import Foundation

/// Per-muscle training data that drives the 3D body's colour, glow and the
/// detail panel. Kept as a plain value type so it can come from real logged
/// workouts (`MuscleStatsService`) or from mock data interchangeably.
struct MuscleScore: Identifiable, Hashable {
    let region: MuscleRegion
    /// Discrete tier 0...4 (untrained → elite). Drives the base colour ramp.
    var level: Int
    /// Strength score 0...100, shown as the muscle "Lv." in the UI.
    var score: Int
    /// Recent fatigue 0...1. High fatigue adds a warm red/orange overlay.
    var fatigue: Double
    /// Signed weekly trend, e.g. +6 means +6% volume vs last week.
    var growthTrend: Double
    /// Recent training activation 0...1 (how much it's been worked lately).
    var activation: Double

    var id: MuscleRegion { region }

    /// Score normalised to 0...1 for colour interpolation.
    var normalizedScore: Double { Double(max(0, min(100, score))) / 100 }

    /// Human label for the current tier.
    var levelLabel: String {
        switch max(0, min(4, level)) {
        case 0: return "Untrained"
        case 1: return "Novice"
        case 2: return "Intermediate"
        case 3: return "Advanced"
        default: return "Elite"
        }
    }

    /// A zero/empty score for regions with no data yet.
    static func empty(_ region: MuscleRegion) -> MuscleScore {
        MuscleScore(region: region, level: 0, score: 0, fatigue: 0, growthTrend: 0, activation: 0)
    }
}

// MARK: - Bridging from real workout stats

extension MuscleScore {
    /// Build a full `[MuscleRegion: MuscleScore]` from the legacy
    /// `MuscleStatsService` output.
    static func from(stats: [AnatomyRegion: MuscleRegionStats]) -> [MuscleRegion: MuscleScore] {
        var result: [MuscleRegion: MuscleScore] = [:]
        for region in MuscleRegion.allCases {
            let s = stats[region.anatomyRegion]
            let level = s?.level.rawValue ?? 0
            // Spread the discrete tier into a friendlier 0...100 score.
            let score = min(100, level * 22 + min(12, (s?.recentSets ?? 0)))
            result[region] = MuscleScore(
                region: region,
                level: level,
                score: score,
                fatigue: fatigue(fromDaysSince: s?.daysSinceLast),
                growthTrend: 0,
                activation: activation(fromRecentSets: s?.recentSets ?? 0)
            )
        }
        return result
    }

    /// Recently trained → higher fatigue; long rest → fully recovered.
    private static func fatigue(fromDaysSince days: Int?) -> Double {
        guard let days else { return 0 }
        switch days {
        case 0: return 0.9
        case 1: return 0.6
        case 2: return 0.35
        case 3: return 0.15
        default: return 0
        }
    }

    private static func activation(fromRecentSets sets: Int) -> Double {
        min(1, Double(sets) / 20.0)
    }

    /// True when there is no logged training at all (drives the mock fallback).
    static func isEmpty(_ scores: [MuscleRegion: MuscleScore]) -> Bool {
        scores.values.allSatisfy { $0.score == 0 }
    }
}

// MARK: - Mock data (first-run demo / SwiftUI previews)

extension MuscleScore {
    /// Rich sample data resembling the design mockups, used before the user
    /// has logged any workouts and in previews.
    static let mock: [MuscleRegion: MuscleScore] = {
        let raw: [(MuscleRegion, Int, Double, Double, Double)] = [
            // region, score, fatigue, growthTrend, activation
            (.chest,      78, 0.45,  8, 0.72),
            (.back,       75, 0.30,  6, 0.66),
            (.shoulders,  66, 0.20,  4, 0.55),
            (.biceps,     64, 0.50,  5, 0.60),
            (.triceps,    60, 0.35,  3, 0.52),
            (.forearms,   45, 0.10,  2, 0.40),
            (.abs,        70, 0.25,  7, 0.64),
            (.obliques,   55, 0.15,  3, 0.48),
            (.glutes,     65, 0.20,  5, 0.58),
            (.quads,      72, 0.55,  6, 0.70),
            (.hamstrings, 58, 0.40,  4, 0.50),
            (.calves,     42, 0.05,  1, 0.35)
        ]
        var result: [MuscleRegion: MuscleScore] = [:]
        for (region, score, fatigue, trend, activation) in raw {
            result[region] = MuscleScore(
                region: region,
                level: min(4, score / 22),
                score: score,
                fatigue: fatigue,
                growthTrend: trend,
                activation: activation
            )
        }
        return result
    }()
}
