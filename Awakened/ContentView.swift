import SwiftUI
import SwiftData

/// Root content view that handles navigation between onboarding and main app
struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .onAppear {
            appState.loadPlayer(from: modelContext)
        }
        .overlay {
            // Level up animation overlay
            if appState.showLevelUpAnimation, let info = appState.levelUpInfo {
                LevelUpOverlay(info: info) {
                    appState.dismissLevelUp()
                }
                .transition(.opacity)
            }
        }
        .overlay(alignment: .top) {
            // System notifications
            NotificationStack(notifications: appState.pendingNotifications) { notification in
                appState.dismissNotification(notification)
            }
        }
    }
}

/// Main tab view with bottom navigation
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label(AppTab.status.title, systemImage: AppTab.status.icon)
                }
                .tag(AppTab.status)
            
            NavigationStack {
                NutritionView()
            }
                .tabItem {
                    Label(AppTab.nutrition.title, systemImage: AppTab.nutrition.icon)
                }
                .tag(AppTab.nutrition)
            
            NavigationStack {
                WorkoutsView()
            }
                .tabItem {
                    Label(AppTab.workouts.title, systemImage: AppTab.workouts.icon)
                }
                .tag(AppTab.workouts)
            
            SocialTabView()
                .tabItem {
                    Label(AppTab.social.title, systemImage: AppTab.social.icon)
                }
                .tag(AppTab.social)
            
            ProfileView()
                .tabItem {
                    Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
                }
                .tag(AppTab.profile)
        }
        .tint(AppColors.primaryBlue)
    }
}

#Preview("Content View - Onboarding") {
    let appState = AppState()
    appState.isOnboardingComplete = false
    
    return ContentView()
        .environmentObject(appState)
        .modelContainer(for: [Player.self, Stat.self, Quest.self, SyncRecord.self, Exercise.self, WorkoutSession.self, WorkoutSet.self, WorkoutTemplate.self, PersonalRecord.self, ReadingEntry.self, LearningSession.self, Achievement.self, FoodItem.self, MealEntry.self, BodyMeasurement.self], inMemory: true)
}

#Preview("Content View - Main") {
    let appState = AppState()
    appState.isOnboardingComplete = true
    
    return ContentView()
        .environmentObject(appState)
        .modelContainer(for: [Player.self, Stat.self, Quest.self, SyncRecord.self, Exercise.self, WorkoutSession.self, WorkoutSet.self, WorkoutTemplate.self, PersonalRecord.self, ReadingEntry.self, LearningSession.self, Achievement.self, FoodItem.self, MealEntry.self, BodyMeasurement.self], inMemory: true)
}
