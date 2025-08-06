import Foundation
import Combine

class GamificationService: ObservableObject {
    static let shared = GamificationService()
    
    @Published var currentLevel: Int = 1
    @Published var experiencePoints: Int = 0
    @Published var unlockedPerks: [Perk] = []
    @Published var earnedBadges: [Badge] = []
    @Published var dailyChallenges: [Challenge] = []
    @Published var weeklyChallenges: [Challenge] = []
    @Published var leaderboardRank: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let baseXPPerLevel = 1000
    
    private init() {
        loadUserProgress()
        loadChallenges()
    }
    
    // MARK: - XP and Level Management
    
    func awardExperience(points: Int, reason: XPReason) {
        let previousLevel = currentLevel
        experiencePoints += points
        
        // Check for level up
        let newLevel = calculateLevel(from: experiencePoints)
        if newLevel > previousLevel {
            levelUp(from: previousLevel, to: newLevel)
        }
        
        // Check for new unlocks
        checkForNewUnlocks()
        
        // Save progress
        saveUserProgress()
        
        // Show XP notification
        NotificationCenter.default.post(
            name: .xpAwarded,
            object: XPAward(points: points, reason: reason, newLevel: newLevel > previousLevel ? newLevel : nil)
        )
    }
    
    func calculateLevel(from xp: Int) -> Int {
        return max(1, xp / baseXPPerLevel + 1)
    }
    
    func experienceForLevel(_ level: Int) -> Int {
        return baseXPPerLevel * (level - 1)
    }
    
    func experienceToNextLevel() -> Int {
        let nextLevel = currentLevel + 1
        let nextLevelXP = experienceForLevel(nextLevel)
        return nextLevelXP - experiencePoints
    }
    
    func levelProgress() -> Double {
        let currentLevelXP = experienceForLevel(currentLevel)
        let nextLevelXP = experienceForLevel(currentLevel + 1)
        let levelRange = nextLevelXP - currentLevelXP
        let progressInLevel = experiencePoints - currentLevelXP
        return Double(progressInLevel) / Double(levelRange)
    }
    
    private func levelUp(from oldLevel: Int, to newLevel: Int) {
        currentLevel = newLevel
        
        // Award level up perks
        for level in (oldLevel + 1)...newLevel {
            unlockLevelPerks(for: level)
        }
        
        // Show level up notification
        NotificationCenter.default.post(
            name: .levelUp,
            object: LevelUpEvent(oldLevel: oldLevel, newLevel: newLevel)
        )
    }
    
    // MARK: - Perk and Badge Management
    
    func checkForNewUnlocks() {
        let user = NetworkService.shared.currentUser
        guard let user = user else { return }
        
        // Check perk unlocks
        let availablePerks = getAllPerks()
        for perk in availablePerks {
            if !unlockedPerks.contains(where: { $0.id == perk.id }) && canUnlockPerk(perk, user: user) {
                unlockPerk(perk)
            }
        }
        
        // Check badge unlocks
        let availableBadges = getAllBadges()
        for badge in availableBadges {
            if !earnedBadges.contains(where: { $0.id == badge.id }) && canEarnBadge(badge, user: user) {
                earnBadge(badge)
            }
        }
    }
    
    private func canUnlockPerk(_ perk: Perk, user: User) -> Bool {
        switch perk.requirementType {
        case .likes:
            return user.totalLikes >= perk.requirementValue
        case .followers:
            return user.followerCount >= perk.requirementValue
        case .level:
            return currentLevel >= perk.requirementValue
        case .streamHours:
            return user.totalStreamHours >= perk.requirementValue
        }
    }
    
    private func canEarnBadge(_ badge: Badge, user: User) -> Bool {
        // Implementation would depend on specific badge requirements
        // This is a simplified version
        switch badge.name {
        case "First Stream":
            return user.totalStreamHours > 0
        case "Popular Streamer":
            return user.followerCount >= 100
        case "Engagement Master":
            return user.totalLikes >= 1000
        case "Marathon Streamer":
            return user.totalStreamHours >= 10
        default:
            return false
        }
    }
    
    private func unlockPerk(_ perk: Perk) {
        var updatedPerk = perk
        updatedPerk = Perk(
            id: perk.id,
            name: perk.name,
            description: perk.description,
            type: perk.type,
            requirementType: perk.requirementType,
            requirementValue: perk.requirementValue,
            isUnlocked: true
        )
        
        unlockedPerks.append(updatedPerk)
        
        NotificationCenter.default.post(
            name: .perkUnlocked,
            object: updatedPerk
        )
    }
    
    private func earnBadge(_ badge: Badge) {
        earnedBadges.append(badge)
        
        NotificationCenter.default.post(
            name: .badgeEarned,
            object: badge
        )
    }
    
    private func unlockLevelPerks(for level: Int) {
        let levelPerks = getLevelPerks(for: level)
        for perk in levelPerks {
            unlockPerk(perk)
        }
    }
    
    // MARK: - Challenge System
    
    func loadChallenges() {
        // Load from API or local data
        dailyChallenges = generateDailyChallenges()
        weeklyChallenges = generateWeeklyChallenges()
    }
    
    func completeChallenge(_ challenge: Challenge) {
        // Award XP and mark complete
        awardExperience(points: challenge.xpReward, reason: .challengeCompleted)
        
        // Update challenge status
        if let index = dailyChallenges.firstIndex(where: { $0.id == challenge.id }) {
            dailyChallenges[index].isCompleted = true
            dailyChallenges[index].completedAt = Date()
        } else if let index = weeklyChallenges.firstIndex(where: { $0.id == challenge.id }) {
            weeklyChallenges[index].isCompleted = true
            weeklyChallenges[index].completedAt = Date()
        }
        
        NotificationCenter.default.post(
            name: .challengeCompleted,
            object: challenge
        )
    }
    
    func checkChallengeProgress() {
        // Check daily challenges
        for challenge in dailyChallenges where !challenge.isCompleted {
            if challenge.progress >= challenge.target {
                completeChallenge(challenge)
            }
        }
        
        // Check weekly challenges
        for challenge in weeklyChallenges where !challenge.isCompleted {
            if challenge.progress >= challenge.target {
                completeChallenge(challenge)
            }
        }
    }
    
    func updateChallengeProgress(for type: ChallengeType, amount: Int = 1) {
        // Update daily challenges
        for i in 0..<dailyChallenges.count {
            if dailyChallenges[i].type == type && !dailyChallenges[i].isCompleted {
                dailyChallenges[i].progress += amount
            }
        }
        
        // Update weekly challenges
        for i in 0..<weeklyChallenges.count {
            if weeklyChallenges[i].type == type && !weeklyChallenges[i].isCompleted {
                weeklyChallenges[i].progress += amount
            }
        }
        
        checkChallengeProgress()
    }
    
    // MARK: - Data Generation
    
    private func generateDailyChallenges() -> [Challenge] {
        return [
            Challenge(
                id: "daily_stream_1",
                title: "Go Live Today",
                description: "Start a livestream",
                type: .startStream,
                target: 1,
                progress: 0,
                xpReward: 100,
                duration: .daily
            ),
            Challenge(
                id: "daily_likes_1",
                title: "Earn 10 Likes",
                description: "Get 10 likes on your streams today",
                type: .earnLikes,
                target: 10,
                progress: 0,
                xpReward: 50,
                duration: .daily
            ),
            Challenge(
                id: "daily_chat_1",
                title: "Send 20 Messages",
                description: "Send 20 chat messages",
                type: .sendChatMessages,
                target: 20,
                progress: 0,
                xpReward: 30,
                duration: .daily
            )
        ]
    }
    
    private func generateWeeklyChallenges() -> [Challenge] {
        return [
            Challenge(
                id: "weekly_stream_1",
                title: "Stream for 5 Hours",
                description: "Stream for a total of 5 hours this week",
                type: .streamDuration,
                target: 300, // 5 hours in minutes
                progress: 0,
                xpReward: 500,
                duration: .weekly
            ),
            Challenge(
                id: "weekly_followers_1",
                title: "Gain 5 Followers",
                description: "Get 5 new followers this week",
                type: .gainFollowers,
                target: 5,
                progress: 0,
                xpReward: 200,
                duration: .weekly
            )
        ]
    }
    
    private func getAllPerks() -> [Perk] {
        return [
            // Visual Effects
            Perk(
                id: "perk_sparkle_effect",
                name: "Sparkle Effect",
                description: "Add sparkle animations to your stream",
                type: .visualEffect,
                requirementType: .likes,
                requirementValue: 100,
                isUnlocked: false
            ),
            Perk(
                id: "perk_heart_explosion",
                name: "Heart Explosion",
                description: "Explosive heart effect for super likes",
                type: .reactionAnimation,
                requirementType: .likes,
                requirementValue: 500,
                isUnlocked: false
            ),
            
            // Stream Quality
            Perk(
                id: "perk_hd_streaming",
                name: "HD Streaming",
                description: "Stream in 720p HD quality",
                type: .streamQuality,
                requirementType: .followers,
                requirementValue: 50,
                isUnlocked: false
            ),
            Perk(
                id: "perk_1080p_streaming",
                name: "Full HD Streaming",
                description: "Stream in 1080p Full HD quality",
                type: .streamQuality,
                requirementType: .followers,
                requirementValue: 200,
                isUnlocked: false
            ),
            
            // Co-streaming
            Perk(
                id: "perk_extra_costreamer",
                name: "Extra Co-streamer Slot",
                description: "Allow one additional co-streamer",
                type: .coStreamSlots,
                requirementType: .level,
                requirementValue: 5,
                isUnlocked: false
            ),
            
            // Duration
            Perk(
                id: "perk_extended_stream",
                name: "Extended Streaming",
                description: "Stream for up to 4 hours continuously",
                type: .streamDuration,
                requirementType: .streamHours,
                requirementValue: 10,
                isUnlocked: false
            )
        ]
    }
    
    private func getAllBadges() -> [Badge] {
        return [
            Badge(
                id: "badge_first_stream",
                name: "First Stream",
                description: "Completed your first livestream",
                iconURL: "badge_first_stream",
                rarity: .common,
                unlockedAt: Date()
            ),
            Badge(
                id: "badge_popular_streamer",
                name: "Popular Streamer",
                description: "Reached 100 followers",
                iconURL: "badge_popular_streamer",
                rarity: .rare,
                unlockedAt: Date()
            ),
            Badge(
                id: "badge_engagement_master",
                name: "Engagement Master",
                description: "Earned 1000 likes",
                iconURL: "badge_engagement_master",
                rarity: .epic,
                unlockedAt: Date()
            ),
            Badge(
                id: "badge_marathon_streamer",
                name: "Marathon Streamer",
                description: "Streamed for 10 hours total",
                iconURL: "badge_marathon_streamer",
                rarity: .rare,
                unlockedAt: Date()
            )
        ]
    }
    
    private func getLevelPerks(for level: Int) -> [Perk] {
        switch level {
        case 2:
            return [
                Perk(
                    id: "perk_level_2_overlay",
                    name: "Custom Overlay",
                    description: "Unlock custom stream overlays",
                    type: .customOverlay,
                    requirementType: .level,
                    requirementValue: 2,
                    isUnlocked: true
                )
            ]
        case 5:
            return getAllPerks().filter { $0.requirementType == .level && $0.requirementValue == 5 }
        case 10:
            return [
                Perk(
                    id: "perk_advanced_moderation",
                    name: "Advanced Moderation",
                    description: "Access to advanced moderation tools",
                    type: .moderationTools,
                    requirementType: .level,
                    requirementValue: 10,
                    isUnlocked: true
                )
            ]
        default:
            return []
        }
    }
    
    // MARK: - Persistence
    
    private func saveUserProgress() {
        userDefaults.set(currentLevel, forKey: "gamification_level")
        userDefaults.set(experiencePoints, forKey: "gamification_xp")
        
        if let perksData = try? JSONEncoder().encode(unlockedPerks) {
            userDefaults.set(perksData, forKey: "gamification_perks")
        }
        
        if let badgesData = try? JSONEncoder().encode(earnedBadges) {
            userDefaults.set(badgesData, forKey: "gamification_badges")
        }
    }
    
    private func loadUserProgress() {
        currentLevel = userDefaults.integer(forKey: "gamification_level")
        if currentLevel == 0 { currentLevel = 1 }
        
        experiencePoints = userDefaults.integer(forKey: "gamification_xp")
        
        if let perksData = userDefaults.data(forKey: "gamification_perks"),
           let perks = try? JSONDecoder().decode([Perk].self, from: perksData) {
            unlockedPerks = perks
        }
        
        if let badgesData = userDefaults.data(forKey: "gamification_badges"),
           let badges = try? JSONDecoder().decode([Badge].self, from: badgesData) {
            earnedBadges = badges
        }
    }
}

// MARK: - Supporting Types

struct Challenge: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: ChallengeType
    let target: Int
    var progress: Int
    let xpReward: Int
    let duration: ChallengeDuration
    var isCompleted: Bool = false
    var completedAt: Date?
    
    var progressPercentage: Double {
        return min(1.0, Double(progress) / Double(target))
    }
}

enum ChallengeType: String, Codable {
    case startStream = "start_stream"
    case streamDuration = "stream_duration"
    case earnLikes = "earn_likes"
    case gainFollowers = "gain_followers"
    case sendChatMessages = "send_chat_messages"
    case watchStreams = "watch_streams"
    case shareStream = "share_stream"
    case inviteCoStreamer = "invite_co_streamer"
}

enum ChallengeDuration: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
}

enum XPReason: String {
    case streamStarted = "stream_started"
    case streamCompleted = "stream_completed"
    case likeReceived = "like_received"
    case followerGained = "follower_gained"
    case chatMessageSent = "chat_message_sent"
    case challengeCompleted = "challenge_completed"
    case badgeEarned = "badge_earned"
    case streamWatched = "stream_watched"
    case coStreamJoined = "co_stream_joined"
}

struct XPAward {
    let points: Int
    let reason: XPReason
    let newLevel: Int?
}

struct LevelUpEvent {
    let oldLevel: Int
    let newLevel: Int
}

// MARK: - Notifications

extension Notification.Name {
    static let xpAwarded = Notification.Name("xpAwarded")
    static let levelUp = Notification.Name("levelUp")
    static let perkUnlocked = Notification.Name("perkUnlocked")
    static let badgeEarned = Notification.Name("badgeEarned")
    static let challengeCompleted = Notification.Name("challengeCompleted")
}

// MARK: - XP Calculation Helpers

extension GamificationService {
    static let xpValues: [XPReason: Int] = [
        .streamStarted: 50,
        .streamCompleted: 100,
        .likeReceived: 5,
        .followerGained: 25,
        .chatMessageSent: 2,
        .streamWatched: 10,
        .coStreamJoined: 30
    ]
    
    static func xpForAction(_ reason: XPReason) -> Int {
        return xpValues[reason] ?? 0
    }
}