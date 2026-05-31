import SwiftUI
import SwiftData

/// Progress screen (Anime mockup): Overall/Weekly/Monthly range selector,
/// the Five Fields radar, a Total Power trend, and a per-field breakdown.
struct ProgressDashboardView: View {
    @Query private var players: [Player]
    @State private var range: ProgressRange = .overall

    private var player: Player? { players.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient.ignoresSafeArea()

                if let player = player {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            rangePicker

                            fiveFieldsCard(player)

                            totalPowerCard(player)

                            fieldBreakdownCard(player)

                            Spacer(minLength: AppSpacing.xxl)
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, AppSpacing.md)
                    }
                } else {
                    Text("No player found")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Sections

    private var rangePicker: some View {
        Picker("Range", selection: $range) {
            ForEach(ProgressRange.allCases) { r in
                Text(r.title).tag(r)
            }
        }
        .pickerStyle(.segmented)
    }

    private func fiveFieldsCard(_ player: Player) -> some View {
        card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Five Fields")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)

                RadarChartView(stats: player.sortedStats)
                    .frame(height: 260)
            }
        }
    }

    private func totalPowerCard(_ player: Player) -> some View {
        let total = totalPower(player)
        return card {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Total Power")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)

                Text("\(total)")
                    .font(AppFonts.largeTitle)
                    .foregroundColor(AppColors.textPrimary)

                Text("Across all five fields")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)

                SparklineShape(points: trendPoints(player))
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.accentPurple, AppColors.accentCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    .frame(height: 70)
                    .padding(.top, AppSpacing.xs)
            }
        }
    }

    private func fieldBreakdownCard(_ player: Player) -> some View {
        card {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text("Field Breakdown")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)

                ForEach(player.sortedStats) { stat in
                    breakdownRow(stat)
                }
            }
        }
    }

    private func breakdownRow(_ stat: Stat) -> some View {
        let value = stat.effectiveLevel
        let fraction = min(Double(value) / 100.0, 1.0)
        return VStack(spacing: AppSpacing.xs) {
            HStack {
                Image(systemName: stat.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(stat.color)
                    .frame(width: 22)
                Text(stat.displayName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(value) / 100")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppColors.border)
                        .frame(height: 6)
                    Capsule()
                        .fill(stat.color)
                        .frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)
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

    private func totalPower(_ player: Player) -> Int {
        player.sortedStats.reduce(0) { $0 + $1.effectiveLevel }
    }

    /// A lightweight, deterministic trend series derived from the current
    /// field levels — purely decorative until real weekly history is wired in.
    private func trendPoints(_ player: Player) -> [Double] {
        let levels = player.sortedStats.map { Double($0.effectiveLevel) }
        guard !levels.isEmpty else { return [0, 0] }
        var running = 0.0
        return levels.map { level in
            running += level
            return running
        }
    }
}

/// Range options for the Progress screen segmented control.
enum ProgressRange: String, CaseIterable, Identifiable {
    case overall, weekly, monthly
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// Simple polyline through normalized points, scaled to the available rect.
struct SparklineShape: Shape {
    let points: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        let maxValue = points.max() ?? 1
        let minValue = points.min() ?? 0
        let span = max(maxValue - minValue, 0.0001)
        let stepX = rect.width / CGFloat(points.count - 1)

        for (index, value) in points.enumerated() {
            let x = rect.minX + CGFloat(index) * stepX
            let normalized = (value - minValue) / span
            let y = rect.maxY - CGFloat(normalized) * rect.height
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
}

#Preview {
    ProgressDashboardView()
        .modelContainer(for: Player.self, inMemory: true)
}
