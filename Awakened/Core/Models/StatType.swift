import SwiftUI

/// Represents the five core stats in the Awakened system
enum StatType: String, Codable, CaseIterable, Identifiable {
    case strength
    case agility
    case vitality
    case sense
    case intelligence
    
    var id: String { rawValue }
    
    /// Full display name.
    /// Note: the enum cases keep their original identifiers (`agility`, `sense`)
    /// for persistence/back-compat, but they are presented as the mockup's
    /// "Five Fields": `agility → Sensation`, `sense → Spirit`.
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .agility: return "Sensation"
        case .vitality: return "Vitality"
        case .sense: return "Spirit"
        case .intelligence: return "Intelligence"
        }
    }
    
    /// Short 3-letter abbreviation
    var shortName: String {
        switch self {
        case .strength: return "STR"
        case .agility: return "SEN"
        case .vitality: return "VIT"
        case .sense: return "SPI"
        case .intelligence: return "INT"
        }
    }
    
    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .agility: return "snowflake"
        case .vitality: return "heart.fill"
        case .sense: return "sparkles"
        case .intelligence: return "brain.head.profile"
        }
    }
    
    /// Associated color for this stat (matches the Anime mockup field colours:
    /// Strength red, Vitality green, Intelligence blue, Spirit purple,
    /// Sensation orange). Reuses the central identity-colour constants.
    var color: Color {
        switch self {
        case .strength: return AppColors.strengthColor      // red
        case .agility: return AppColors.vitalityColor       // Sensation – orange
        case .vitality: return AppColors.agilityColor       // Vitality – green
        case .sense: return AppColors.senseColor            // Spirit – purple
        case .intelligence: return AppColors.intelligenceColor // blue
        }
    }
    
    /// Description of what this stat represents
    var description: String {
        switch self {
        case .strength:
            return "Physical power from weight training. Increases damage output and carrying capacity."
        case .agility:
            return "Resilience from breathwork and cold exposure. Sharpens recovery and body awareness."
        case .vitality:
            return "Endurance from cardio training. Increases stamina and recovery rate."
        case .sense:
            return "Spiritual focus from meditation. Enhances perception, calm, and intuition."
        case .intelligence:
            return "Mental acuity from learning. Expands knowledge and problem-solving ability."
        }
    }
    
    /// Real-world activities that contribute to this stat
    var activities: [String] {
        switch self {
        case .strength:
            return ["Weight lifting", "Resistance training", "Bodyweight exercises", "CrossFit"]
        case .agility:
            return ["Cold shower", "Breathwork", "Mobility", "Yoga", "Stretching"]
        case .vitality:
            return ["Running", "Cycling", "Swimming", "HIIT", "Walking"]
        case .sense:
            return ["Meditation", "Mindfulness", "Breathing exercises", "Yoga nidra"]
        case .intelligence:
            return ["Reading", "Coding", "Learning courses", "Writing", "Problem solving"]
        }
    }
    
    /// Order for display (matches radar chart vertices, clockwise from top):
    /// Strength, Vitality, Sensation, Spirit, Intelligence.
    var displayOrder: Int {
        switch self {
        case .strength: return 0
        case .vitality: return 1
        case .agility: return 2   // Sensation
        case .sense: return 3     // Spirit
        case .intelligence: return 4
        }
    }
    
    /// Get all stat types in display order
    static var orderedCases: [StatType] {
        allCases.sorted { $0.displayOrder < $1.displayOrder }
    }
}
