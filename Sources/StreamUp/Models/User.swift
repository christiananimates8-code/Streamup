import Foundation

struct User: Codable, Identifiable {
    let id: String
    var username: String
    var displayName: String
    var email: String
    var profileImageURL: String?
    var bio: String?
    
    // Stats
    var followerCount: Int
    var followingCount: Int
    var totalLikes: Int
    var totalStreamHours: Int
    var currentLevel: Int
    var experiencePoints: Int
    
    // Achievements & Perks
    var badges: [Badge]
    var unlockedPerks: [Perk]
    var titles: [String]
    
    // Settings
    var isPrivate: Bool
    var allowCoStreaming: Bool
    var moderationSettings: ModerationSettings
    
    // Timestamps
    let createdAt: Date
    var lastActiveAt: Date
    
    var experienceToNextLevel: Int {
        let baseXP = 1000
        let nextLevelXP = baseXP * (currentLevel + 1)
        return nextLevelXP - experiencePoints
    }
    
    var levelProgress: Double {
        let baseXP = 1000
        let currentLevelXP = baseXP * currentLevel
        let nextLevelXP = baseXP * (currentLevel + 1)
        let levelRange = nextLevelXP - currentLevelXP
        let progressInLevel = experiencePoints - currentLevelXP
        return Double(progressInLevel) / Double(levelRange)
    }
}

struct Badge: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let iconURL: String
    let rarity: BadgeRarity
    let unlockedAt: Date
}

enum BadgeRarity: String, Codable, CaseIterable {
    case common = "common"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var color: String {
        switch self {
        case .common: return "#808080"
        case .rare: return "#0066CC"
        case .epic: return "#9932CC"
        case .legendary: return "#FFD700"
        }
    }
}

struct Perk: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let type: PerkType
    let requirementType: RequirementType
    let requirementValue: Int
    let isUnlocked: Bool
}

enum PerkType: String, Codable {
    case visualEffect = "visual_effect"
    case streamQuality = "stream_quality"
    case streamDuration = "stream_duration"
    case coStreamSlots = "co_stream_slots"
    case moderationTools = "moderation_tools"
    case customOverlay = "custom_overlay"
    case reactionAnimation = "reaction_animation"
}

enum RequirementType: String, Codable {
    case likes = "likes"
    case followers = "followers"
    case level = "level"
    case streamHours = "stream_hours"
}

struct ModerationSettings: Codable {
    var autoModerateChat: Bool
    var allowedWords: [String]
    var blockedWords: [String]
    var blockedUsers: [String]
    var requireFollowToChat: Bool
    var slowModeEnabled: Bool
    var slowModeDelay: Int // seconds
}

extension User {
    static let mockUser = User(
        id: "1",
        username: "streamer_pro",
        displayName: "Pro Streamer",
        email: "pro@streamup.com",
        profileImageURL: nil,
        bio: "Professional streamer and content creator",
        followerCount: 1250,
        followingCount: 150,
        totalLikes: 25000,
        totalStreamHours: 120,
        currentLevel: 5,
        experiencePoints: 4500,
        badges: [],
        unlockedPerks: [],
        titles: ["Rising Star"],
        isPrivate: false,
        allowCoStreaming: true,
        moderationSettings: ModerationSettings(
            autoModerateChat: true,
            allowedWords: [],
            blockedWords: [],
            blockedUsers: [],
            requireFollowToChat: false,
            slowModeEnabled: false,
            slowModeDelay: 5
        ),
        createdAt: Date().addingTimeInterval(-86400 * 30),
        lastActiveAt: Date()
    )
}