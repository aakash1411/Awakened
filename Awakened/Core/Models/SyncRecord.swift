import Foundation
import SwiftData

/// Tracks processed HealthKit samples to prevent double XP crediting
/// Each record represents a single HealthKit sample that has been processed
@Model
final class SyncRecord {
    
    // MARK: - Stored Properties
    
    /// Unique identifier
    var id: UUID
    
    /// The HealthKit sample UUID (HKSample.uuid.uuidString)
    var healthKitUUID: String
    
    /// Type of data source ("workout", "sleep", "mindfulSession", "steps")
    var sourceType: String
    
    /// Amount of XP credited from this sample
    var xpCredited: Int
    
    /// Which stat received the XP
    var statTypeRaw: String
    
    /// When this record was processed
    var processedAt: Date
    
    /// The original date of the HealthKit sample
    var sampleDate: Date
    
    // MARK: - Computed Properties
    
    /// The stat type enum
    var statType: StatType {
        get { StatType(rawValue: statTypeRaw) ?? .vitality }
        set { statTypeRaw = newValue.rawValue }
    }
    
    // MARK: - Initialization
    
    /// Create a new sync record
    /// - Parameters:
    ///   - healthKitUUID: The UUID string of the HealthKit sample
    ///   - sourceType: Type of health data ("workout", "sleep", etc.)
    ///   - xpCredited: Amount of XP that was credited
    ///   - statType: Which stat received the XP
    ///   - sampleDate: Original date of the health sample
    init(
        healthKitUUID: String,
        sourceType: String,
        xpCredited: Int,
        statType: StatType,
        sampleDate: Date
    ) {
        self.id = UUID()
        self.healthKitUUID = healthKitUUID
        self.sourceType = sourceType
        self.xpCredited = xpCredited
        self.statTypeRaw = statType.rawValue
        self.processedAt = Date()
        self.sampleDate = sampleDate
    }
    
    // MARK: - Static Helpers
    
    /// Check if a HealthKit UUID has already been processed
    /// - Parameters:
    ///   - uuid: The HealthKit sample UUID string
    ///   - context: SwiftData model context
    /// - Returns: True if already processed
    static func isProcessed(_ uuid: String, in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<SyncRecord>(
            predicate: #Predicate { $0.healthKitUUID == uuid }
        )
        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            return false
        }
    }
    
    /// Fetch all sync records for a given date
    /// - Parameters:
    ///   - date: The date to query
    ///   - context: SwiftData model context
    /// - Returns: Array of sync records
    static func records(for date: Date, in context: ModelContext) -> [SyncRecord] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<SyncRecord>(
            predicate: #Predicate {
                $0.sampleDate >= startOfDay && $0.sampleDate < endOfDay
            },
            sortBy: [SortDescriptor(\.processedAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    /// Clean up old sync records (older than 90 days) to save space
    /// - Parameter context: SwiftData model context
    static func cleanupOldRecords(in context: ModelContext) {
        guard let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) else { return }
        
        let descriptor = FetchDescriptor<SyncRecord>(
            predicate: #Predicate { $0.processedAt < cutoffDate }
        )
        
        do {
            let oldRecords = try context.fetch(descriptor)
            for record in oldRecords {
                context.delete(record)
            }
        } catch {
            print("Failed to cleanup old sync records: \(error)")
        }
    }
}
