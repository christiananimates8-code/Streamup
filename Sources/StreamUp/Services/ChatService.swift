import Foundation
import SocketIO
import Combine

class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var messages: [ChatMessage] = []
    @Published var isConnected = false
    @Published var connectionStatus: SocketIOStatus = .notConnected
    
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var currentStreamId: String?
    
    private init() {
        setupSocketConnection()
    }
    
    // MARK: - Socket Setup
    
    private func setupSocketConnection() {
        guard let url = URL(string: "https://chat.streamup.com") else { return }
        
        let config: SocketIOClientConfiguration = [
            .log(false),
            .compress,
            .reconnects(true),
            .reconnectAttempts(5),
            .reconnectWait(2)
        ]
        
        manager = SocketManager(socketURL: url, config: config)
        socket = manager?.defaultSocket
        
        setupEventHandlers()
    }
    
    private func setupEventHandlers() {
        guard let socket = socket else { return }
        
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = true
                self?.connectionStatus = .connected
            }
            print("Chat socket connected")
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            DispatchQueue.main.async {
                self?.isConnected = false
                self?.connectionStatus = .disconnected
            }
            print("Chat socket disconnected")
        }
        
        socket.on(clientEvent: .error) { [weak self] data, _ in
            DispatchQueue.main.async {
                self?.connectionStatus = .disconnected
            }
            print("Chat socket error: \(data)")
        }
        
        socket.on("message") { [weak self] data, _ in
            self?.handleIncomingMessage(data)
        }
        
        socket.on("user_joined") { [weak self] data, _ in
            self?.handleUserJoined(data)
        }
        
        socket.on("user_left") { [weak self] data, _ in
            self?.handleUserLeft(data)
        }
        
        socket.on("message_deleted") { [weak self] data, _ in
            self?.handleMessageDeleted(data)
        }
        
        socket.on("user_banned") { [weak self] data, _ in
            self?.handleUserBanned(data)
        }
        
        socket.on("viewer_count_update") { [weak self] data, _ in
            self?.handleViewerCountUpdate(data)
        }
    }
    
    // MARK: - Connection Management
    
    func connect() {
        guard let authToken = UserDefaults.standard.string(forKey: "auth_token") else {
            print("No auth token available")
            return
        }
        
        socket?.connect(withPayload: ["token": authToken])
    }
    
    func disconnect() {
        socket?.disconnect()
        DispatchQueue.main.async {
            self.messages.removeAll()
            self.currentStreamId = nil
        }
    }
    
    // MARK: - Stream Chat Management
    
    func joinStreamChat(streamId: String) {
        self.currentStreamId = streamId
        
        socket?.emit("join_stream", [
            "stream_id": streamId
        ])
        
        // Load chat history
        Task {
            await loadChatHistory(streamId: streamId)
        }
    }
    
    func leaveStreamChat() {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("leave_stream", [
            "stream_id": streamId
        ])
        
        DispatchQueue.main.async {
            self.messages.removeAll()
            self.currentStreamId = nil
        }
    }
    
    // MARK: - Message Operations
    
    func sendMessage(_ text: String) async throws {
        guard let streamId = currentStreamId else {
            throw ChatError.notConnectedToStream
        }
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatError.emptyMessage
        }
        
        let message = ChatMessage(
            id: UUID().uuidString,
            userId: NetworkService.shared.currentUser?.id,
            username: NetworkService.shared.currentUser?.username ?? "Anonymous",
            message: text,
            timestamp: Date(),
            type: .text,
            isVisible: true,
            reactions: []
        )
        
        // Optimistically add message to UI
        DispatchQueue.main.async {
            self.messages.append(message)
        }
        
        socket?.emit("send_message", [
            "stream_id": streamId,
            "message": text,
            "type": MessageType.text.rawValue
        ])
    }
    
    func sendLike() {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("send_like", [
            "stream_id": streamId
        ])
    }
    
    func sendReaction(_ emoji: String) {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("send_reaction", [
            "stream_id": streamId,
            "emoji": emoji
        ])
    }
    
    // MARK: - Moderation
    
    func deleteMessage(messageId: String) {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("delete_message", [
            "stream_id": streamId,
            "message_id": messageId
        ])
    }
    
    func banUser(userId: String, duration: TimeInterval? = nil) {
        guard let streamId = currentStreamId else { return }
        
        var params: [String: Any] = [
            "stream_id": streamId,
            "user_id": userId
        ]
        
        if let duration = duration {
            params["duration"] = duration
        }
        
        socket?.emit("ban_user", params)
    }
    
    func unbanUser(userId: String) {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("unban_user", [
            "stream_id": streamId,
            "user_id": userId
        ])
    }
    
    func muteUser(userId: String, duration: TimeInterval) {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("mute_user", [
            "stream_id": streamId,
            "user_id": userId,
            "duration": duration
        ])
    }
    
    func enableSlowMode(delay: Int) {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("set_slow_mode", [
            "stream_id": streamId,
            "delay": delay
        ])
    }
    
    func disableSlowMode() {
        guard let streamId = currentStreamId else { return }
        
        socket?.emit("disable_slow_mode", [
            "stream_id": streamId
        ])
    }
    
    // MARK: - Event Handlers
    
    private func handleIncomingMessage(_ data: [Any]) {
        guard let messageData = data.first as? [String: Any] else { return }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
            let message = try JSONDecoder().decode(ChatMessage.self, from: jsonData)
            
            DispatchQueue.main.async {
                // Remove any optimistic message with same content
                self.messages.removeAll { $0.message == message.message && $0.userId == message.userId }
                self.messages.append(message)
                self.messages.sort { $0.timestamp < $1.timestamp }
            }
        } catch {
            print("Failed to decode message: \(error)")
        }
    }
    
    private func handleUserJoined(_ data: [Any]) {
        guard let userData = data.first as? [String: Any],
              let username = userData["username"] as? String else { return }
        
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            userId: nil,
            username: "System",
            message: "\(username) joined the stream",
            timestamp: Date(),
            type: .join,
            isVisible: true,
            reactions: []
        )
        
        DispatchQueue.main.async {
            self.messages.append(systemMessage)
        }
    }
    
    private func handleUserLeft(_ data: [Any]) {
        guard let userData = data.first as? [String: Any],
              let username = userData["username"] as? String else { return }
        
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            userId: nil,
            username: "System",
            message: "\(username) left the stream",
            timestamp: Date(),
            type: .leave,
            isVisible: true,
            reactions: []
        )
        
        DispatchQueue.main.async {
            self.messages.append(systemMessage)
        }
    }
    
    private func handleMessageDeleted(_ data: [Any]) {
        guard let messageData = data.first as? [String: Any],
              let messageId = messageData["message_id"] as? String else { return }
        
        DispatchQueue.main.async {
            self.messages.removeAll { $0.id == messageId }
        }
    }
    
    private func handleUserBanned(_ data: [Any]) {
        guard let banData = data.first as? [String: Any],
              let userId = banData["user_id"] as? String,
              let username = banData["username"] as? String else { return }
        
        // Remove all messages from banned user
        DispatchQueue.main.async {
            self.messages.removeAll { $0.userId == userId }
        }
        
        let systemMessage = ChatMessage(
            id: UUID().uuidString,
            userId: nil,
            username: "System",
            message: "\(username) has been banned",
            timestamp: Date(),
            type: .system,
            isVisible: true,
            reactions: []
        )
        
        DispatchQueue.main.async {
            self.messages.append(systemMessage)
        }
    }
    
    private func handleViewerCountUpdate(_ data: [Any]) {
        guard let countData = data.first as? [String: Any],
              let count = countData["count"] as? Int else { return }
        
        // Update viewer count in streaming service
        DispatchQueue.main.async {
            StreamingService.shared.viewerCount = count
        }
    }
    
    // MARK: - Chat History
    
    private func loadChatHistory(streamId: String) async {
        do {
            let messages = try await NetworkService.shared.getChatHistory(streamId: streamId, limit: 50)
            
            DispatchQueue.main.async {
                self.messages = messages.sorted { $0.timestamp < $1.timestamp }
            }
        } catch {
            print("Failed to load chat history: \(error)")
        }
    }
    
    // MARK: - Message Filtering
    
    func filterMessages(by type: MessageType? = nil, hideSystemMessages: Bool = false) -> [ChatMessage] {
        var filtered = messages
        
        if let type = type {
            filtered = filtered.filter { $0.type == type }
        }
        
        if hideSystemMessages {
            filtered = filtered.filter { $0.type != .system }
        }
        
        return filtered.filter { $0.isVisible }
    }
    
    // MARK: - Chat Commands
    
    func processChatCommand(_ text: String) -> Bool {
        guard text.hasPrefix("/") else { return false }
        
        let components = text.dropFirst().components(separatedBy: " ")
        guard let command = components.first?.lowercased() else { return false }
        
        switch command {
        case "clear":
            DispatchQueue.main.async {
                self.messages.removeAll()
            }
            return true
            
        case "slow":
            if components.count > 1, let delay = Int(components[1]) {
                enableSlowMode(delay: delay)
            } else {
                enableSlowMode(delay: 5)
            }
            return true
            
        case "slowoff":
            disableSlowMode()
            return true
            
        default:
            return false
        }
    }
}

// MARK: - Chat Errors

enum ChatError: Error, LocalizedError {
    case notConnectedToStream
    case emptyMessage
    case messageTooLong
    case rateLimited
    case banned
    case muted
    
    var errorDescription: String? {
        switch self {
        case .notConnectedToStream:
            return "Not connected to a stream chat"
        case .emptyMessage:
            return "Message cannot be empty"
        case .messageTooLong:
            return "Message is too long"
        case .rateLimited:
            return "You are sending messages too quickly"
        case .banned:
            return "You have been banned from this chat"
        case .muted:
            return "You have been muted and cannot send messages"
        }
    }
}

// MARK: - Chat Settings

struct ChatSettings {
    var slowMode: Bool = false
    var slowModeDelay: Int = 5
    var subscribersOnly: Bool = false
    var followersOnly: Bool = false
    var autoModerate: Bool = true
    var hideSystemMessages: Bool = false
    var fontSize: ChatFontSize = .medium
}

enum ChatFontSize: String, CaseIterable {
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var pointSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }
}