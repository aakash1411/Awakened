import Foundation
import SwiftData

/// Calculates Strength XP from workout sessions and detects personal records
struct WorkoutXPService {
    
    // MARK: - Constants
    
    /// Maximum XP earnable per session
    static let sessionXPCap = 500
    
    /// Progressive overload bonus multiplier
    static let progressiveOverloadBonus = 1.25
    
    /// Failure set bonus multiplier
    static let failureBonus = 1.15
    
    /// Warmup set multiplier (reduced XP)
    static let warmupMultiplier = 0.25
    
    /// Drop set multiplier
    static let dropSetMultiplier = 0.75
    
    // MARK: - XP Calculation
    
    /// Calculate total XP for a completed workout session
    /// - Parameters:
    ///   - session: The completed workout session
    ///   - context: SwiftData model context for looking up previous bests
    /// - Returns: Total XP earned
    static func calculateSessionXP(
        session: WorkoutSession,
        context: ModelContext
    ) -> Int {
        var totalXP = 0.0
        
        // Group sets by exercise
        let groups = session.exerciseGroups
        
        for group in groups {
            let previousBest = fetchPreviousBest(
                exerciseName: group.name,
                context: context,
                excludingSession: session.id
            )
            
            for set in group.sets {
                totalXP += calculateSetXP(set: set, previousBest: previousBest)
            }
        }
        
        // Apply session cap
        return min(Int(totalXP), sessionXPCap)
    }
    
    /// Calculate XP for a single set
    /// - Parameters:
    ///   - set: The workout set
    ///   - previousBest: Previous best weight for this exercise
    /// - Returns: XP earned from this set
    static func calculateSetXP(set: WorkoutSet, previousBest: Double?) -> Double {
        guard set.reps > 0 else { return 0 }
        
        // Base XP: reps × (weight / 10)
        // For bodyweight exercises (weight = 0), use reps × 2
        let baseXP: Double
        if set.weight > 0 {
            baseXP = Double(set.reps) * (set.weight / 10.0)
        } else {
            baseXP = Double(set.reps) * 2.0
        }
        
        // Apply multipliers
        var multiplier = 1.0
        
        // Warmup sets get reduced XP
        if set.isWarmup {
            multiplier *= warmupMultiplier
        }
        
        // Drop sets get slightly reduced XP
        if set.isDropSet {
            multiplier *= dropSetMultiplier
        }
        
        // Failure bonus
        if set.isFailure {
            multiplier *= failureBonus
        }
        
        // Progressive overload bonus
        if let prevBest = previousBest, set.weight > prevBest {
            multiplier *= progressiveOverloadBonus
        }
        
        return max(1, baseXP * multiplier)
    }
    
    // MARK: - Personal Records
    
    /// Check for and record personal records from a workout session
    /// - Parameters:
    ///   - session: The completed workout session
    ///   - context: SwiftData model context
    ///   - player: The player to associate PRs with
    /// - Returns: Array of new personal records
    @discardableResult
    static func checkForPRs(
        session: WorkoutSession,
        context: ModelContext,
        player: Player
    ) -> [PersonalRecord] {
        var newPRs: [PersonalRecord] = []
        
        let groups = session.exerciseGroups
        
        for group in groups {
            guard let exerciseId = group.exerciseId else { continue }
            
            let workingSets = group.sets.filter { !$0.isWarmup }
            guard !workingSets.isEmpty else { continue }
            
            // Check max weight PR
            if let heaviestSet = workingSets.max(by: { $0.weight < $1.weight }) {
                if let pr = checkAndCreatePR(
                    exerciseId: exerciseId,
                    exerciseName: group.name,
                    recordType: .maxWeight,
                    newValue: heaviestSet.weight,
                    sessionId: session.id,
                    context: context,
                    player: player
                ) {
                    newPRs.append(pr)
                }
            }
            
            // Check max reps PR (at any weight)
            if let mostReps = workingSets.max(by: { $0.reps < $1.reps }) {
                if let pr = checkAndCreatePR(
                    exerciseId: exerciseId,
                    exerciseName: group.name,
                    recordType: .maxReps,
                    newValue: Double(mostReps.reps),
                    sessionId: session.id,
                    context: context,
                    player: player
                ) {
                    newPRs.append(pr)
                }
            }
            
            // Check max volume PR (single set)
            if let maxVolume = workingSets.max(by: { $0.volume < $1.volume }) {
                if let pr = checkAndCreatePR(
                    exerciseId: exerciseId,
                    exerciseName: group.name,
                    recordType: .maxVolume,
                    newValue: maxVolume.volume,
                    sessionId: session.id,
                    context: context,
                    player: player
                ) {
                    newPRs.append(pr)
                }
            }
            
            // Check estimated 1RM PR
            let best1RM = workingSets.map { set in
                PersonalRecord.estimated1RM(weight: set.weight, reps: set.reps)
            }.max() ?? 0
            
            if best1RM > 0 {
                if let pr = checkAndCreatePR(
                    exerciseId: exerciseId,
                    exerciseName: group.name,
                    recordType: .estimated1RM,
                    newValue: best1RM,
                    sessionId: session.id,
                    context: context,
                    player: player
                ) {
                    newPRs.append(pr)
                }
            }
        }
        
        if !newPRs.isEmpty {
            try? context.save()
        }
        
        return newPRs
    }
    
    // MARK: - Helpers
    
    /// Fetch the previous best weight for an exercise
    private static func fetchPreviousBest(
        exerciseName: String,
        context: ModelContext,
        excludingSession: UUID
    ) -> Double? {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { record in
                record.exerciseName == exerciseName && record.recordTypeRaw == "maxWeight"
            }
        )
        
        let records = (try? context.fetch(descriptor)) ?? []
        return records.first?.value
    }
    
    /// Check if a new value beats the existing PR and create record if so
    private static func checkAndCreatePR(
        exerciseId: UUID,
        exerciseName: String,
        recordType: RecordType,
        newValue: Double,
        sessionId: UUID,
        context: ModelContext,
        player: Player
    ) -> PersonalRecord? {
        guard newValue > 0 else { return nil }
        
        let typeRaw = recordType.rawValue
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { record in
                record.exerciseName == exerciseName && record.recordTypeRaw == typeRaw
            }
        )
        
        let existingRecords = (try? context.fetch(descriptor)) ?? []
        let existingBest = existingRecords.first
        
        if let existing = existingBest {
            if newValue > existing.value {
                // Beat the record — update it
                existing.previousValue = existing.value
                existing.value = newValue
                existing.achievedAt = Date()
                existing.workoutSessionId = sessionId
                return existing
            }
            return nil // Didn't beat the record
        } else {
            // First time — create new PR
            let pr = PersonalRecord(
                exerciseId: exerciseId,
                exerciseName: exerciseName,
                recordType: recordType,
                value: newValue,
                workoutSessionId: sessionId,
                player: player
            )
            context.insert(pr)
            return pr
        }
    }
    
    /// Calculate progressive overload percentage
    /// - Parameters:
    ///   - currentWeight: Current weight
    ///   - previousWeight: Previous session weight
    /// - Returns: Percentage increase
    static func progressiveOverloadPercent(currentWeight: Double, previousWeight: Double) -> Double {
        guard previousWeight > 0 else { return 0 }
        return ((currentWeight - previousWeight) / previousWeight) * 100
    }
}
