import SwiftUI
import SwiftData

@main
struct AwakenedApp: App {
    
    /// Background task delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// SwiftData model container
    let modelContainer: ModelContainer
    
    /// Global app state
    @StateObject private var appState = AppState()
    
    /// Scene phase for triggering syncs
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Configure SwiftData schema
        do {
            let schema = Schema([
                Player.self,
                Stat.self,
                Quest.self,
                SyncRecord.self,
                Exercise.self,
                WorkoutSession.self,
                WorkoutSet.self,
                WorkoutTemplate.self,
                PersonalRecord.self,
                ReadingEntry.self,
                LearningSession.self,
                Achievement.self,
                FoodItem.self,
                MealEntry.self,
                BodyMeasurement.self
            ])
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic  // Enable CloudKit sync
            )
            
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            // Fallback: try in-memory store so the app doesn't crash
            print("⚠️ Failed to create persistent ModelContainer: \(error). Falling back to in-memory store.")
            do {
                let fallbackConfig = ModelConfiguration(schema: Schema([
                    Player.self, Stat.self, Quest.self, SyncRecord.self,
                    Exercise.self, WorkoutSession.self, WorkoutSet.self,
                    WorkoutTemplate.self, PersonalRecord.self,
                    ReadingEntry.self, LearningSession.self, Achievement.self,
                    FoodItem.self, MealEntry.self, BodyMeasurement.self
                ]), isStoredInMemoryOnly: true)
                modelContainer = try ModelContainer(for: Schema([
                    Player.self, Stat.self, Quest.self, SyncRecord.self,
                    Exercise.self, WorkoutSession.self, WorkoutSet.self,
                    WorkoutTemplate.self, PersonalRecord.self,
                    ReadingEntry.self, LearningSession.self, Achievement.self,
                    FoodItem.self, MealEntry.self, BodyMeasurement.self
                ]), configurations: [fallbackConfig])
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
        
        // Configure app appearance
        configureAppearance()
    }
    
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.current.isDark ? .dark : .light)
                .tint(AppColors.primaryBlue)
                .id(themeManager.current.id) // force full re-render on theme change
                .onAppear {
                    setupHealthSync()
                    seedExerciseDatabaseIfNeeded()
                }
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await appState.healthSyncEngine?.syncAll()
                }
                appDelegate.scheduleHealthSync()
            }
        }
    }
    
    /// Configure global app appearance
    private func configureAppearance() {
        // Tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppColors.surface)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(AppColors.background)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
    
    /// Set up HealthKit sync engine and background observer queries
    @MainActor
    private func setupHealthSync() {
        let context = modelContainer.mainContext
        let syncEngine = HealthSyncEngine(modelContext: context)
        appState.healthSyncEngine = syncEngine
        
        // Start observer queries if authorized and HealthKit is available
        guard HealthKitManager.shared.isAvailable else { return }
        if HealthKitManager.shared.isAuthorized {
            HealthKitManager.shared.startObservingChanges {
                Task { @MainActor in
                    await syncEngine.syncAll()
                }
            }
            
            Task {
                try? await HealthKitManager.shared.enableBackgroundDelivery()
                await syncEngine.syncAll()
            }
        }
    }
    
    /// Seed exercise database on first launch
    private func seedExerciseDatabaseIfNeeded() {
        let context = modelContainer.mainContext
        Task {
            await ExerciseDatabase.seedIfNeeded(context: context)
        }
    }
}
