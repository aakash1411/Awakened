import SwiftUI
import HealthKit

/// Chronological list of all cardio activities with type filtering
struct CardioHistoryView: View {
    @StateObject private var cardioService = CardioService()
    @State private var activities: [CardioActivity] = []
    @State private var selectedFilter: CardioFilter = .all
    @State private var selectedActivity: CardioActivity?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter chips
                filterBar
                
                // Activity list
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(AppColors.vitalityColor)
                    Spacer()
                } else if filteredActivities.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    activityList
                }
            }
        }
        .navigationTitle("Cardio History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHistory()
        }
        .navigationDestination(item: $selectedActivity) { activity in
            CardioDetailView(activity: activity)
        }
    }
    
    // MARK: - Filtered Activities
    
    private var filteredActivities: [CardioActivity] {
        guard selectedFilter != .all else { return activities }
        return activities.filter { selectedFilter.matches($0.activityType) }
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(CardioFilter.allCases) { filter in
                    CardioFilterChip(
                        title: filter.displayName,
                        icon: filter.icon,
                        isActive: selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.sm)
        }
    }
    
    // MARK: - Activity List
    
    private var activityList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.sm) {
                ForEach(groupedByDate, id: \.date) { group in
                    Section {
                        ForEach(group.activities) { activity in
                            Button {
                                selectedActivity = activity
                            } label: {
                                CardioActivityRow(activity: activity)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(group.dateLabel)
                            .font(AppFonts.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, AppSpacing.sm)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.bottom, AppSpacing.xl)
        }
    }
    
    // MARK: - Grouped by Date
    
    private struct DateGroup {
        let date: String
        let dateLabel: String
        let activities: [CardioActivity]
    }
    
    private var groupedByDate: [DateGroup] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, MMM d"
        
        let grouped = Dictionary(grouping: filteredActivities) { activity in
            formatter.string(from: activity.date)
        }
        
        return grouped
            .sorted { $0.key > $1.key }
            .map { key, value in
                let displayDate: String
                if let date = formatter.date(from: key) {
                    let calendar = Calendar.current
                    if calendar.isDateInToday(date) {
                        displayDate = "Today"
                    } else if calendar.isDateInYesterday(date) {
                        displayDate = "Yesterday"
                    } else {
                        displayDate = displayFormatter.string(from: date)
                    }
                } else {
                    displayDate = key
                }
                return DateGroup(date: key, dateLabel: displayDate, activities: value)
            }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: selectedFilter.icon)
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            
            Text("No \(selectedFilter.displayName.lowercased()) activities found")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadHistory() async {
        isLoading = true
        defer { isLoading = false }
        
        let now = Date()
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
        activities = (try? await cardioService.fetchCardioHistory(from: sixMonthsAgo, to: now)) ?? []
    }
}

// MARK: - Cardio Filter

enum CardioFilter: String, CaseIterable, Identifiable {
    case all
    case running
    case cycling
    case swimming
    case walking
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "figure.mixed.cardio"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .walking: return "figure.walk"
        }
    }
    
    /// Check if a workout type matches this filter
    func matches(_ type: HKWorkoutActivityType) -> Bool {
        switch self {
        case .all: return true
        case .running: return type == .running
        case .cycling: return type == .cycling
        case .swimming: return type == .swimming
        case .walking: return type == .walking || type == .hiking
        }
    }
}

// MARK: - Filter Chip

private struct CardioFilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(AppFonts.caption1)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? AppColors.vitalityColor.opacity(0.2) : AppColors.surface)
            .foregroundColor(isActive ? AppColors.vitalityColor : AppColors.textSecondary)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isActive ? AppColors.vitalityColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

#Preview("Cardio History") {
    NavigationStack {
        CardioHistoryView()
    }
}
