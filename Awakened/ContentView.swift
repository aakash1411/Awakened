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

/// Main tab view with the custom Anime bottom navigation
/// (Home · Progress · center crest · Community · Profile).
struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showQuickActions = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()
            
            // Active destination fills the screen; the bar is added as a
            // bottom safe-area inset so each screen's content isn't hidden.
            selectedScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    AnimeTabBar(selection: $appState.selectedTab) {
                        showQuickActions = true
                    }
                }
        }
        .sheet(isPresented: $showQuickActions) {
            QuickActionsSheet()
        }
    }
    
    @ViewBuilder
    private var selectedScreen: some View {
        switch appState.selectedTab {
        case .home:
            DashboardView()
        case .progress:
            ProgressDashboardView()
        case .community:
            SocialTabView()
        case .profile:
            ProfileView()
        }
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
