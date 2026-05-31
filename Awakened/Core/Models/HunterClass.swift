import SwiftUI

/// Hunter class (job) determined by the player's dominant stat distribution.
/// Based on Solo Leveling's six hunter class types.
/// Assigned once the player reaches D-Rank (level 10) — before that, class is nil ("None").
enum HunterClass: String, Codable, CaseIterable, Identifiable {
    case fighter
    case assassin
    case tanker
    case ranger
    case mage
    case healer
    
    var id: String { rawValue }
    
    // MARK: - Display
    
    /// Human-readable class name
    var displayName: String {
        switch self {
        case .fighter:  return "Fighter"
        case .assassin: return "Assassin"
        case .tanker:   return "Tanker"
        case .ranger:   return "Ranger"
        case .mage:     return "Mage"
        case .healer:   return "Healer"
        }
    }
    
    /// Short description of the class
    var description: String {
        switch self {
        case .fighter:  return "Balanced melee combat specialist"
        case .assassin: return "Speed and stealth operative"
        case .tanker:   return "Defensive frontline guardian"
        case .ranger:   return "Ranged endurance attacker"
        case .mage:     return "Intelligence-based strategist"
        case .healer:   return "Recovery and support specialist"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .fighter:  return "figure.martial.arts"
        case .assassin: return "figure.run"
        case .tanker:   return "shield.checkered"
        case .ranger:   return "scope"
        case .mage:     return "wand.and.stars"
        case .healer:   return "cross.circle.fill"
        }
    }
    
    /// Class color
    var color: Color {
        switch self {
        case .fighter:  return AppColors.strengthColor
        case .assassin: return AppColors.agilityColor
        case .tanker:   return AppColors.vitalityColor
        case .ranger:   return Color.orange
        case .mage:     return AppColors.intelligenceColor
        case .healer:   return AppColors.senseColor
        }
    }
    
    /// Category label (Fighter Type or Mage Type)
    var category: String {
        switch self {
        case .fighter, .assassin, .tanker, .ranger:
            return "Fighter Type"
        case .mage, .healer:
            return "Mage Type"
        }
    }
    
    /// Primary stat that drives this class
    var primaryStat: StatType {
        switch self {
        case .fighter:  return .strength
        case .assassin: return .agility
        case .tanker:   return .vitality
        case .ranger:   return .agility
        case .mage:     return .intelligence
        case .healer:   return .sense
        }
    }
    
    // MARK: - Classification
    
    /// Determine the hunter class from a player's stat distribution.
    ///
    /// Logic:
    /// - Sort stats by effective level descending.
    /// - If a single stat is clearly dominant (≥ 20% higher than 2nd), assign its direct class.
    /// - If AGI and VIT are both in top 2 and close (within 20%), assign Ranger (endurance runner profile).
    /// - If STR and VIT are both in top 2 and close, assign Tanker (strength + endurance).
    /// - Otherwise, assign based on the #1 stat.
    ///
    /// - Parameter stats: The player's stat array
    /// - Returns: The computed hunter class
    static func classify(from stats: [Stat]) -> HunterClass {
        guard !stats.isEmpty else { return .fighter }
        
        let sorted = stats.sorted { $0.effectiveLevel > $1.effectiveLevel }
        
        guard sorted.count >= 2 else {
            return directClass(for: sorted[0].type)
        }
        
        let top = sorted[0]
        let second = sorted[1]
        
        let dominanceRatio: Double = second.effectiveLevel > 0
            ? Double(top.effectiveLevel) / Double(second.effectiveLevel)
            : 2.0
        
        let topTypes = Set([top.type, second.type])
        
        // Clear dominance — single stat stands out
        if dominanceRatio >= 1.2 {
            return directClass(for: top.type)
        }
        
        // Hybrid detection when top two are close
        if topTypes == Set([.agility, .vitality]) {
            return .ranger
        }
        if topTypes == Set([.strength, .vitality]) {
            return .tanker
        }
        if topTypes == Set([.strength, .agility]) {
            return .assassin
        }
        if topTypes == Set([.intelligence, .sense]) {
            return .healer
        }
        
        // Default: highest stat
        return directClass(for: top.type)
    }
    
    /// Simple 1-to-1 stat → class mapping
    private static func directClass(for statType: StatType) -> HunterClass {
        switch statType {
        case .strength:     return .fighter
        case .agility:      return .assassin
        case .vitality:     return .tanker
        case .intelligence: return .mage
        case .sense:        return .healer
        }
    }
}
