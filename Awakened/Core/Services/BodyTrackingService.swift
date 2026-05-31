import Foundation
import SwiftData
import Combine

/// Manages body measurements with HealthKit sync for weight and body fat
@MainActor
class BodyTrackingService: ObservableObject {
    
    private let modelContext: ModelContext
    private let healthKit = HealthKitManager.shared
    
    @Published var recentMeasurements: [BodyMeasurement] = []
    @Published var latestByType: [BodyMeasurementType: BodyMeasurement] = [:]
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch
    
    /// Fetch recent measurements
    func fetchRecentMeasurements(limit: Int = 30) {
        var descriptor = FetchDescriptor<BodyMeasurement>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            recentMeasurements = try modelContext.fetch(descriptor)
            updateLatestByType()
        } catch {
            print("BodyTrackingService: Failed to fetch — \(error)")
        }
    }
    
    /// Fetch measurements for a specific type
    func measurements(for type: BodyMeasurementType, limit: Int = 30) -> [BodyMeasurement] {
        let typeRaw = type.rawValue
        var descriptor = FetchDescriptor<BodyMeasurement>(
            predicate: #Predicate { $0.typeRaw == typeRaw },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    /// Update latest measurement per type
    private func updateLatestByType() {
        var latest: [BodyMeasurementType: BodyMeasurement] = [:]
        for measurement in recentMeasurements {
            let type = measurement.measurementType
            if latest[type] == nil {
                latest[type] = measurement
            }
        }
        latestByType = latest
    }
    
    // MARK: - Add
    
    /// Log a manual body measurement
    @discardableResult
    func addMeasurement(
        type: BodyMeasurementType,
        value: Double,
        notes: String? = nil,
        player: Player
    ) -> BodyMeasurement {
        let measurement = BodyMeasurement(
            type: type,
            value: value,
            notes: notes
        )
        measurement.player = player
        modelContext.insert(measurement)
        
        do {
            try modelContext.save()
        } catch {
            print("BodyTrackingService: Failed to save — \(error)")
        }
        
        recentMeasurements.insert(measurement, at: 0)
        updateLatestByType()
        return measurement
    }
    
    /// Delete a measurement
    func deleteMeasurement(_ measurement: BodyMeasurement) {
        modelContext.delete(measurement)
        recentMeasurements.removeAll { $0.id == measurement.id }
        updateLatestByType()
        
        do {
            try modelContext.save()
        } catch {
            print("BodyTrackingService: Failed to delete — \(error)")
        }
    }
    
    // MARK: - HealthKit Sync
    
    /// Sync weight and body fat from HealthKit
    func syncFromHealthKit(player: Player) async {
        // Weight
        if let weight = try? await healthKit.fetchBodyMass() {
            let existing = measurements(for: .weight, limit: 1).first
            let isNew = existing.map { !Calendar.current.isDateInToday($0.date) } ?? true
            
            if isNew {
                let m = BodyMeasurement(type: .weight, value: weight, isFromHealthKit: true)
                m.player = player
                modelContext.insert(m)
            }
        }
        
        // Body fat
        if let bodyFat = try? await healthKit.fetchBodyFatPercentage() {
            let existing = measurements(for: .bodyFat, limit: 1).first
            let isNew = existing.map { !Calendar.current.isDateInToday($0.date) } ?? true
            
            if isNew {
                let m = BodyMeasurement(type: .bodyFat, value: bodyFat * 100, isFromHealthKit: true)
                m.player = player
                modelContext.insert(m)
            }
        }
        
        do {
            try modelContext.save()
            fetchRecentMeasurements()
        } catch {
            print("BodyTrackingService: HK sync save failed — \(error)")
        }
    }
    
    // MARK: - Trends
    
    /// Get data points for a chart (value, date) for a measurement type
    func trendData(for type: BodyMeasurementType, days: Int = 30) -> [(value: Double, date: Date)] {
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let typeRaw = type.rawValue
        
        let descriptor = FetchDescriptor<BodyMeasurement>(
            predicate: #Predicate { $0.typeRaw == typeRaw && $0.date >= since },
            sortBy: [SortDescriptor(\.date)]
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.map { (value: $0.value, date: $0.date) }
        } catch {
            return []
        }
    }
}
