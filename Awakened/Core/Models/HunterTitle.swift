import SwiftUI

/// Titles earned by the player based on milestones and activity patterns.
/// Inspired by Solo Leveling's title system (e.g., "Wolf Assassin", "Demon Hunter").
struct HunterTitle: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let requiredRank: PlayerRank
    
    /// All available titles and their unlock conditions
    static let allTitles: [HunterTitle] = [
        // Rank-based titles
        HunterTitle(id: "novice_hunter",    name: "Novice Hunter",    description: "Reach D-Rank",              icon: "shield.fill",                    requiredRank: .d),
        HunterTitle(id: "proven_hunter",    name: "Proven Hunter",    description: "Reach C-Rank",              icon: "shield.lefthalf.filled",         requiredRank: .c),
        HunterTitle(id: "elite_hunter",     name: "Elite Hunter",     description: "Reach B-Rank",              icon: "shield.checkered",               requiredRank: .b),
        HunterTitle(id: "apex_hunter",      name: "Apex Hunter",      description: "Reach A-Rank",              icon: "star.shield",                    requiredRank: .a),
        HunterTitle(id: "national_level",   name: "National Level",   description: "Reach S-Rank",              icon: "star.shield.fill",               requiredRank: .s),
        HunterTitle(id: "shadow_monarch",   name: "Shadow Monarch",   description: "Reach SS-Rank",             icon: "crown",                          requiredRank: .ss),
        HunterTitle(id: "absolute_being",   name: "Absolute Being",   description: "Reach SSS-Rank",            icon: "crown.fill",                     requiredRank: .sss),
        
        // Streak-based titles
        HunterTitle(id: "iron_will",        name: "Iron Will",        description: "7-day streak",              icon: "flame.fill",                     requiredRank: .e),
        HunterTitle(id: "unbreakable",      name: "Unbreakable",      description: "30-day streak",             icon: "flame.circle.fill",              requiredRank: .e),
        HunterTitle(id: "relentless",       name: "Relentless",       description: "100-day streak",            icon: "bolt.shield.fill",               requiredRank: .e),
        
        // Class-based titles (earned by reaching certain levels in the primary stat)
        HunterTitle(id: "steel_fist",       name: "Steel Fist",       description: "STR stat reaches level 25", icon: "figure.strengthtraining.traditional", requiredRank: .e),
        HunterTitle(id: "wind_walker",      name: "Wind Walker",      description: "AGI stat reaches level 25", icon: "figure.run",                     requiredRank: .e),
        HunterTitle(id: "stone_heart",      name: "Stone Heart",      description: "VIT stat reaches level 25", icon: "heart.fill",                     requiredRank: .e),
        HunterTitle(id: "third_eye",        name: "Third Eye",        description: "SEN stat reaches level 25", icon: "eye.fill",                       requiredRank: .e),
        HunterTitle(id: "sage_mind",        name: "Sage Mind",        description: "INT stat reaches level 25", icon: "brain.head.profile",             requiredRank: .e),
        
        // Penalty zone titles
        HunterTitle(id: "penalty_survivor", name: "Penalty Survivor", description: "Escape the Penalty Zone",   icon: "exclamationmark.triangle.fill",  requiredRank: .e),
    ]
    
    /// Determine the best (highest priority) title a player has earned.
    /// - Parameter player: The player to evaluate
    /// - Returns: The highest-priority earned title, or nil if none earned
    static func currentTitle(for player: Player) -> HunterTitle? {
        let earned = earnedTitles(for: player)
        return earned.last // Highest priority is last (rank-based titles at top)
    }
    
    /// All titles the player has earned, sorted by priority (lowest first).
    /// - Parameter player: The player to evaluate
    /// - Returns: Array of earned titles
    static func earnedTitles(for player: Player) -> [HunterTitle] {
        allTitles.filter { title in
            checkUnlocked(title: title, player: player)
        }
    }
    
    /// Check if a specific title is unlocked for a player.
    private static func checkUnlocked(title: HunterTitle, player: Player) -> Bool {
        switch title.id {
        // Rank-based
        case "novice_hunter":    return player.level >= PlayerRank.d.minLevel
        case "proven_hunter":    return player.level >= PlayerRank.c.minLevel
        case "elite_hunter":     return player.level >= PlayerRank.b.minLevel
        case "apex_hunter":      return player.level >= PlayerRank.a.minLevel
        case "national_level":   return player.level >= PlayerRank.s.minLevel
        case "shadow_monarch":   return player.level >= PlayerRank.ss.minLevel
        case "absolute_being":   return player.level >= PlayerRank.sss.minLevel
            
        // Streak-based
        case "iron_will":        return player.longestStreak >= 7
        case "unbreakable":      return player.longestStreak >= 30
        case "relentless":       return player.longestStreak >= 100
            
        // Stat-based
        case "steel_fist":       return (player.stat(for: .strength)?.effectiveLevel ?? 0) >= 25
        case "wind_walker":      return (player.stat(for: .agility)?.effectiveLevel ?? 0) >= 25
        case "stone_heart":      return (player.stat(for: .vitality)?.effectiveLevel ?? 0) >= 25
        case "third_eye":        return (player.stat(for: .sense)?.effectiveLevel ?? 0) >= 25
        case "sage_mind":        return (player.stat(for: .intelligence)?.effectiveLevel ?? 0) >= 25
            
        // Special
        case "penalty_survivor": return player.longestStreak >= 3 && !player.isInPenaltyZone
            
        default: return false
        }
    }
}
