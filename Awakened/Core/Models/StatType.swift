import SwiftUI

/// Represents the five core stats in the Awakened system
enum StatType: String, Codable, CaseIterable, Identifiable {
    case strength
    case agility
    case vitality
    case sense
    case intelligence
    
    var id: String { rawValue }
    
    /// Full display name
    var displayName: String {
        switch self {
        case .strength: return "Strength"
        case .agility: return "Agility"
        case .vitality: return "Vitality"
        case .sense: return "Sense"
        case .intelligence: return "Intelligence"
        }
    }
    
    /// Short 3-letter abbreviation
    var shortName: String {
        switch self {
        case .strength: return "STR"
        case .agility: return "AGI"
        case .vitality: return "VIT"
        case .sense: return "SEN"
        case .intelligence: return "INT"
        }
    }
    
    /// SF Symbol icon name
    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .agility: return "figure.flexibility"
        case .vitality: return "heart.fill"
        case .sense: return "eye.fill"
        case .intelligence: return "brain.head.profile"
        }
    }
    
    /// Associated color for this stat
    var color: Color {
        switch self {
        case .strength: return AppColors.strengthColor
        case .agility: return AppColors.agilityColor
        case .vitality: return AppColors.vitalityColor
        case .sense: return AppColors.senseColor
        case .intelligence: return AppColors.intelligenceColor
        }
    }
    
    /// Description of what this stat represents
    var description: String {
        switch self {
        case .strength:
            return "Physical power from weight training. Increases damage output and carrying capacity."
        case .agility:
            return "Speed and reflexes from calisthenics. Improves reaction time and flexibility."
        case .vitality:
            return "Endurance from cardio training. Increases stamina and recovery rate."
        case .sense:
            return "Awareness from meditation. Enhances perception, focus, and intuition."
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
            return ["Calisthenics", "Yoga", "Martial arts", "Dance", "Gymnastics"]
        case .vitality:
            return ["Running", "Cycling", "Swimming", "HIIT", "Walking"]
        case .sense:
            return ["Meditation", "Mindfulness", "Breathing exercises", "Yoga nidra"]
        case .intelligence:
            return ["Reading", "Coding", "Learning courses", "Writing", "Problem solving"]
        }
    }
    
    /// Order for display (matches radar chart vertices)
    var displayOrder: Int {
        switch self {
        case .strength: return 0
        case .agility: return 1
        case .vitality: return 2
        case .sense: return 3
        case .intelligence: return 4
        }
    }
    
    /// Get all stat types in display order
    static var orderedCases: [StatType] {
        allCases.sorted { $0.displayOrder < $1.displayOrder }
    }
}
