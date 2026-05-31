import SwiftUI
import SwiftData

/// Full list of learning sessions with category filtering
struct LearningSessionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LearningSession.date, order: .reverse) private var sessions: [LearningSession]
    @State private var selectedCategory: LearningCategory?
    @State private var showAddSession = false
    
    private var filteredSessions: [LearningSession] {
        guard let category = selectedCategory else { return sessions }
        return sessions.filter { $0.category == category }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        categoryChip(title: "All", category: nil)
                        ForEach(LearningCategory.allCases) { cat in
                            categoryChip(title: cat.displayName, category: cat)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.vertical, AppSpacing.md)
                }
                
                if filteredSessions.isEmpty {
                    Spacer()
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.textTertiary)
                        Text("No learning sessions yet")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.sm) {
                            ForEach(filteredSessions) { session in
                                sessionRow(session)
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.bottom, AppSpacing.xxl)
                    }
                }
            }
        }
        .navigationTitle("Learning Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddSession = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.intelligenceColor)
                }
            }
        }
        .sheet(isPresented: $showAddSession) {
            AddLearningSessionView()
        }
    }
    
    private func categoryChip(title: String, category: LearningCategory?) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(title)
                .font(AppFonts.caption1)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .foregroundColor(selectedCategory == category ? .white : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(selectedCategory == category ? AppColors.intelligenceColor : AppColors.surface)
                .cornerRadius(AppSpacing.buttonCornerRadius)
        }
    }
    
    private func sessionRow(_ session: LearningSession) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: session.category.icon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.intelligenceColor)
                .frame(width: 36, height: 36)
                .background(AppColors.intelligenceColor.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(session.category.displayName)
                    Text("•")
                    Text(session.durationFormatted)
                    if session.source != .manual {
                        Text("•")
                        Image(systemName: session.source.icon)
                            .font(.system(size: 10))
                    }
                }
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(session.xpEarned) XP")
                    .font(AppFonts.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.intelligenceColor)
                Text(session.formattedDate)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
