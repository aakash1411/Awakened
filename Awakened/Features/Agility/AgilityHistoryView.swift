import SwiftUI

/// Chronological list of all flexibility/agility sessions with filtering
struct AgilityHistoryView: View {
    @StateObject private var service = AgilityService()
    @State private var selectedFilter: FlexibilityType?
    
    private var filteredSessions: [FlexibilitySession] {
        guard let filter = selectedFilter else {
            return service.recentSessions
        }
        return service.recentSessions.filter { $0.type == filter }
    }
    
    /// Group sessions by date
    private var groupedSessions: [(String, [FlexibilitySession])] {
        let grouped = Dictionary(grouping: filteredSessions) { session in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: session.date)
        }
        return grouped.sorted { lhs, rhs in
            guard let lhsDate = lhs.value.first?.date,
                  let rhsDate = rhs.value.first?.date else { return false }
            return lhsDate > rhsDate
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        FilterChipButton(title: "All", isSelected: selectedFilter == nil) {
                            selectedFilter = nil
                        }
                        
                        ForEach([FlexibilityType.yoga, .calisthenics, .stretching, .pilates, .dance, .martialArts], id: \.self) { type in
                            FilterChipButton(title: type.displayName, isSelected: selectedFilter == type) {
                                selectedFilter = type
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.md)
                }
                
                // Sessions list
                if filteredSessions.isEmpty {
                    Spacer()
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "figure.flexibility")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.textTertiary)
                        Text("No sessions found")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.lg) {
                            ForEach(groupedSessions, id: \.0) { dateString, sessions in
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text(dateString)
                                        .font(AppFonts.caption1)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppColors.textTertiary)
                                        .padding(.horizontal, AppSpacing.screenHorizontal)
                                    
                                    VStack(spacing: 0) {
                                        ForEach(sessions) { session in
                                            historyRow(session)
                                            
                                            if session.id != sessions.last?.id {
                                                Divider()
                                                    .background(AppColors.border)
                                                    .padding(.leading, 56)
                                            }
                                        }
                                    }
                                    .background(AppColors.surface)
                                    .cornerRadius(AppSpacing.cardCornerRadius)
                                    .padding(.horizontal, AppSpacing.screenHorizontal)
                                }
                            }
                        }
                        .padding(.bottom, AppSpacing.xxl)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await service.fetchRecentSessions(limit: 50)
        }
    }
    
    private func historyRow(_ session: FlexibilitySession) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: session.icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.agilityColor)
                .frame(width: 36, height: 36)
                .background(AppColors.agilityColor.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.sm) {
                    Text(session.intensity.displayName)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("•")
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(session.durationFormatted)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            Text("+\(session.xpEarned) XP")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.agilityColor)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Filter Chip Button

private struct FilterChipButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.caption1)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(isSelected ? AppColors.agilityColor : AppColors.surface)
                .cornerRadius(AppSpacing.buttonCornerRadius)
        }
    }
}
