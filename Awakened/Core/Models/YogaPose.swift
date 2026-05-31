import Foundation

// MARK: - Pose Difficulty

/// Difficulty levels for yoga poses
enum PoseDifficulty: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        rawValue.capitalized
    }
    
    /// Color-associated icon
    var icon: String {
        switch self {
        case .beginner: return "leaf.fill"
        case .intermediate: return "flame.fill"
        case .advanced: return "bolt.fill"
        }
    }
}

// MARK: - Yoga Pose

/// Represents a single yoga pose in a session
struct YogaPose: Identifiable, Codable {
    let id: UUID
    let name: String
    let sanskritName: String?
    let duration: TimeInterval
    let difficulty: PoseDifficulty
    
    /// Formatted duration (e.g., "30s" or "2 min")
    var durationFormatted: String {
        let seconds = Int(duration)
        if seconds >= 60 {
            let minutes = seconds / 60
            let secs = seconds % 60
            return secs > 0 ? "\(minutes)m \(secs)s" : "\(minutes) min"
        }
        return "\(seconds)s"
    }
    
    /// Display name with optional Sanskrit
    var fullName: String {
        if let sanskrit = sanskritName {
            return "\(name) (\(sanskrit))"
        }
        return name
    }
    
    init(
        name: String,
        sanskritName: String? = nil,
        duration: TimeInterval = 30,
        difficulty: PoseDifficulty = .beginner
    ) {
        self.id = UUID()
        self.name = name
        self.sanskritName = sanskritName
        self.duration = duration
        self.difficulty = difficulty
    }
}
