import SwiftUI

/// Chronological list of all meditation sessions
struct MeditationHistoryView: View {
    @StateObject private var service = MeditationService()
    @State private var selectedSource: MeditationSource?
    
    private var filteredSessions: [MeditationSession] {
        guard let source = selectedSource else {
            return service.recentSessions
        }
        return service.recentSessions.filter { $0.source == source }
    }
    
    /// Group sessions by date
    private var groupedSessions: [(String, [MeditationSession])] {
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
                        sourceChip(title: "All", source: nil)
                        
                        ForEach(MeditationSource.allCases) { source in
                            sourceChip(title: source.displayName, source: source)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.md)
                }
                
                // Sessions list
                if filteredSessions.isEmpty {
                    Spacer()
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "brain.head.profile")
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
    
    private func sourceChip(title: String, source: MeditationSource?) -> some View {
        Button {
            selectedSource = source
        } label: {
            Text(title)
                .font(AppFonts.caption1)
                .fontWeight(selectedSource == source ? .semibold : .regular)
                .foregroundColor(selectedSource == source ? .white : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(selectedSource == source ? AppColors.senseColor : AppColors.surface)
                .cornerRadius(AppSpacing.buttonCornerRadius)
        }
    }
    
    private func historyRow(_ session: MeditationSession) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: session.typeIcon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.senseColor)
                .frame(width: 36, height: 36)
                .background(AppColors.senseColor.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: session.source.icon)
                        .font(.system(size: 10))
                    Text(session.source.displayName)
                        .font(AppFonts.caption2)
                    Text("•")
                    Text(session.timeFormatted)
                        .font(AppFonts.caption2)
                }
                .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationFormatted)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("+\(session.xpEarned) XP")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.senseColor)
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
