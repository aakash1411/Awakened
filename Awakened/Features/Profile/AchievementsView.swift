import SwiftUI
import SwiftData

/// Full achievements gallery grouped by category
struct AchievementsView: View {
    @Query(sort: \Achievement.categoryRaw) private var achievements: [Achievement]
    @State private var selectedCategory: AchievementCategory?
    
    private var filteredAchievements: [Achievement] {
        guard let category = selectedCategory else { return achievements }
        return achievements.filter { $0.category == category }
    }
    
    private var unlockedCount: Int {
        achievements.filter(\.isUnlocked).count
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Summary header
                HStack {
                    Text("\(unlockedCount)/\(achievements.count) Unlocked")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.sm)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        categoryChip(title: "All", category: nil)
                        ForEach(AchievementCategory.allCases) { cat in
                            categoryChip(title: cat.displayName, category: cat)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.md)
                }
                
                // Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                        ForEach(filteredAchievements) { achievement in
                            NavigationLink {
                                AchievementDetailView(achievement: achievement)
                            } label: {
                                AchievementBadge(achievement: achievement)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func categoryChip(title: String, category: AchievementCategory?) -> some View {
        Button {
            selectedCategory = category
        } label: {
            Text(title)
                .font(AppFonts.caption1)
                .fontWeight(selectedCategory == category ? .semibold : .regular)
                .foregroundColor(selectedCategory == category ? .white : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(selectedCategory == category ? AppColors.accentPurple : AppColors.surface)
                .cornerRadius(AppSpacing.buttonCornerRadius)
        }
    }
}
