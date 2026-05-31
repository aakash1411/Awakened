import Foundation

/// Calculates "Strength Points" (SP) for the daily strength quest from
/// bodyweight exercise reps + a walking-steps movement bonus.
///
/// Mapping:
/// - Pushup / dip                        → 1.0 SP per rep
/// - Pullup / chin-up / muscle-up        → 3.0 SP per rep (compound, harder)
/// - Situp / crunch / leg-raise / plank  → 0.5 SP per rep
/// - Walking                             → 1 SP per 100 steps (cap 30 SP from steps)
///
/// Default daily target: 50 SP.
struct StrengthPointsCalculator {
    
    /// Per-rep SP multiplier classes
    enum RepClass {
        case heavyPush   // 1.0 SP
        case heavyPull   // 3.0 SP
        case core        // 0.5 SP
        
        var multiplier: Double {
            switch self {
            case .heavyPush: return 1.0
            case .heavyPull: return 3.0
            case .core:      return 0.5
            }
        }
    }
    
    /// Maximum SP contribution from walking steps in a single day
    static let maxStepsContribution: Double = 30.0
    
    /// Steps required to earn 1 SP from walking
    static let stepsPerPoint: Double = 100.0
    
    // MARK: - Classification
    
    /// Classify an exercise by its name. Returns nil if it doesn't qualify
    /// for strength-quest credit (e.g. cardio, gym lifts with weights).
    /// - Parameter name: Exercise display name (case-insensitive match)
    static func classify(exerciseName name: String) -> RepClass? {
        let lower = name.lowercased()
        
        // Heavy pull movements
        if lower.contains("pull-up") || lower.contains("pullup") ||
           lower.contains("pull up") || lower.contains("chin-up") ||
           lower.contains("chinup") || lower.contains("chin up") ||
           lower.contains("muscle-up") || lower.contains("muscle up") {
            return .heavyPull
        }
        
        // Core movements
        if lower.contains("crunch") || lower.contains("sit-up") ||
           lower.contains("situp") || lower.contains("sit up") ||
           lower.contains("leg raise") || lower.contains("leg-raise") ||
           lower.contains("plank") || lower.contains("ab wheel") ||
           lower.contains("hollow") || lower.contains("v-up") ||
           lower.contains("flutter kick") || lower.contains("russian twist") {
            return .core
        }
        
        // Heavy push movements (pushup variants, dips)
        if lower.contains("push-up") || lower.contains("pushup") ||
           lower.contains("push up") || lower.contains("dip") ||
           lower.contains("burpee") {
            return .heavyPush
        }
        
        return nil
    }
    
    // MARK: - SP Calculation
    
    /// Compute total SP from a list of (exerciseName, reps) pairs and step count.
    /// - Parameters:
    ///   - reps: Array of (exerciseName, repCount) for today's bodyweight work
    ///   - steps: Today's walking steps
    /// - Returns: Total SP earned today
    static func points(reps: [(name: String, count: Int)], steps: Int) -> Double {
        let repsSP = reps.reduce(0.0) { acc, entry in
            guard let cls = classify(exerciseName: entry.name) else { return acc }
            return acc + Double(entry.count) * cls.multiplier
        }
        
        let stepsSP = min(Double(steps) / stepsPerPoint, maxStepsContribution)
        
        return repsSP + stepsSP
    }
    
    /// Convenience: compute SP from today's WorkoutSession reps and steps.
    /// - Parameters:
    ///   - workoutSets: All completed sets from today's workout sessions
    ///   - steps: Today's walking steps from HealthKit
    /// - Returns: Total SP earned today
    static func points(fromSets workoutSets: [WorkoutSet], steps: Int) -> Double {
        let pairs = workoutSets
            .filter { !$0.isWarmup && $0.reps > 0 }
            .map { (name: $0.exerciseName, count: $0.reps) }
        return points(reps: pairs, steps: steps)
    }
}
