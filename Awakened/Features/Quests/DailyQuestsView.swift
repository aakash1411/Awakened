import SwiftUI
import SwiftData

/// Full Daily Quests screen (Anime mockup): field filter chips, quest cards
/// with EXP rewards and completion state, and a daily completion-reward banner.
struct DailyQuestsView: View {
    @Query private var players: [Player]
    @State private var filter: StatType? = nil

    private var player: Player? { players.first }

    private var quests: [Quest] {
        let all = player?.todayQuests ?? []
        guard let filter else { return all }
        return all.filter { $0.statType == filter }
    }

    private var totalReward: Int {
        (player?.todayQuests ?? []).reduce(0) { $0 + $1.xpReward }
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    filterChips

                    ForEach(quests) { quest in
                        QuestRowCard(quest: quest)
                    }

                    if quests.isEmpty {
                        Text("No quests in this field today")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.xl)
                    }

                    completionReward

                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Daily Quests")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                chip(title: "All", icon: "square.grid.2x2.fill", color: AppColors.accentPurple, isSelected: filter == nil) {
                    filter = nil
                }
                ForEach(StatType.orderedCases) { stat in
                    chip(title: stat.displayName, icon: stat.icon, color: stat.color, isSelected: filter == stat) {
                        filter = stat
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(title: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(AppFonts.caption1)
            }
            .foregroundColor(isSelected ? .white : AppColors.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 8)
            .background(isSelected ? color : AppColors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? color : AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var completionReward: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily Completion Reward")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text("Finish all quests today")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            Spacer()
            Text("+\(totalReward) EXP")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.accentPurple)
        }
        .padding(AppSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [AppColors.accentPurple.opacity(0.25), AppColors.surface],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.accentPurple.opacity(0.4), lineWidth: 1)
        )
    }
}

/// A single quest card on the Daily Quests screen.
struct QuestRowCard: View {
    let quest: Quest

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: quest.statType.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(quest.statType.color)
                .frame(width: 44, height: 44)
                .background(quest.statType.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(quest.title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text(quest.progressText)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                Text("+\(quest.xpReward) EXP")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(quest.statType.color)
            }

            Spacer()

            Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(quest.isCompleted ? AppColors.success : AppColors.textTertiary)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        DailyQuestsView()
    }
    .modelContainer(for: Player.self, inMemory: true)
}
