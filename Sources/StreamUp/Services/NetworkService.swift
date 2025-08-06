import Foundation
import Alamofire
import SwiftyJSON

class NetworkService: ObservableObject {
    static let shared = NetworkService()
    
    private let baseURL = "https://api.streamup.com/v1"
    private let session: Session
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    
    private var authToken: String? {
        didSet {
            isAuthenticated = authToken != nil
        }
    }
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        let interceptor = AuthenticationInterceptor()
        self.session = Session(configuration: configuration, interceptor: interceptor)
        
        // Load stored auth token
        loadAuthToken()
    }
    
    // MARK: - Authentication
    
    func login(email: String, password: String) async throws -> User {
        let parameters: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        let response = try await session.request(
            "\(baseURL)/auth/login",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).serializingDecodable(LoginResponse.self).value
        
        self.authToken = response.token
        self.currentUser = response.user
        saveAuthToken(response.token)
        
        return response.user
    }
    
    func register(username: String, email: String, password: String, displayName: String) async throws -> User {
        let parameters: [String: Any] = [
            "username": username,
            "email": email,
            "password": password,
            "display_name": displayName
        ]
        
        let response = try await session.request(
            "\(baseURL)/auth/register",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).serializingDecodable(LoginResponse.self).value
        
        self.authToken = response.token
        self.currentUser = response.user
        saveAuthToken(response.token)
        
        return response.user
    }
    
    func logout() {
        authToken = nil
        currentUser = nil
        clearAuthToken()
    }
    
    // MARK: - User Operations
    
    func getCurrentUser() async throws -> User {
        let user = try await session.request(
            "\(baseURL)/user/me"
        ).serializingDecodable(User.self).value
        
        DispatchQueue.main.async {
            self.currentUser = user
        }
        
        return user
    }
    
    func updateProfile(_ user: User) async throws -> User {
        let updatedUser = try await session.request(
            "\(baseURL)/user/me",
            method: .put,
            parameters: user,
            encoder: JSONParameterEncoder.default
        ).serializingDecodable(User.self).value
        
        DispatchQueue.main.async {
            self.currentUser = updatedUser
        }
        
        return updatedUser
    }
    
    func followUser(userId: String) async throws {
        _ = try await session.request(
            "\(baseURL)/user/\(userId)/follow",
            method: .post
        ).serializingData().value
    }
    
    func unfollowUser(userId: String) async throws {
        _ = try await session.request(
            "\(baseURL)/user/\(userId)/follow",
            method: .delete
        ).serializingData().value
    }
    
    func getUser(userId: String) async throws -> User {
        return try await session.request(
            "\(baseURL)/user/\(userId)"
        ).serializingDecodable(User.self).value
    }
    
    // MARK: - Stream Operations
    
    func createStream(_ stream: CreateStreamRequest) async throws -> Stream {
        return try await session.request(
            "\(baseURL)/streams",
            method: .post,
            parameters: stream,
            encoder: JSONParameterEncoder.default
        ).serializingDecodable(Stream.self).value
    }
    
    func getStream(streamId: String) async throws -> Stream {
        return try await session.request(
            "\(baseURL)/streams/\(streamId)"
        ).serializingDecodable(Stream.self).value
    }
    
    func startStream(streamId: String) async throws -> StreamKey {
        return try await session.request(
            "\(baseURL)/streams/\(streamId)/start",
            method: .post
        ).serializingDecodable(StreamKey.self).value
    }
    
    func endStream(streamId: String) async throws {
        _ = try await session.request(
            "\(baseURL)/streams/\(streamId)/end",
            method: .post
        ).serializingData().value
    }
    
    func getLiveStreams(page: Int = 1, limit: Int = 20) async throws -> StreamListResponse {
        let parameters: [String: Any] = [
            "page": page,
            "limit": limit,
            "status": "live"
        ]
        
        return try await session.request(
            "\(baseURL)/streams",
            method: .get,
            parameters: parameters
        ).serializingDecodable(StreamListResponse.self).value
    }
    
    func searchStreams(query: String, category: StreamCategory? = nil) async throws -> StreamListResponse {
        var parameters: [String: Any] = ["q": query]
        if let category = category {
            parameters["category"] = category.rawValue
        }
        
        return try await session.request(
            "\(baseURL)/streams/search",
            method: .get,
            parameters: parameters
        ).serializingDecodable(StreamListResponse.self).value
    }
    
    func likeStream(streamId: String) async throws {
        _ = try await session.request(
            "\(baseURL)/streams/\(streamId)/like",
            method: .post
        ).serializingData().value
    }
    
    // MARK: - Co-Streaming
    
    func inviteToCoStream(streamId: String, userId: String) async throws {
        let parameters = ["user_id": userId]
        
        _ = try await session.request(
            "\(baseURL)/streams/\(streamId)/invite",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).serializingData().value
    }
    
    func joinCoStream(streamId: String, inviteCode: String) async throws -> CoStreamJoinResponse {
        let parameters = ["invite_code": inviteCode]
        
        return try await session.request(
            "\(baseURL)/streams/\(streamId)/join",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).serializingDecodable(CoStreamJoinResponse.self).value
    }
    
    func leaveCoStream(streamId: String) async throws {
        _ = try await session.request(
            "\(baseURL)/streams/\(streamId)/leave",
            method: .post
        ).serializingData().value
    }
    
    // MARK: - Chat Operations
    
    func sendChatMessage(streamId: String, message: String) async throws -> ChatMessage {
        let parameters: [String: Any] = [
            "message": message,
            "type": MessageType.text.rawValue
        ]
        
        return try await session.request(
            "\(baseURL)/streams/\(streamId)/chat",
            method: .post,
            parameters: parameters,
            encoding: JSONEncoding.default
        ).serializingDecodable(ChatMessage.self).value
    }
    
    func getChatHistory(streamId: String, limit: Int = 50) async throws -> [ChatMessage] {
        let parameters = ["limit": limit]
        
        let response = try await session.request(
            "\(baseURL)/streams/\(streamId)/chat",
            method: .get,
            parameters: parameters
        ).serializingDecodable(ChatHistoryResponse.self).value
        
        return response.messages
    }
    
    // MARK: - Rewards & Gamification
    
    func getRewards() async throws -> [Perk] {
        return try await session.request(
            "\(baseURL)/rewards"
        ).serializingDecodable([Perk].self).value
    }
    
    func getLeaderboard(type: String = "weekly") async throws -> LeaderboardResponse {
        let parameters = ["type": type]
        
        return try await session.request(
            "\(baseURL)/leaderboard",
            method: .get,
            parameters: parameters
        ).serializingDecodable(LeaderboardResponse.self).value
    }
    
    // MARK: - File Upload
    
    func uploadProfileImage(_ imageData: Data) async throws -> String {
        let response = try await session.upload(
            multipartFormData: { formData in
                formData.append(imageData, withName: "image", fileName: "profile.jpg", mimeType: "image/jpeg")
            },
            to: "\(baseURL)/upload/profile-image"
        ).serializingDecodable(UploadResponse.self).value
        
        return response.url
    }
    
    // MARK: - Token Management
    
    private func saveAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: "auth_token")
    }
    
    private func loadAuthToken() {
        authToken = UserDefaults.standard.string(forKey: "auth_token")
    }
    
    private func clearAuthToken() {
        UserDefaults.standard.removeObject(forKey: "auth_token")
    }
}

// MARK: - Authentication Interceptor

class AuthenticationInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var request = urlRequest
        
        if let token = UserDefaults.standard.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("StreamUp/1.0 iOS", forHTTPHeaderField: "User-Agent")
        
        completion(.success(request))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        // Token expired, logout user
        DispatchQueue.main.async {
            NetworkService.shared.logout()
        }
        
        completion(.doNotRetryWithError(error))
    }
}

// MARK: - Response Models

struct LoginResponse: Codable {
    let token: String
    let user: User
}

struct CreateStreamRequest: Codable {
    let title: String
    let description: String?
    let category: StreamCategory
    let isPrivate: Bool
    let allowCoStreaming: Bool
    let maxCoStreamers: Int
    let tags: [String]
}

struct StreamKey: Codable {
    let streamURL: String
    let streamKey: String
}

struct StreamListResponse: Codable {
    let streams: [Stream]
    let totalCount: Int
    let page: Int
    let hasMore: Bool
}

struct CoStreamJoinResponse: Codable {
    let success: Bool
    let streamURL: String
    let position: CoStreamerPosition
}

struct ChatHistoryResponse: Codable {
    let messages: [ChatMessage]
}

struct LeaderboardResponse: Codable {
    let users: [LeaderboardEntry]
    let currentUserRank: Int?
}

struct LeaderboardEntry: Codable, Identifiable {
    let id: String
    let user: User
    let rank: Int
    let score: Int
    let change: Int
}

struct UploadResponse: Codable {
    let url: String
}