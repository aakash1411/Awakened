import UIKit
import BackgroundTasks

/// Handles background task registration and execution
class AppDelegate: NSObject, UIApplicationDelegate {
    
    /// Background task identifier for health sync
    static let healthSyncTaskId = "com.awakened.healthsync"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register background health sync task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.healthSyncTaskId,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleHealthSync(task: refreshTask)
        }
        
        return true
    }
    
    /// Schedule the next background health sync
    func scheduleHealthSync() {
        let request = BGAppRefreshTaskRequest(identifier: Self.healthSyncTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 min minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule health sync: \(error)")
        }
    }
    
    /// Handle the background health sync task
    private func handleHealthSync(task: BGAppRefreshTask) {
        // Schedule the next sync
        scheduleHealthSync()
        
        // Create a task to perform the sync
        let syncTask = Task {
            await performBackgroundSync()
        }
        
        // Handle expiration
        task.expirationHandler = {
            syncTask.cancel()
        }
        
        // Complete when done
        Task {
            _ = await syncTask.result
            task.setTaskCompleted(success: true)
        }
    }
    
    /// Perform the actual background sync
    @MainActor
    private func performBackgroundSync() async {
        // The actual sync is triggered via HealthKitManager's observer queries
        // This background task just ensures the app gets wake-up time
        // The HealthSyncEngine.syncAll() will be called by the observer handler
        print("Background health sync triggered")
    }
}
