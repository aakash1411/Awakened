import Foundation
import HealthKit

/// Maps HKWorkoutActivityType to StatType and calculates XP
struct WorkoutStatMapper {
    
    /// Maximum XP that can be earned from a single workout session
    static let maxXPPerWorkout = 500
    
    /// Determine which stat a workout contributes to
    /// - Parameter workoutType: The HealthKit workout activity type
    /// - Returns: The corresponding stat type
    static func statType(for workoutType: HKWorkoutActivityType) -> StatType {
        switch workoutType {
        // Strength
        case .traditionalStrengthTraining,
             .functionalStrengthTraining,
             .crossTraining,
             .coreTraining:
            return .strength
            
        // Agility
        case .yoga,
             .pilates,
             .flexibility,
             .dance,
             .martialArts,
             .gymnastics,
             .barre,
             .jumpRope:
            return .agility
            
        // Vitality (cardio)
        case .running,
             .cycling,
             .swimming,
             .walking,
             .hiking,
             .highIntensityIntervalTraining,
             .elliptical,
             .rowing,
             .stairClimbing,
             .kickboxing,
             .skatingSports,
             .surfingSports,
             .snowSports,
             .paddleSports,
             .soccer,
             .basketball,
             .tennis,
             .badminton,
             .tableTennis,
             .handball,
             .volleyball,
             .baseball,
             .softball,
             .rugby,
             .hockey,
             .lacrosse:
            return .vitality
            
        // Sense (mind-body)
        case .mindAndBody,
             .taiChi:
            return .sense
            
        // Default: Vitality
        default:
            return .vitality
        }
    }
    
    /// Calculate XP for a workout
    /// - Parameter workout: The HKWorkout object
    /// - Returns: Tuple of (stat type, XP earned)
    static func calculateXP(for workout: HKWorkout) -> (stat: StatType, xp: Int) {
        let stat = statType(for: workout.workoutActivityType)
        let durationMinutes = workout.duration / 60.0
        
        guard durationMinutes > 0 else { return (stat, 0) }
        
        let activeEnergy = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        let distance = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
        
        let baseXP: Double
        
        switch stat {
        case .strength:
            baseXP = strengthXP(durationMinutes: durationMinutes, activeEnergy: activeEnergy, workoutType: workout.workoutActivityType)
            
        case .agility:
            let intensity = intensityForWorkout(workout.workoutActivityType)
            baseXP = Double(XPCalculator.agilityXP(durationMinutes: durationMinutes, intensity: intensity))
            
        case .vitality:
            baseXP = Double(XPCalculator.vitalityXP(
                durationMinutes: durationMinutes,
                distanceKm: distance > 0 ? distance : nil,
                averageHeartRate: nil // HR bonus applied separately if available
            ))
            
        case .sense:
            baseXP = Double(XPCalculator.senseXP(durationMinutes: durationMinutes))
            
        case .intelligence:
            baseXP = durationMinutes * 1.0 // Rare case, fallback
        }
        
        let xp = min(max(1, Int(baseXP)), maxXPPerWorkout)
        return (stat, xp)
    }
    
    /// Calculate strength XP from workout duration and energy
    /// Formula: duration_min × 3 + activeEnergy/10
    private static func strengthXP(
        durationMinutes: Double,
        activeEnergy: Double,
        workoutType: HKWorkoutActivityType
    ) -> Double {
        let multiplier: Double
        switch workoutType {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            multiplier = 3.0
        case .crossTraining:
            multiplier = 2.5
        case .coreTraining:
            multiplier = 2.0
        default:
            multiplier = 1.5
        }
        
        return (durationMinutes * multiplier) + (activeEnergy / 10.0)
    }
    
    /// Determine intensity for agility workouts
    private static func intensityForWorkout(_ type: HKWorkoutActivityType) -> ActivityIntensity {
        switch type {
        case .martialArts, .gymnastics, .jumpRope:
            return .high
        case .yoga, .pilates, .dance, .barre:
            return .medium
        case .flexibility:
            return .low
        default:
            return .medium
        }
    }
    
    /// Get a user-friendly name for a workout type
    /// - Parameter type: The HKWorkoutActivityType
    /// - Returns: Human-readable name
    static func displayName(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .crossTraining: return "Cross Training"
        case .coreTraining: return "Core Training"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Yoga"
        case .pilates: return "Pilates"
        case .flexibility: return "Stretching"
        case .dance: return "Dance"
        case .martialArts: return "Martial Arts"
        case .gymnastics: return "Gymnastics"
        case .mindAndBody: return "Mind & Body"
        case .taiChi: return "Tai Chi"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .stairClimbing: return "Stair Climbing"
        case .barre: return "Barre"
        case .jumpRope: return "Jump Rope"
        case .kickboxing: return "Kickboxing"
        case .soccer: return "Soccer"
        case .basketball: return "Basketball"
        case .tennis: return "Tennis"
        default: return "Workout"
        }
    }
    
    /// Get the SF Symbol icon for a workout type
    /// - Parameter type: The HKWorkoutActivityType
    /// - Returns: SF Symbol name
    static func icon(for type: HKWorkoutActivityType) -> String {
        switch type {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        case .hiking: return "figure.hiking"
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining"
        case .yoga: return "figure.yoga"
        case .dance: return "figure.dance"
        case .martialArts: return "figure.martial.arts"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        case .coreTraining: return "figure.core.training"
        case .crossTraining: return "figure.cross.training"
        case .flexibility: return "figure.flexibility"
        case .pilates: return "figure.pilates"
        case .mindAndBody: return "figure.mind.and.body"
        default: return "figure.mixed.cardio"
        }
    }
}
