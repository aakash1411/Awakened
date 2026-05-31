import Foundation
import SwiftData

// MARK: - Measurement Type

/// Types of body measurements
enum BodyMeasurementType: String, Codable, CaseIterable, Identifiable {
    case weight
    case bodyFat
    case chest
    case waist
    case hips
    case arms
    case thighs
    case neck
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .weight: return "Weight"
        case .bodyFat: return "Body Fat"
        case .chest: return "Chest"
        case .waist: return "Waist"
        case .hips: return "Hips"
        case .arms: return "Arms"
        case .thighs: return "Thighs"
        case .neck: return "Neck"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .bodyFat: return "percent"
        case .chest: return "figure.stand"
        case .waist: return "figure.stand"
        case .hips: return "figure.stand"
        case .arms: return "figure.arms.open"
        case .thighs: return "figure.walk"
        case .neck: return "figure.stand"
        }
    }
    
    /// Unit string
    var unit: String {
        switch self {
        case .weight: return "kg"
        case .bodyFat: return "%"
        default: return "cm"
        }
    }
    
    /// Whether this measurement syncs from HealthKit
    var syncsFromHealthKit: Bool {
        switch self {
        case .weight, .bodyFat: return true
        default: return false
        }
    }
}

// MARK: - Body Measurement

/// A single body measurement entry
@Model
final class BodyMeasurement {
    
    /// Unique identifier
    var id: UUID
    
    /// Measurement type stored as raw string
    var typeRaw: String
    
    /// The measured value
    var value: Double
    
    /// Date of the measurement
    var date: Date
    
    /// Optional notes
    var notes: String?
    
    /// Whether this came from HealthKit
    var isFromHealthKit: Bool
    
    /// Reference to the owning player
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Measurement type enum
    var measurementType: BodyMeasurementType {
        get { BodyMeasurementType(rawValue: typeRaw) ?? .weight }
        set { typeRaw = newValue.rawValue }
    }
    
    /// Formatted value with unit
    var formattedValue: String {
        let type = measurementType
        if type == .bodyFat {
            return String(format: "%.1f%%", value)
        } else if type == .weight {
            return String(format: "%.1f %@", value, type.unit)
        }
        return String(format: "%.1f %@", value, type.unit)
    }
    
    /// Formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    init(
        type: BodyMeasurementType,
        value: Double,
        date: Date = Date(),
        notes: String? = nil,
        isFromHealthKit: Bool = false
    ) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.value = value
        self.date = date
        self.notes = notes
        self.isFromHealthKit = isFromHealthKit
    }
}
