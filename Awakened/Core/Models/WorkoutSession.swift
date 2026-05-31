import Foundation
import SwiftData

/// Represents a completed or in-progress gym session
@Model
final class WorkoutSession {
    
    /// Unique identifier
    var id: UUID
    
    /// Session name (e.g., "Push Day", "Full Body")
    var name: String
    
    /// Date of the workout
    var date: Date
    
    /// When the session started
    var startTime: Date
    
    /// When the session ended (nil if still in progress)
    var endTime: Date?
    
    /// Total duration in seconds (stored on finish)
    var durationSeconds: Int
    
    /// Optional session notes
    var notes: String
    
    /// Whether the session has been completed
    var isCompleted: Bool
    
    /// Total XP earned from this session
    var xpEarned: Int
    
    /// Number of PRs achieved
    var prCount: Int
    
    /// All sets in this session
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.session)
    var sets: [WorkoutSet]
    
    /// The player who performed this workout
    @Relationship
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Total volume across all sets (weight × reps)
    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }
    
    /// Number of unique exercises in this session
    var exerciseCount: Int {
        Set(sets.map { $0.exerciseName }).count
    }
    
    /// Total number of working sets (excluding warmups)
    var workingSetCount: Int {
        sets.filter { !$0.isWarmup }.count
    }
    
    /// Total number of sets including warmups
    var totalSetCount: Int {
        sets.count
    }
    
    /// Whether this session is currently in progress
    var isInProgress: Bool {
        !isCompleted && endTime == nil
    }
    
    /// Duration formatted as "1h 15m" or "45m"
    var durationFormatted: String {
        let duration = isInProgress
            ? Int(Date().timeIntervalSince(startTime))
            : durationSeconds
        
        let hours = duration / 3600
        let minutes = (duration % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    /// Volume formatted with units
    var volumeFormatted: String {
        if totalVolume >= 1000 {
            return String(format: "%.1fk kg", totalVolume / 1000)
        }
        return String(format: "%.0f kg", totalVolume)
    }
    
    /// Exercises grouped by name, preserving order of first appearance
    var exerciseGroups: [(name: String, exerciseId: UUID?, sets: [WorkoutSet])] {
        var groups: [(name: String, exerciseId: UUID?, sets: [WorkoutSet])] = []
        var seen: Set<String> = []
        
        for set in sets.sorted(by: { $0.completedAt < $1.completedAt }) {
            if seen.contains(set.exerciseName) {
                if let idx = groups.firstIndex(where: { $0.name == set.exerciseName }) {
                    groups[idx].sets.append(set)
                }
            } else {
                seen.insert(set.exerciseName)
                groups.append((name: set.exerciseName, exerciseId: set.exerciseId, sets: [set]))
            }
        }
        
        return groups
    }
    
    // MARK: - Methods
    
    /// Finish the workout session
    func finish() {
        endTime = Date()
        isCompleted = true
        durationSeconds = Int(Date().timeIntervalSince(startTime))
    }
    
    /// Add a set to this session
    /// - Parameter set: The workout set to add
    func addSet(_ set: WorkoutSet) {
        set.session = self
        sets.append(set)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        name: String = "Workout",
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationSeconds: Int = 0,
        notes: String = "",
        isCompleted: Bool = false,
        xpEarned: Int = 0,
        prCount: Int = 0,
        sets: [WorkoutSet] = [],
        player: Player? = nil
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.isCompleted = isCompleted
        self.xpEarned = xpEarned
        self.prCount = prCount
        self.sets = sets
        self.player = player
    }
}
