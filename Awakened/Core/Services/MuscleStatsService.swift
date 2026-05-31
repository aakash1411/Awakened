import Foundation
import SwiftUI
import SwiftData

/// Coarse anatomy regions used by `MuscleMapView`.
/// We aggregate the fine-grained `MuscleGroup` values (`primaryMuscles` from the
/// exercise DB) into these high-level regions for the body-map UI.
enum AnatomyRegion: String, CaseIterable, Identifiable {
    case chest, back, shoulders, biceps, triceps, forearms
    case abs, glutes, quads, hamstrings, calves
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .forearms: return "Forearms"
        case .abs: return "Abs"
        case .glutes: return "Glutes"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .calves: return "Calves"
        }
    }
    
    /// Whether this region appears on the front silhouette (else back).
    var isFront: Bool {
        switch self {
        case .chest, .biceps, .forearms, .abs, .quads: return true
        case .back, .triceps, .hamstrings, .glutes: return false
        case .shoulders, .calves: return true // show on front by default; we draw both
        }
    }
    
    /// Map fine-grained `MuscleGroup` → coarse region for the body-map UI.
    static func from(_ muscle: MuscleGroup) -> AnatomyRegion? {
        switch muscle {
        case .chest: return .chest
        case .lats, .middleBack, .lowerBack, .traps: return .back
        case .shoulders: return .shoulders
        case .biceps: return .biceps
        case .triceps: return .triceps
        case .forearms: return .forearms
        case .abdominals: return .abs
        case .glutes: return .glutes
        case .quadriceps, .abductors, .adductors: return .quads
        case .hamstrings: return .hamstrings
        case .calves: return .calves
        case .neck, .fullBody, .cardio: return nil
        }
    }
}

/// Discrete level for a muscle region, used for color coding.
enum MuscleLevel: Int, CaseIterable {
    case untrained = 0   // gray
    case novice = 1      // light blue
    case intermediate = 2 // green
    case advanced = 3    // orange
    case elite = 4       // red
    
    var label: String {
        switch self {
        case .untrained:    return "Untrained"
        case .novice:       return "Novice"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        case .elite:        return "Elite"
        }
    }
    
    var color: Color {
        switch self {
        case .untrained:    return Color(hex: "55606F")
        case .novice:       return Color(hex: "5AC8FA")
        case .intermediate: return Color(hex: "34C759")
        case .advanced:     return Color(hex: "FF9500")
        case .elite:        return Color(hex: "FF3B30")
        }
    }
}

/// Per-region training data, derived from logged WorkoutSet history.
struct MuscleRegionStats {
    let region: AnatomyRegion
    /// Total volume (kg × reps) ever logged for this region
    let totalVolume: Double
    /// Number of sets logged in the last 30 days
    let recentSets: Int
    /// Days since the last logged set targeting this region (nil if never)
    let daysSinceLast: Int?
    /// Computed level
    let level: MuscleLevel
}

/// Computes per-muscle-group strength levels from a player's logged WorkoutSets.
///
/// **Method (volume + bodyweight bucket):**
/// - For each WorkoutSet, find the matching `Exercise` by `exerciseId`.
/// - Add `set.volume` (= weight × reps) to the primary region (1.0 weight)
///   and to each secondary region (0.5 weight).
/// - Convert total volume → MuscleLevel via thresholds scaled to the player's
///   bodyweight bucket. Heavier hunters need more volume to level up.
@MainActor
struct MuscleStatsService {
    let modelContext: ModelContext
    let player: Player
    
    /// Bodyweight in kg (from `Player.weightKg`, defaults to 75 kg if not set).
    var bodyweightKg: Double {
        let kg = (player.weightKg ?? 0)
        return kg > 0 ? kg : 75
    }
    
    /// Bodyweight bucket — adjusts level thresholds. Heavier = higher requirements.
    /// Returns a multiplier applied to the base thresholds.
    var bodyweightMultiplier: Double {
        let bw = bodyweightKg
        switch bw {
        case ..<55:   return 0.7
        case 55..<70: return 0.85
        case 70..<85: return 1.0
        case 85..<100: return 1.15
        default:      return 1.3
        }
    }
    
    /// Base volume thresholds (in kg-reps) for level transitions.
    /// Tuned so a typical 70-85 kg lifter hitting 3 sessions/week lands at intermediate after a few months.
    private static let baseThresholds: [(MuscleLevel, Double)] = [
        (.novice,        2_000),    // ~10 sets of 50 kg × 4 reps
        (.intermediate,  15_000),   // ~75 sets of 60 kg × ~3 reps spread
        (.advanced,      60_000),
        (.elite,        180_000)
    ]
    
    /// Compute stats for every region.
    func computeAll() -> [AnatomyRegion: MuscleRegionStats] {
        // Fetch all exercises once; build lookup by id and by exerciseName
        let exercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let byID: [UUID: Exercise] = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        let byName: [String: Exercise] = Dictionary(uniqueKeysWithValues: exercises.map { ($0.name.lowercased(), $0) })
        
        // Aggregate per region
        var totals: [AnatomyRegion: Double] = [:]
        var recentCounts: [AnatomyRegion: Int] = [:]
        var lastDates: [AnatomyRegion: Date] = [:]
        
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        for session in player.workoutSessions {
            for set in session.sets {
                guard let ex = lookupExercise(set: set, byID: byID, byName: byName) else { continue }
                
                // Primary region (full weight)
                if let primary = AnatomyRegion.from(ex.muscleGroup) {
                    totals[primary, default: 0] += set.volume
                    if set.completedAt >= thirtyDaysAgo { recentCounts[primary, default: 0] += 1 }
                    if (lastDates[primary] ?? .distantPast) < set.completedAt {
                        lastDates[primary] = set.completedAt
                    }
                }
                // Secondary regions (half weight)
                for sec in ex.secondaryMuscles {
                    if let region = AnatomyRegion.from(sec) {
                        totals[region, default: 0] += set.volume * 0.5
                        if set.completedAt >= thirtyDaysAgo { recentCounts[region, default: 0] += 1 }
                        if (lastDates[region] ?? .distantPast) < set.completedAt {
                            lastDates[region] = set.completedAt
                        }
                    }
                }
            }
        }
        
        // Map to MuscleRegionStats
        var result: [AnatomyRegion: MuscleRegionStats] = [:]
        for region in AnatomyRegion.allCases {
            let volume = totals[region] ?? 0
            let recent = recentCounts[region] ?? 0
            let daysSince: Int? = lastDates[region].map {
                Calendar.current.dateComponents([.day], from: $0, to: now).day ?? 0
            }
            result[region] = MuscleRegionStats(
                region: region,
                totalVolume: volume,
                recentSets: recent,
                daysSinceLast: daysSince,
                level: levelFor(volume: volume)
            )
        }
        return result
    }
    
    /// Convert total volume → MuscleLevel using bodyweight-adjusted thresholds.
    func levelFor(volume: Double) -> MuscleLevel {
        let mult = bodyweightMultiplier
        var current: MuscleLevel = .untrained
        for (level, threshold) in Self.baseThresholds {
            if volume >= threshold * mult {
                current = level
            } else {
                break
            }
        }
        return current
    }
    
    /// Best-effort lookup: prefer `exerciseId` match, fall back to name.
    private func lookupExercise(
        set: WorkoutSet,
        byID: [UUID: Exercise],
        byName: [String: Exercise]
    ) -> Exercise? {
        if let id = set.exerciseId, let ex = byID[id] { return ex }
        return byName[set.exerciseName.lowercased()]
    }
}
