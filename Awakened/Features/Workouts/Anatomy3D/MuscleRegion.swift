import Foundation

/// The muscle groups rendered and selectable in the 3D workout anatomy.
///
/// This is the single source of truth for the 3D body: every selectable
/// mesh in the scene is named with one of these `rawValue`s, and all colour
/// / score logic is keyed on this enum. It is intentionally decoupled from
/// the legacy `AnatomyRegion` (used by `MuscleStatsService`) so the 3D layer
/// can evolve independently — `anatomyRegion` bridges the two.
enum MuscleRegion: String, CaseIterable, Identifiable, Hashable {
    case chest
    case back
    case shoulders
    case biceps
    case triceps
    case forearms
    case abs
    case obliques
    case glutes
    case quads
    case hamstrings
    case calves

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
        case .obliques: return "Obliques"
        case .glutes: return "Glutes"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .calves: return "Calves"
        }
    }

    /// SF Symbol used in chips and the detail sheet.
    var symbol: String {
        switch self {
        case .chest, .abs, .obliques: return "figure.core.training"
        case .back: return "figure.strengthtraining.functional"
        case .shoulders, .biceps, .triceps, .forearms: return "dumbbell.fill"
        case .glutes, .quads, .hamstrings, .calves: return "figure.run"
        }
    }

    /// Whether the region reads primarily from the front of the body
    /// (used to pick a sensible default camera angle when selected).
    var isFront: Bool {
        switch self {
        case .chest, .biceps, .forearms, .abs, .obliques, .quads: return true
        case .back, .triceps, .hamstrings, .glutes, .shoulders, .calves: return false
        }
    }

    /// Bridge to the legacy coarse region that `MuscleStatsService` produces.
    /// `obliques` has no dedicated legacy region, so it reads from `abs`.
    var anatomyRegion: AnatomyRegion {
        switch self {
        case .chest: return .chest
        case .back: return .back
        case .shoulders: return .shoulders
        case .biceps: return .biceps
        case .triceps: return .triceps
        case .forearms: return .forearms
        case .abs, .obliques: return .abs
        case .glutes: return .glutes
        case .quads: return .quads
        case .hamstrings: return .hamstrings
        case .calves: return .calves
        }
    }
}
