import SwiftUI
import HealthKit

/// Hub view for cardio activities — accessible from Workouts tab and Dashboard Vitality drill-down
struct CardioView: View {
    @StateObject private var cardioService = CardioService()
    @State private var selectedActivity: CardioActivity?
    @State private var showingHistory = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Weekly chart
                    WeeklyCardioChart(stats: cardioService.weeklyStats)
                    
                    // Recent activities
                    recentActivitiesSection
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.sm)
            }
            .refreshable {
                await cardioService.loadDashboardData()
            }
            
            if cardioService.isLoading && cardioService.recentActivities.isEmpty {
                ProgressView()
                    .tint(AppColors.vitalityColor)
            }
        }
        .navigationTitle("Cardio")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CardioHistoryView()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColors.vitalityColor)
                }
            }
        }
        .task {
            await cardioService.loadDashboardData()
        }
        .navigationDestination(item: $selectedActivity) { activity in
            CardioDetailView(activity: activity)
        }
    }
    
    // MARK: - Recent Activities
    
    private var recentActivitiesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("RECENT ACTIVITIES")
                    .font(AppFonts.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                NavigationLink("See All") {
                    CardioHistoryView()
                }
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.vitalityColor)
            }
            
            if cardioService.recentActivities.isEmpty && !cardioService.isLoading {
                emptyState
            } else {
                ForEach(cardioService.recentActivities) { activity in
                    Button {
                        selectedActivity = activity
                    } label: {
                        CardioActivityRow(activity: activity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "figure.run")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No cardio activities yet")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Text("Go for a run, ride, or swim and sync with Apple Health")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Hashable conformance for navigation

extension CardioActivity: Hashable {
    static func == (lhs: CardioActivity, rhs: CardioActivity) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview("Cardio") {
    NavigationStack {
        CardioView()
    }
}
