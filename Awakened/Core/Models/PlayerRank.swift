import SwiftUI

/// Player rank based on overall level
/// Inspired by Solo Leveling's hunter ranking system
enum PlayerRank: String, CaseIterable, Comparable, Codable {
    case e = "E"
    case d = "D"
    case c = "C"
    case b = "B"
    case a = "A"
    case s = "S"
    case ss = "SS"
    case sss = "SSS"
    
    /// Full display name (e.g., "E-Rank")
    var displayName: String {
        rawValue + "-Rank"
    }
    
    /// Associated color for this rank
    var color: Color {
        switch self {
        case .e: return AppColors.rankE
        case .d: return AppColors.rankD
        case .c: return AppColors.rankC
        case .b: return AppColors.rankB
        case .a: return AppColors.rankA
        case .s: return AppColors.rankS
        case .ss: return AppColors.rankSS
        case .sss: return AppColors.rankSSS
        }
    }
    
    /// Minimum level required for this rank
    var minLevel: Int {
        switch self {
        case .e: return 1
        case .d: return 10
        case .c: return 25
        case .b: return 50
        case .a: return 75
        case .s: return 100
        case .ss: return 150
        case .sss: return 200
        }
    }
    
    /// Maximum level for this rank (before promotion)
    var maxLevel: Int {
        switch self {
        case .e: return 9
        case .d: return 24
        case .c: return 49
        case .b: return 74
        case .a: return 99
        case .s: return 149
        case .ss: return 199
        case .sss: return Int.max
        }
    }
    
    /// Description of this rank (aligned with Solo Leveling lore)
    var description: String {
        switch self {
        case .e: return "Weakest rank. Slightly superhuman. Every journey starts here."
        case .d: return "Can clear basic Gates. Your awakening has begun."
        case .c: return "Professional level. Respected in the hunter community."
        case .b: return "Elite hunter. Rare abilities set you apart."
        case .a: return "Top 1% of hunters. A national-level asset."
        case .s: return "The pinnacle. Nations compete for your allegiance."
        case .ss: return "Legendary power. You stand above S-Rank."
        case .sss: return "Transcendent being. Your name echoes through history."
        }
    }
    
    /// Motivational message for this rank
    var motivationalMessage: String {
        switch self {
        case .e: return "Every journey begins with a single step. Keep pushing!"
        case .d: return "You're making progress. The path ahead is clearer now."
        case .c: return "You've proven your dedication. Greater challenges await."
        case .b: return "Your strength grows. Few can match your determination."
        case .a: return "Elite status achieved. You stand among the best."
        case .s: return "Master level reached. Your legend is being written."
        case .ss: return "Legendary power flows through you. Inspire others."
        case .sss: return "You have transcended. A true mythical being."
        }
    }
    
    /// SF Symbol icon for this rank
    var icon: String {
        switch self {
        case .e: return "shield"
        case .d: return "shield.fill"
        case .c: return "shield.lefthalf.filled"
        case .b: return "shield.checkered"
        case .a: return "star.shield"
        case .s: return "star.shield.fill"
        case .ss: return "crown"
        case .sss: return "crown.fill"
        }
    }
    
    /// Determine rank from player level
    /// - Parameter level: The player's current level
    /// - Returns: The appropriate rank for that level
    static func from(level: Int) -> PlayerRank {
        for rank in PlayerRank.allCases.reversed() {
            if level >= rank.minLevel {
                return rank
            }
        }
        return .e
    }
    
    /// Get the next rank (if any)
    var nextRank: PlayerRank? {
        guard let currentIndex = PlayerRank.allCases.firstIndex(of: self),
              currentIndex < PlayerRank.allCases.count - 1 else {
            return nil
        }
        return PlayerRank.allCases[currentIndex + 1]
    }
    
    /// Get the previous rank (if any)
    var previousRank: PlayerRank? {
        guard let currentIndex = PlayerRank.allCases.firstIndex(of: self),
              currentIndex > 0 else {
            return nil
        }
        return PlayerRank.allCases[currentIndex - 1]
    }
    
    /// Progress toward next rank (0.0 to 1.0)
    func progress(forLevel level: Int) -> Double {
        guard let next = nextRank else { return 1.0 }
        let levelsInRank = next.minLevel - minLevel
        let currentProgress = level - minLevel
        return Double(currentProgress) / Double(levelsInRank)
    }
    
    // MARK: - Comparable
    
    static func < (lhs: PlayerRank, rhs: PlayerRank) -> Bool {
        lhs.minLevel < rhs.minLevel
    }
}
