import Foundation
import HealthKit

// MARK: - Flexibility Type

/// Types of flexibility/agility activities
enum FlexibilityType: String, Codable, CaseIterable, Identifiable {
    case yoga
    case stretching
    case calisthenics
    case mobility
    case dance
    case martialArts
    case gymnastics
    case pilates
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .yoga: return "Yoga"
        case .stretching: return "Stretching"
        case .calisthenics: return "Calisthenics"
        case .mobility: return "Mobility"
        case .dance: return "Dance"
        case .martialArts: return "Martial Arts"
        case .gymnastics: return "Gymnastics"
        case .pilates: return "Pilates"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .yoga: return "figure.yoga"
        case .stretching: return "figure.flexibility"
        case .calisthenics: return "figure.strengthtraining.functional"
        case .mobility: return "figure.cooldown"
        case .dance: return "figure.dance"
        case .martialArts: return "figure.martial.arts"
        case .gymnastics: return "figure.gymnastics"
        case .pilates: return "figure.pilates"
        }
    }
    
    /// Map from HKWorkoutActivityType to FlexibilityType
    static func from(workoutType: HKWorkoutActivityType) -> FlexibilityType? {
        switch workoutType {
        case .yoga: return .yoga
        case .flexibility: return .stretching
        case .coreTraining: return .calisthenics
        case .gymnastics: return .gymnastics
        case .pilates: return .pilates
        case .dance, .socialDance, .cardioDance: return .dance
        case .martialArts: return .martialArts
        default: return nil
        }
    }
}

// MARK: - Flexibility Session

/// Represents a single flexibility/agility session
struct FlexibilitySession: Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let type: FlexibilityType
    let intensity: ActivityIntensity
    let poses: [YogaPose]?
    let notes: String?
    let xpEarned: Int
    let sourceWorkout: HKWorkout?
    
    // MARK: - Computed Properties
    
    /// Formatted duration string (e.g., "45 min")
    var durationFormatted: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes) min"
    }
    
    /// Display name combining type and duration
    var displayName: String {
        type.displayName
    }
    
    /// Icon for this session
    var icon: String {
        type.icon
    }
    
    /// Formatted date string
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Factory
    
    /// Create a FlexibilitySession from an HKWorkout
    static func from(workout: HKWorkout) -> FlexibilitySession? {
        guard let flexType = FlexibilityType.from(workoutType: workout.workoutActivityType) else {
            return nil
        }
        
        let durationMinutes = workout.duration / 60.0
        let intensity: ActivityIntensity = durationMinutes > 45 ? .high : (durationMinutes > 20 ? .medium : .low)
        let xp = XPCalculator.agilityXP(durationMinutes: durationMinutes, intensity: intensity)
        
        return FlexibilitySession(
            id: UUID(),
            date: workout.startDate,
            duration: workout.duration,
            type: flexType,
            intensity: intensity,
            poses: nil,
            notes: nil,
            xpEarned: xp,
            sourceWorkout: workout
        )
    }
    
    /// Create a manual FlexibilitySession
    static func manual(
        type: FlexibilityType,
        duration: TimeInterval,
        intensity: ActivityIntensity,
        poses: [YogaPose]? = nil,
        notes: String? = nil
    ) -> FlexibilitySession {
        let durationMinutes = duration / 60.0
        let xp = XPCalculator.agilityXP(durationMinutes: durationMinutes, intensity: intensity)
        
        return FlexibilitySession(
            id: UUID(),
            date: Date(),
            duration: duration,
            type: type,
            intensity: intensity,
            poses: poses,
            notes: notes,
            xpEarned: xp,
            sourceWorkout: nil
        )
    }
}
