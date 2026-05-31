import Foundation
import HealthKit

// MARK: - Meditation Type

/// Types of meditation practices
enum MeditationType: String, Codable, CaseIterable, Identifiable {
    case mindfulness
    case breathing
    case bodyReflection
    case guided
    case unguided
    case sleep
    case focus
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .mindfulness: return "Mindfulness"
        case .breathing: return "Breathing"
        case .bodyReflection: return "Body Scan"
        case .guided: return "Guided"
        case .unguided: return "Unguided"
        case .sleep: return "Sleep"
        case .focus: return "Focus"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .mindfulness: return "brain.head.profile"
        case .breathing: return "wind"
        case .bodyReflection: return "figure.mind.and.body"
        case .guided: return "headphones"
        case .unguided: return "leaf.fill"
        case .sleep: return "moon.fill"
        case .focus: return "scope"
        }
    }
    
    /// Suggested durations in minutes
    var suggestedDurations: [Int] {
        switch self {
        case .mindfulness: return [5, 10, 15, 20, 30]
        case .breathing: return [3, 5, 10, 15]
        case .bodyReflection: return [10, 15, 20, 30]
        case .guided: return [10, 15, 20, 30, 45]
        case .unguided: return [5, 10, 15, 20, 30, 45, 60]
        case .sleep: return [10, 15, 20, 30]
        case .focus: return [5, 10, 15, 25]
        }
    }
}

// MARK: - Meditation Source

/// Where the meditation session data came from
enum MeditationSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case healthKit
    case builtInTimer
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .healthKit: return "Apple Health"
        case .builtInTimer: return "Timer"
        }
    }
    
    /// Badge icon
    var icon: String {
        switch self {
        case .manual: return "pencil.circle.fill"
        case .healthKit: return "heart.circle.fill"
        case .builtInTimer: return "timer"
        }
    }
}

// MARK: - Meditation Session

/// Represents a single meditation or mindfulness session
struct MeditationSession: Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let type: MeditationType
    let source: MeditationSource
    let notes: String?
    let xpEarned: Int
    
    // MARK: - Computed Properties
    
    /// Formatted duration string (e.g., "15 min")
    var durationFormatted: String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(minutes) min"
    }
    
    /// Display name for the session
    var displayName: String {
        type.displayName
    }
    
    /// Type icon
    var typeIcon: String {
        type.icon
    }
    
    /// Formatted date string
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Short time string (e.g., "3:45 PM")
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Factory
    
    /// Create a MeditationSession from a HealthKit mindful session
    static func from(
        sample: HKCategorySample,
        consecutiveDays: Int = 0
    ) -> MeditationSession {
        let duration = sample.endDate.timeIntervalSince(sample.startDate)
        let durationMinutes = duration / 60.0
        let xp = XPCalculator.senseXP(durationMinutes: durationMinutes, consecutiveDays: consecutiveDays)
        
        return MeditationSession(
            id: UUID(),
            date: sample.startDate,
            duration: duration,
            type: .mindfulness,
            source: .healthKit,
            notes: nil,
            xpEarned: xp
        )
    }
    
    /// Create a manual MeditationSession
    static func manual(
        type: MeditationType,
        duration: TimeInterval,
        notes: String? = nil,
        consecutiveDays: Int = 0
    ) -> MeditationSession {
        let durationMinutes = duration / 60.0
        let xp = XPCalculator.senseXP(durationMinutes: durationMinutes, consecutiveDays: consecutiveDays)
        
        return MeditationSession(
            id: UUID(),
            date: Date(),
            duration: duration,
            type: type,
            source: .manual,
            notes: notes,
            xpEarned: xp
        )
    }
    
    /// Create a session from the built-in timer
    static func fromTimer(
        type: MeditationType,
        duration: TimeInterval,
        consecutiveDays: Int = 0
    ) -> MeditationSession {
        let durationMinutes = duration / 60.0
        let xp = XPCalculator.senseXP(durationMinutes: durationMinutes, consecutiveDays: consecutiveDays)
        
        return MeditationSession(
            id: UUID(),
            date: Date(),
            duration: duration,
            type: type,
            source: .builtInTimer,
            notes: nil,
            xpEarned: xp
        )
    }
}
