import Foundation
import SwiftData
import SwiftUI

// MARK: - Supporting Enums

/// Muscle groups matching free-exercise-db primaryMuscles values
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case abdominals
    case abductors
    case adductors
    case biceps
    case calves
    case chest
    case forearms
    case glutes
    case hamstrings
    case lats
    case lowerBack = "lower back"
    case middleBack = "middle back"
    case neck
    case quadriceps
    case shoulders
    case traps
    case triceps
    case fullBody
    case cardio
    
    var id: String { rawValue }
    
    /// Display-friendly name
    var displayName: String {
        switch self {
        case .abdominals: return "Abdominals"
        case .abductors: return "Abductors"
        case .adductors: return "Adductors"
        case .biceps: return "Biceps"
        case .calves: return "Calves"
        case .chest: return "Chest"
        case .forearms: return "Forearms"
        case .glutes: return "Glutes"
        case .hamstrings: return "Hamstrings"
        case .lats: return "Lats"
        case .lowerBack: return "Lower Back"
        case .middleBack: return "Middle Back"
        case .neck: return "Neck"
        case .quadriceps: return "Quadriceps"
        case .shoulders: return "Shoulders"
        case .traps: return "Traps"
        case .triceps: return "Triceps"
        case .fullBody: return "Full Body"
        case .cardio: return "Cardio"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .lats, .middleBack, .lowerBack: return "figure.rowing"
        case .shoulders, .traps: return "figure.arms.open"
        case .biceps, .forearms: return "figure.mixed.cardio"
        case .triceps: return "figure.cooldown"
        case .quadriceps, .hamstrings, .glutes, .calves: return "figure.walk"
        case .abdominals: return "figure.core.training"
        case .abductors, .adductors: return "figure.flexibility"
        case .neck: return "person.fill"
        case .fullBody: return "figure.cross.training"
        case .cardio: return "heart.fill"
        }
    }
    
    /// Associated color for display
    var color: Color {
        switch self {
        case .chest, .triceps, .shoulders: return AppColors.strengthColor
        case .lats, .middleBack, .lowerBack, .biceps, .traps: return AppColors.primaryBlue
        case .quadriceps, .hamstrings, .glutes, .calves: return AppColors.agilityColor
        case .abdominals, .forearms: return AppColors.vitalityColor
        case .abductors, .adductors, .neck: return AppColors.senseColor
        case .fullBody: return AppColors.accentPurple
        case .cardio: return AppColors.strengthColor
        }
    }
    
    /// Broad grouping for filter UI
    var bodyRegion: String {
        switch self {
        case .chest, .shoulders, .triceps, .traps: return "Push"
        case .lats, .middleBack, .lowerBack, .biceps, .forearms: return "Pull"
        case .quadriceps, .hamstrings, .glutes, .calves, .abductors, .adductors: return "Legs"
        case .abdominals, .neck: return "Core"
        case .fullBody, .cardio: return "Other"
        }
    }
    
    /// Initialize from free-exercise-db string
    init(fromDatabase value: String) {
        self = MuscleGroup(rawValue: value.lowercased()) ?? .fullBody
    }
}

/// Workaround: need a non-rawValue back reference
extension MuscleGroup {
    static let back: MuscleGroup = .lats
}

/// Equipment types matching free-exercise-db
enum EquipmentType: String, Codable, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case cable
    case machine
    case bodyOnly = "body only"
    case kettlebells
    case bands
    case ezCurlBar = "e-z curl bar"
    case medicineBall = "medicine ball"
    case exerciseBall = "exercise ball"
    case foamRoll = "foam roll"
    case other
    
    var id: String { rawValue }
    
    /// Display-friendly name
    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .cable: return "Cable"
        case .machine: return "Machine"
        case .bodyOnly: return "Bodyweight"
        case .kettlebells: return "Kettlebell"
        case .bands: return "Bands"
        case .ezCurlBar: return "EZ Curl Bar"
        case .medicineBall: return "Medicine Ball"
        case .exerciseBall: return "Exercise Ball"
        case .foamRoll: return "Foam Roll"
        case .other: return "Other"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .barbell: return "figure.strengthtraining.traditional"
        case .dumbbell: return "dumbbell.fill"
        case .cable: return "line.diagonal"
        case .machine: return "gearshape.fill"
        case .bodyOnly: return "figure.stand"
        case .kettlebells: return "scalemass.fill"
        case .bands: return "circle.dotted"
        case .ezCurlBar: return "figure.strengthtraining.functional"
        case .medicineBall: return "circle.fill"
        case .exerciseBall: return "circle.fill"
        case .foamRoll: return "capsule.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    /// Initialize from free-exercise-db string
    init(fromDatabase value: String?) {
        guard let value = value else { self = .other; return }
        self = EquipmentType(rawValue: value.lowercased()) ?? .other
    }
}

/// Exercise mechanic type
enum ExerciseMechanic: String, Codable {
    case compound
    case isolation
    case cardio
    
    var displayName: String { rawValue.capitalized }
    
    init(fromDatabase value: String?) {
        guard let value = value else { self = .compound; return }
        self = ExerciseMechanic(rawValue: value.lowercased()) ?? .compound
    }
}

/// Exercise force type
enum ExerciseForce: String, Codable {
    case push
    case pull
    case isometric = "static"
    
    var displayName: String { rawValue.capitalized }
    
    init(fromDatabase value: String?) {
        guard let value = value else { self = .push; return }
        self = ExerciseForce(rawValue: value.lowercased()) ?? .push
    }
}

/// Exercise difficulty level
enum ExerciseLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case expert
    
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    
    /// Default rest seconds for this level
    var defaultRestSeconds: Int {
        switch self {
        case .beginner: return 90
        case .intermediate: return 75
        case .expert: return 60
        }
    }
}

// MARK: - Exercise Model

/// Represents a single exercise in the database
@Model
final class Exercise {
    
    /// Unique identifier
    var id: UUID
    
    /// External ID from free-exercise-db (e.g., "Barbell_Bench_Press")
    var externalId: String
    
    /// Display name
    var name: String
    
    /// Primary muscle group (raw value)
    var muscleGroupRaw: String
    
    /// Secondary muscles (comma-separated raw values)
    var secondaryMusclesRaw: String
    
    /// Equipment required (raw value)
    var equipmentRaw: String
    
    /// Mechanic type: compound/isolation (raw value)
    var mechanicRaw: String
    
    /// Force type: push/pull/static (raw value)
    var forceRaw: String
    
    /// Difficulty level (raw value)
    var levelRaw: String
    
    /// Exercise instructions (joined with newlines)
    var instructions: String
    
    /// Image paths from free-exercise-db (comma-separated)
    var imagePaths: String
    
    /// Whether this is a user-created exercise
    var isCustom: Bool
    
    /// Exercise category from the database (e.g. "strength", "stretching", "plyometrics")
    var dbCategory: String
    
    // MARK: - Computed Properties
    
    /// Primary muscle group
    var muscleGroup: MuscleGroup {
        get { MuscleGroup(fromDatabase: muscleGroupRaw) }
        set { muscleGroupRaw = newValue.rawValue }
    }
    
    /// Secondary muscles as array
    var secondaryMuscles: [MuscleGroup] {
        guard !secondaryMusclesRaw.isEmpty else { return [] }
        return secondaryMusclesRaw
            .split(separator: ",")
            .map { MuscleGroup(fromDatabase: String($0).trimmingCharacters(in: .whitespaces)) }
    }
    
    /// Equipment type
    var equipment: EquipmentType {
        get { EquipmentType(fromDatabase: equipmentRaw) }
        set { equipmentRaw = newValue.rawValue }
    }
    
    /// Mechanic (compound/isolation)
    var mechanic: ExerciseMechanic {
        get { ExerciseMechanic(fromDatabase: mechanicRaw) }
        set { mechanicRaw = newValue.rawValue }
    }
    
    /// Force direction
    var force: ExerciseForce {
        get { ExerciseForce(fromDatabase: forceRaw) }
        set { forceRaw = newValue.rawValue }
    }
    
    /// Difficulty level
    var level: ExerciseLevel {
        get { ExerciseLevel(rawValue: levelRaw) ?? .beginner }
        set { levelRaw = newValue.rawValue }
    }
    
    /// Default rest time in seconds (based on mechanic)
    var defaultRestSeconds: Int {
        mechanic == .compound ? 90 : 60
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        externalId: String,
        name: String,
        muscleGroupRaw: String,
        secondaryMusclesRaw: String = "",
        equipmentRaw: String = "body only",
        mechanicRaw: String = "compound",
        forceRaw: String = "push",
        levelRaw: String = "beginner",
        instructions: String = "",
        imagePaths: String = "",
        isCustom: Bool = false,
        dbCategory: String = "strength"
    ) {
        self.id = id
        self.externalId = externalId
        self.name = name
        self.muscleGroupRaw = muscleGroupRaw
        self.secondaryMusclesRaw = secondaryMusclesRaw
        self.equipmentRaw = equipmentRaw
        self.mechanicRaw = mechanicRaw
        self.forceRaw = forceRaw
        self.levelRaw = levelRaw
        self.instructions = instructions
        self.imagePaths = imagePaths
        self.isCustom = isCustom
        self.dbCategory = dbCategory
    }
}
