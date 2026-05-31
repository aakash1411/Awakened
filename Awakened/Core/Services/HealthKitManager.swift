import Foundation
import HealthKit
import CoreLocation
import Combine

/// Errors specific to HealthKit operations
enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case queryFailed(Error)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Health data is not available on this device."
        case .notAuthorized:
            return "Health data access has not been authorized."
        case .queryFailed(let error):
            return "Health query failed: \(error.localizedDescription)"
        case .noData:
            return "No health data found for the requested period."
        }
    }
}

/// Singleton service wrapping all HealthKit interactions
@MainActor
class HealthKitManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = HealthKitManager()
    
    // MARK: - Properties
    
    /// The HealthKit store
    let healthStore = HKHealthStore()
    
    /// Whether HealthKit authorization has been requested
    @Published var isAuthorized: Bool = false
    
    /// Whether HealthKit is available on this device
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Active observer queries for background updates
    private var observerQueries: [HKObserverQuery] = []
    
    /// UserDefaults key for tracking if auth was requested
    private let authRequestedKey = "healthKitAuthorizationRequested"
    
    // MARK: - Data Types
    
    /// All HealthKit types we want to read
    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Quantity types
        if let stepCount = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let cyclingDistance = HKQuantityType.quantityType(forIdentifier: .distanceCycling) {
            types.insert(cyclingDistance)
        }
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        if let bodyFat = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            types.insert(bodyFat)
        }
        
        // Category types
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        
        // Workout type
        types.insert(HKWorkoutType.workoutType())
        
        // Workout route (GPS data)
        types.insert(HKSeriesType.workoutRoute())
        
        return types
    }
    
    /// Types we want to write
    private var writeTypes: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        types.insert(HKWorkoutType.workoutType())
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        return types
    }
    
    // MARK: - Initialization
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    /// Request HealthKit authorization
    /// - Returns: Whether authorization was granted (note: HealthKit doesn't reveal per-type status)
    func requestAuthorization() async throws -> Bool {
        guard isAvailable else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        
        isAuthorized = true
        UserDefaults.standard.set(true, forKey: authRequestedKey)
        return true
    }
    
    /// Check if authorization has been previously requested
    func checkAuthorizationStatus() {
        guard isAvailable else {
            isAuthorized = false
            return
        }
        isAuthorized = UserDefaults.standard.bool(forKey: authRequestedKey)
    }
    
    /// Whether a specific type is authorized for reading
    func isTypeAuthorized(_ type: HKObjectType) -> Bool {
        let status = healthStore.authorizationStatus(for: type)
        return status == .sharingAuthorized
    }
    
    // MARK: - Steps
    
    /// Fetch total step count for a given date
    /// - Parameter date: The date to query
    /// - Returns: Total steps for that day
    func fetchSteps(for date: Date) async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.notAvailable
        }
        
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    // No data available — not a real error
                    continuation.resume(returning: 0)
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Sleep
    
    /// Fetch total sleep hours for a given date (previous night)
    /// - Parameter date: The date to query (sleep ending on this date)
    /// - Returns: Total sleep hours
    func fetchSleepHours(for date: Date) async throws -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.notAvailable
        }
        
        // Sleep typically spans the previous evening to this morning
        let calendar = Calendar.current
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
        let startOfPreviousEvening = calendar.date(byAdding: .hour, value: -12, to: calendar.startOfDay(for: date))!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfPreviousEvening, end: endOfDay, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: 0)
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                // Sum up asleep time only (not inBed)
                let totalSeconds = samples
                    .filter { sample in
                        let value = HKCategoryValueSleepAnalysis(rawValue: sample.value)
                        // Include all sleep stages (asleep, core, deep, REM) but not inBed/awake
                        return value != .inBed && value != .awake
                    }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }
                
                let hours = totalSeconds / 3600.0
                continuation.resume(returning: hours)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Workouts
    
    /// Fetch workouts within a date range
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Array of HKWorkout objects
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKWorkoutType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: [])
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                let workouts = (samples as? [HKWorkout]) ?? []
                continuation.resume(returning: workouts)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Mindful Minutes
    
    /// Fetch total mindful minutes for a given date
    /// - Parameter date: The date to query
    /// - Returns: Total mindful minutes
    func fetchMindfulMinutes(for date: Date) async throws -> Double {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.notAvailable
        }
        
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: 0)
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let totalSeconds = samples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }
                
                continuation.resume(returning: totalSeconds / 60.0)
            }
            healthStore.execute(query)
        }
    }
    
    /// Fetch total mindful minutes for a date range
    /// - Parameters:
    ///   - startDate: Start of range
    ///   - endDate: End of range
    /// - Returns: Total mindful minutes
    func fetchMindfulMinutes(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: mindfulType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: 0)
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let totalSeconds = samples.reduce(0.0) { total, sample in
                    total + sample.endDate.timeIntervalSince(sample.startDate)
                }
                
                continuation.resume(returning: totalSeconds / 60.0)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Heart Rate
    
    /// Fetch heart rate samples within a date range
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Array of HeartRateSample
    func fetchHeartRateSamples(from start: Date, to end: Date) async throws -> [HeartRateSample] {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.notAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: [])
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let quantitySamples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                let hrSamples = quantitySamples.map { sample in
                    let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let context = sample.metadata?[HKMetadataKeyHeartRateMotionContext] as? NSNumber
                    let motionContext = context.flatMap { HKHeartRateMotionContext(rawValue: $0.intValue) }
                    return HeartRateSample(date: sample.startDate, bpm: bpm, motionContext: motionContext)
                }
                
                continuation.resume(returning: hrSamples)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Active Energy
    
    /// Fetch total active energy burned for a given date
    /// - Parameter date: The date to query
    /// - Returns: Active energy in kilocalories
    func fetchActiveEnergy(for date: Date) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.notAvailable
        }
        
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: 0)
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                let kcal = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: kcal)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Distance
    
    /// Fetch total walking/running distance for a given date
    /// - Parameter date: The date to query
    /// - Returns: Distance in kilometers
    func fetchDistance(for date: Date) async throws -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.notAvailable
        }
        
        let (start, end) = dayBounds(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: 0)
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                let km = result?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                continuation.resume(returning: km)
            }
            healthStore.execute(query)
        }
    }
    
    // MARK: - Workout Routes
    
    /// Fetch GPS route locations for a workout
    /// - Parameter workout: The HKWorkout to fetch route data for
    /// - Returns: Array of CLLocation points along the route
    func fetchWorkoutRoute(for workout: HKWorkout) async throws -> [CLLocation] {
        // First, fetch the HKWorkoutRoute objects associated with this workout
        let routeType = HKSeriesType.workoutRoute()
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        let routes: [HKWorkoutRoute] = try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: routeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                let routes = (samples as? [HKWorkoutRoute]) ?? []
                continuation.resume(returning: routes)
            }
            healthStore.execute(query)
        }
        
        guard let route = routes.first else { return [] }
        
        // Extract CLLocation points from the route
        return try await withCheckedThrowingContinuation { continuation in
            var allLocations: [CLLocation] = []
            
            let routeQuery = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                if let locations = locations {
                    allLocations.append(contentsOf: locations)
                }
                
                if done {
                    continuation.resume(returning: allLocations)
                }
            }
            healthStore.execute(routeQuery)
        }
    }
    
    // MARK: - Body Metrics
    
    /// Fetch most recent body mass
    /// - Returns: Weight in kilograms, or nil if no data
    func fetchBodyMass() async throws -> Double? {
        guard let massType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.notAvailable
        }
        
        return try await fetchMostRecentQuantity(type: massType, unit: .gramUnit(with: .kilo))
    }
    
    /// Fetch most recent body fat percentage
    /// - Returns: Body fat as fraction (0-1), or nil if no data
    func fetchBodyFatPercentage() async throws -> Double? {
        guard let fatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            throw HealthKitError.notAvailable
        }
        
        return try await fetchMostRecentQuantity(type: fatType, unit: .percent())
    }
    
    // MARK: - Background Delivery
    
    /// Enable background delivery for key data types
    func enableBackgroundDelivery() async throws {
        guard isAvailable else { return }
        
        var typesAndFrequencies: [(HKObjectType, HKUpdateFrequency)] = [
            (HKWorkoutType.workoutType(), .immediate)
        ]
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { typesAndFrequencies.append((steps, .hourly)) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { typesAndFrequencies.append((sleep, .hourly)) }
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) { typesAndFrequencies.append((mindful, .immediate)) }
        
        for (type, frequency) in typesAndFrequencies {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                healthStore.enableBackgroundDelivery(for: type, frequency: frequency) { success, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }
    
    /// Start observer queries that fire when new data appears
    /// - Parameter handler: Called when any observed data type has new samples
    func startObservingChanges(handler: @escaping () -> Void) {
        stopObservingChanges()
        
        var typesToObserve: [HKSampleType] = [HKWorkoutType.workoutType()]
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) { typesToObserve.append(steps) }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) { typesToObserve.append(sleep) }
        if let mindful = HKCategoryType.categoryType(forIdentifier: .mindfulSession) { typesToObserve.append(mindful) }
        
        for type in typesToObserve {
            let query = HKObserverQuery(sampleType: type, predicate: nil) { _, completionHandler, error in
                if error == nil {
                    handler()
                }
                completionHandler()
            }
            
            healthStore.execute(query)
            observerQueries.append(query)
        }
    }
    
    /// Stop all observer queries
    func stopObservingChanges() {
        for query in observerQueries {
            healthStore.stop(query)
        }
        observerQueries.removeAll()
    }
    
    // MARK: - Private Helpers
    
    /// Get start and end of day for a given date
    private func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
    
    /// Fetch the most recent quantity sample of a given type
    private func fetchMostRecentQuantity(type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                if let error = error as? NSError, error.domain == "com.apple.healthkit", error.code == 11 {
                    continuation.resume(returning: nil)
                    return
                }
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}
