import Foundation
import MuscleMap

/// Bridges our internal `AnatomyRegion` (coarse grouping that drives
/// workout volume math) to the fine-grained `MuscleMap.Muscle` cases used
/// by the `BodyView`.
///
/// Why coarse → fine: our exercise DB tags exercises with broad muscle
/// groups (e.g., "back"); the MuscleMap SDK needs us to address upper back,
/// lower back, trapezius, and rhomboids individually so each fragment can
/// be coloured. Mapping one→many means a back workout lights up the whole
/// posterior chain visually.
enum MuscleRegionMapping {
    
    /// All MuscleMap muscles that should be coloured for a given region.
    static func muscles(for region: AnatomyRegion) -> [MuscleMap.Muscle] {
        switch region {
        case .chest:      return [.chest]
        case .back:       return [.upperBack, .lowerBack, .trapezius, .rhomboids]
        case .shoulders:  return [.deltoids, .rotatorCuff]
        case .biceps:     return [.biceps]
        case .triceps:    return [.triceps]
        case .forearms:   return [.forearm]
        case .abs:        return [.abs, .obliques, .serratus]
        case .glutes:     return [.gluteal]
        case .quads:      return [.quadriceps]
        case .hamstrings: return [.hamstring]
        case .calves:     return [.calves, .tibialis]
        }
    }
    
    /// Reverse map for tap detection (which region was tapped given a muscle).
    static func region(for muscle: MuscleMap.Muscle) -> AnatomyRegion? {
        switch muscle {
        case .chest:                                                return .chest
        case .upperBack, .lowerBack, .trapezius, .rhomboids:        return .back
        case .deltoids, .rotatorCuff:                               return .shoulders
        case .biceps:                                               return .biceps
        case .triceps:                                              return .triceps
        case .forearm:                                              return .forearms
        case .abs, .obliques, .serratus:                            return .abs
        case .gluteal:                                              return .glutes
        case .quadriceps:                                           return .quads
        case .hamstring:                                            return .hamstrings
        case .calves, .tibialis:                                    return .calves
        default:                                                    return nil
        }
    }
    
    /// Build the `[Muscle: Int]` payload consumable by `BodyView.intensities(_:)`.
    /// Levels are 0–4, mapping directly to `MuscleLevel.rawValue` and the
    /// SDK's `.workout` colour scale (gray → yellow → orange → red).
    static func intensities(
        from stats: [AnatomyRegion: MuscleRegionStats]
    ) -> [MuscleMap.Muscle: Int] {
        var result: [MuscleMap.Muscle: Int] = [:]
        for region in AnatomyRegion.allCases {
            guard let s = stats[region] else { continue }
            let value = s.level.rawValue
            for muscle in muscles(for: region) {
                // If two regions both touch the same muscle, take the max so
                // the better-trained mapping wins.
                result[muscle] = max(result[muscle] ?? 0, value)
            }
        }
        return result
    }
}
