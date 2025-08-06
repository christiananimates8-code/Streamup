import Foundation

struct Stream: Codable, Identifiable {
    let id: String
    let hostUserId: String
    var title: String
    var description: String?
    var thumbnailURL: String?
    
    // Stream Configuration
    var isPrivate: Bool
    var allowCoStreaming: Bool
    var maxCoStreamers: Int
    var category: StreamCategory
    var tags: [String]
    
    // Participants
    var coStreamers: [CoStreamer]
    var viewers: [Viewer]
    
    // Engagement
    var viewerCount: Int
    var totalLikes: Int
    var chatMessages: [ChatMessage]
    
    // Stream Status
    var status: StreamStatus
    var streamURL: String?
    var streamKey: String?
    var quality: StreamQuality
    
    // Timestamps
    let createdAt: Date
    var startedAt: Date?
    var endedAt: Date?
    
    // Metrics
    var peakViewerCount: Int
    var totalWatchTime: TimeInterval
    var engagementRate: Double
    
    var duration: TimeInterval? {
        guard let startedAt = startedAt else { return nil }
        let endTime = endedAt ?? Date()
        return endTime.timeIntervalSince(startedAt)
    }
    
    var isLive: Bool {
        return status == .live
    }
}

struct CoStreamer: Codable, Identifiable {
    let id: String
    let userId: String
    let username: String
    let profileImageURL: String?
    let joinedAt: Date
    var isMuted: Bool
    var isVideoEnabled: Bool
    var position: CoStreamerPosition
}

enum CoStreamerPosition: String, Codable {
    case topLeft = "top_left"
    case topRight = "top_right"
    case bottomLeft = "bottom_left"
    case bottomRight = "bottom_right"
    case splitScreen = "split_screen"
    case pictureInPicture = "picture_in_picture"
}

struct Viewer: Codable, Identifiable {
    let id: String
    let userId: String?
    let username: String?
    let isAnonymous: Bool
    let joinedAt: Date
    var lastSeenAt: Date
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let userId: String?
    let username: String
    let message: String
    let timestamp: Date
    let type: MessageType
    var isVisible: Bool
    var reactions: [MessageReaction]
}

enum MessageType: String, Codable {
    case text = "text"
    case emoji = "emoji"
    case system = "system"
    case like = "like"
    case gift = "gift"
    case follow = "follow"
    case join = "join"
    case leave = "leave"
}

struct MessageReaction: Codable {
    let emoji: String
    let count: Int
    let userIds: [String]
}

enum StreamCategory: String, Codable, CaseIterable {
    case gaming = "gaming"
    case music = "music"
    case art = "art"
    case cooking = "cooking"
    case fitness = "fitness"
    case education = "education"
    case technology = "technology"
    case lifestyle = "lifestyle"
    case entertainment = "entertainment"
    case sports = "sports"
    case travel = "travel"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .gaming: return "Gaming"
        case .music: return "Music"
        case .art: return "Art & Design"
        case .cooking: return "Cooking"
        case .fitness: return "Fitness"
        case .education: return "Education"
        case .technology: return "Technology"
        case .lifestyle: return "Lifestyle"
        case .entertainment: return "Entertainment"
        case .sports: return "Sports"
        case .travel: return "Travel"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .gaming: return "gamecontroller"
        case .music: return "music.note"
        case .art: return "paintbrush"
        case .cooking: return "fork.knife"
        case .fitness: return "dumbbell"
        case .education: return "book"
        case .technology: return "desktopcomputer"
        case .lifestyle: return "heart"
        case .entertainment: return "tv"
        case .sports: return "sportscourt"
        case .travel: return "airplane"
        case .other: return "ellipsis.circle"
        }
    }
}

enum StreamStatus: String, Codable {
    case scheduled = "scheduled"
    case starting = "starting"
    case live = "live"
    case paused = "paused"
    case ended = "ended"
    case cancelled = "cancelled"
}

enum StreamQuality: String, Codable {
    case low = "360p"
    case medium = "720p"
    case high = "1080p"
    case ultra = "4k"
    
    var displayName: String {
        switch self {
        case .low: return "360p"
        case .medium: return "720p HD"
        case .high: return "1080p HD"
        case .ultra: return "4K Ultra HD"
        }
    }
    
    var bitrate: Int {
        switch self {
        case .low: return 1000
        case .medium: return 2500
        case .high: return 5000
        case .ultra: return 15000
        }
    }
}

// MARK: - Mock Data
extension Stream {
    static let mockStream = Stream(
        id: "stream_1",
        hostUserId: "1",
        title: "Epic Gaming Session!",
        description: "Playing the latest games with friends",
        thumbnailURL: nil,
        isPrivate: false,
        allowCoStreaming: true,
        maxCoStreamers: 3,
        category: .gaming,
        tags: ["gaming", "multiplayer", "fun"],
        coStreamers: [],
        viewers: [],
        viewerCount: 124,
        totalLikes: 89,
        chatMessages: [],
        status: .live,
        streamURL: "rtmp://stream.streamup.com/live",
        streamKey: "abc123def456",
        quality: .medium,
        createdAt: Date().addingTimeInterval(-3600),
        startedAt: Date().addingTimeInterval(-1800),
        endedAt: nil,
        peakViewerCount: 156,
        totalWatchTime: 2240,
        engagementRate: 0.72
    )
}