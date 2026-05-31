import SwiftUI
import SwiftData

/// Rank / Level-Up celebration screen (Anime mockup), driven by the real XP
/// system — shows the rank crest, level, progress to the next rank, total power,
/// and the Five Fields summary. No manual stat allocation (stats auto-level).
struct RankLevelUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]

    private var player: Player? { players.first }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            if let player = player {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        crest(player)

                        Text(player.rank.displayName)
                            .font(AppFonts.title1)
                            .foregroundColor(player.rank.color)

                        Text(player.rank.motivationalMessage)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.lg)

                        rankProgress(player)

                        totalPowerCard(player)

                        fieldsSummary(player)

                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.lg)
                }
            } else {
                Text("No player found")
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .navigationTitle("Rank")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { dismiss() }
                    .foregroundColor(AppColors.accentPurple)
            }
        }
    }

    // MARK: - Sections

    private func crest(_ player: Player) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [player.rank.color.opacity(0.5), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 110
                    )
                )
                .frame(width: 220, height: 220)

            Circle()
                .fill(AppColors.surface)
                .frame(width: 150, height: 150)
                .overlay(Circle().stroke(player.rank.color, lineWidth: 3))

            VStack(spacing: 2) {
                Image(systemName: player.rank.icon)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundColor(player.rank.color)
                Text("LV \(player.level)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }

    private func rankProgress(_ player: Player) -> some View {
        let rank = player.rank
        let nextRank = rank.nextRank
        let lower = rank.minLevel
        let upper = nextRank?.minLevel ?? rank.maxLevel
        let span = max(upper - lower, 1)
        let fraction = min(max(Double(player.level - lower) / Double(span), 0), 1)

        return card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    Text("Progress to next rank")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    if let nextRank {
                        Text(nextRank.displayName)
                            .font(AppFonts.caption1)
                            .foregroundColor(nextRank.color)
                    } else {
                        Text("Max rank")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppColors.border).frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [rank.color, nextRank?.color ?? rank.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * fraction, height: 8)
                    }
                }
                .frame(height: 8)

                if let nextRank {
                    Text("Level \(player.level) · \(max(upper - player.level, 0)) levels to \(nextRank.displayName)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
    }

    private func totalPowerCard(_ player: Player) -> some View {
        let total = player.sortedStats.reduce(0) { $0 + $1.effectiveLevel }
        return card {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Power")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Text("\(total)")
                        .font(AppFonts.title1)
                        .foregroundColor(AppColors.textPrimary)
                }
                Spacer()
                Image(systemName: "bolt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.accentPurple)
            }
        }
    }

    private func fieldsSummary(_ player: Player) -> some View {
        card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Five Fields")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)

                ForEach(player.sortedStats) { stat in
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: stat.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(stat.color)
                            .frame(width: 22)
                        Text(stat.displayName)
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(stat.effectiveLevel)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(stat.color)
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(AppSpacing.cardPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
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
        RankLevelUpView()
    }
    .modelContainer(for: Player.self, inMemory: true)
}
