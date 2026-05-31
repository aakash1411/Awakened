import Foundation
import HealthKit
import SwiftUI

/// Lightweight struct for passing heart rate data through the sync pipeline
/// Not persisted — used only during sync processing
struct HeartRateSample: Identifiable {
    let id: UUID
    let date: Date
    let bpm: Double
    let motionContext: HKHeartRateMotionContext?
    
    init(date: Date, bpm: Double, motionContext: HKHeartRateMotionContext? = nil) {
        self.id = UUID()
        self.date = date
        self.bpm = bpm
        self.motionContext = motionContext
    }
    
    /// Heart rate zone based on BPM
    var zone: HeartRateZone {
        HeartRateZone.from(bpm: bpm)
    }
    
    /// Whether this is a resting heart rate sample
    var isResting: Bool {
        motionContext == .sedentary
    }
}

/// Heart rate training zones
enum HeartRateZone: String, CaseIterable, Identifiable {
    case rest       // < 50% max HR
    case warmUp     // 50-59% max HR
    case fatBurn    // 60-69% max HR
    case cardio     // 70-79% max HR
    case hard       // 80-89% max HR
    case peak       // 90%+ max HR
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .rest: return "Rest"
        case .warmUp: return "Warm Up"
        case .fatBurn: return "Fat Burn"
        case .cardio: return "Cardio"
        case .hard: return "Hard"
        case .peak: return "Peak"
        }
    }
    
    /// Zone color for charts and map overlays
    var color: Color {
        switch self {
        case .rest: return Color(hex: "90CAF9")    // Light blue
        case .warmUp: return Color(hex: "69F0AE")  // Green
        case .fatBurn: return Color(hex: "FFD54F")  // Yellow
        case .cardio: return Color(hex: "FFB74D")   // Orange
        case .hard: return Color(hex: "FF8A65")     // Deep orange
        case .peak: return Color(hex: "EF5350")     // Red
        }
    }
    
    /// Zone number (1-6) for display
    var zoneNumber: Int {
        switch self {
        case .rest: return 1
        case .warmUp: return 2
        case .fatBurn: return 3
        case .cardio: return 4
        case .hard: return 5
        case .peak: return 6
        }
    }
    
    /// XP multiplier for this zone
    var xpMultiplier: Double {
        switch self {
        case .rest: return 0.8
        case .warmUp: return 1.0
        case .fatBurn: return 1.1
        case .cardio: return 1.2
        case .hard: return 1.3
        case .peak: return 1.4
        }
    }
    
    /// Determine zone from BPM using fixed thresholds (fallback)
    /// - Parameter bpm: Heart rate in beats per minute
    /// - Returns: The corresponding heart rate zone
    static func from(bpm: Double) -> HeartRateZone {
        switch bpm {
        case ..<100: return .rest
        case 100..<120: return .warmUp
        case 120..<140: return .fatBurn
        case 140..<160: return .cardio
        case 160..<180: return .hard
        default: return .peak
        }
    }
    
    /// Determine zone from BPM using age-based max HR (Karvonen formula: 220 - age)
    /// - Parameters:
    ///   - bpm: Heart rate in beats per minute
    ///   - age: User's age in years
    /// - Returns: The corresponding heart rate zone
    static func from(bpm: Double, age: Int) -> HeartRateZone {
        let maxHR = Double(220 - age)
        let percent = bpm / maxHR
        switch percent {
        case ..<0.50: return .rest
        case 0.50..<0.60: return .warmUp
        case 0.60..<0.70: return .fatBurn
        case 0.70..<0.80: return .cardio
        case 0.80..<0.90: return .hard
        default: return .peak
        }
    }
    
    /// Get BPM range for this zone based on age
    /// - Parameter age: User's age in years
    /// - Returns: ClosedRange of BPM values
    func bpmRange(forAge age: Int) -> ClosedRange<Int> {
        let maxHR = 220 - age
        switch self {
        case .rest: return 0...Int(Double(maxHR) * 0.50)
        case .warmUp: return Int(Double(maxHR) * 0.50)...Int(Double(maxHR) * 0.60)
        case .fatBurn: return Int(Double(maxHR) * 0.60)...Int(Double(maxHR) * 0.70)
        case .cardio: return Int(Double(maxHR) * 0.70)...Int(Double(maxHR) * 0.80)
        case .hard: return Int(Double(maxHR) * 0.80)...Int(Double(maxHR) * 0.90)
        case .peak: return Int(Double(maxHR) * 0.90)...maxHR
        }
    }
}
