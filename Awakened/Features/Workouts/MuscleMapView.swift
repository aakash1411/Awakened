import SwiftUI
import SwiftData
import MuscleMap

/// Workout-page muscle anatomy panel.
///
/// **Phase 1 (current):** Built on top of the
/// [MuscleMap](https://github.com/melihcolpan/MuscleMap) SwiftUI SDK which
/// ships fully-segmented vector anatomy (22 muscles + 14 sub-groups) for
/// male/female × front/back. Per-muscle colours are driven by
/// `MuscleStatsService` output through `MuscleRegionMapping`.
///
/// **Phase 2 (planned):** Once a licensed segmented USDZ model lands, the
/// `is3DEnabled` flag flips to `true` and `Muscle3DView` takes over (see
/// `docs/MUSCLE_MAP_PLAN.md`).
struct MuscleMapView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]

    @State private var selectedRegion: AnatomyRegion?
    @State private var statsByRegion: [AnatomyRegion: MuscleRegionStats] = [:]
    @State private var bodySide: BodySide = .front

    private var player: Player? { players.first }
    private var bodyGender: BodyGender {
        (player?.sexRaw ?? "male") == "female" ? .female : .male
    }

    /// Pre-computed `[Muscle: Int]` (0–4) payload for the SDK heatmap.
    private var intensities: [Muscle: Int] {
        MuscleRegionMapping.intensities(from: statsByRegion)
    }

    /// Stat cards laid out below the figure.
    private let displayRegions: [AnatomyRegion] = [
        .chest, .back, .shoulders, .biceps, .triceps,
        .abs, .quads, .hamstrings, .glutes, .calves
    ]

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            header
            scoreBanner

            // Main 3D-style body view (Phase 1: MuscleMap SDK)
            BodyView(gender: bodyGender, side: bodySide)
                .intensities(intensities, colorScale: .workout)
                .onMuscleSelected { muscle, _ in
                    if let region = MuscleRegionMapping.region(for: muscle) {
                        selectedRegion = region
                    }
                }
                .frame(height: 380)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                        .fill(AppColors.surfaceElevated.opacity(0.4))
                )
                .padding(.horizontal, AppSpacing.md)

            sideToggle

            statsGrid
                .padding(.horizontal, AppSpacing.md)

            MuscleLevelLegend()
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.sm)
        }
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .onAppear { loadStats() }
        .onChange(of: player?.workoutSessions.count ?? 0) { _, _ in loadStats() }
        .sheet(item: $selectedRegion) { region in
            if let stats = statsByRegion[region] {
                MuscleDetailSheet(stats: stats)
                    .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Muscle Map")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text("Tap a muscle for details")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            Spacer()
            Button(action: toggleSex) {
                HStack(spacing: 4) {
                    Image(systemName: bodyGender == .male ? "figure.stand" : "figure.stand.dress")
                    Text(bodyGender == .male ? "Male" : "Female")
                }
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 6)
                .background(AppColors.surfaceElevated)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    // MARK: - Score banner

    private var totalMuscleScore: Int {
        AnatomyRegion.allCases.reduce(0) { acc, r in
            acc + (statsByRegion[r]?.level.rawValue ?? 0)
        } * 100
    }

    private var scoreBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Muscle Score")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                Text("\(totalMuscleScore)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
            }
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 24))
                .foregroundColor(AppColors.primaryBlue)
                .padding(10)
                .background(AppColors.primaryBlue.opacity(0.15))
                .clipShape(Circle())
        }
        .padding(.horizontal, AppSpacing.md + 4)
    }

    // MARK: - Front/Back toggle

    private var sideToggle: some View {
        HStack(spacing: 0) {
            sideButton(.front, label: "Front")
            sideButton(.back, label: "Back")
        }
        .padding(4)
        .background(AppColors.surfaceElevated)
        .cornerRadius(10)
        .padding(.horizontal, AppSpacing.lg + AppSpacing.md)
    }

    private func sideButton(_ side: BodySide, label: String) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { bodySide = side } }) {
            Text(label)
                .font(AppFonts.caption1)
                .fontWeight(bodySide == side ? .semibold : .regular)
                .foregroundColor(bodySide == side ? AppColors.textPrimary : AppColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(bodySide == side ? AppColors.primaryBlue.opacity(0.25) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats grid

    private var statsGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: AppSpacing.xs
        ) {
            ForEach(displayRegions, id: \.self) { region in
                MuscleStatCard(
                    region: region,
                    stats: statsByRegion[region]
                ) {
                    selectedRegion = region
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadStats() {
        guard let player = player else { return }
        let svc = MuscleStatsService(modelContext: modelContext, player: player)
        statsByRegion = svc.computeAll()
    }

    private func toggleSex() {
        guard let player = player else { return }
        player.sexRaw = bodyGender == .male ? "female" : "male"
        try? modelContext.save()
    }
}

// MARK: - Stat Card

/// Compact muscle-group row: color dot + name + level label.
struct MuscleStatCard: View {
    let region: AnatomyRegion
    let stats: MuscleRegionStats?
    let onTap: () -> Void

    private var level: MuscleLevel { stats?.level ?? .untrained }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(level.color)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(level.color.opacity(0.45), lineWidth: 3)
                            .blur(radius: 2)
                    )

                VStack(alignment: .leading, spacing: 0) {
                    Text(region.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.textPrimary)
                    Text(level.label)
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, 8)
            .background(AppColors.surfaceElevated)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legend

struct MuscleLevelLegend: View {
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(MuscleLevel.allCases, id: \.rawValue) { level in
                HStack(spacing: 4) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 8, height: 8)
                    Text(level.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Detail Sheet

struct MuscleDetailSheet: View {
    let stats: MuscleRegionStats
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.sm) {
                Circle()
                    .fill(stats.level.color)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text("\(stats.level.rawValue)")
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    )

                Text(stats.region.displayName)
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary)

                Text(stats.level.label)
                    .font(AppFonts.headline)
                    .foregroundColor(stats.level.color)
            }
            .padding(.top, AppSpacing.lg)

            HStack(spacing: AppSpacing.lg) {
                statCell(value: formatVolume(stats.totalVolume), label: "Total Volume")
                statCell(value: "\(stats.recentSets)", label: "Sets in 30d")
                statCell(
                    value: stats.daysSinceLast.map { "\($0)d" } ?? "—",
                    label: "Last Trained"
                )
            }
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .padding(.horizontal, AppSpacing.screenHorizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.backgroundGradient)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private func formatVolume(_ v: Double) -> String {
        if v >= 1_000 { return String(format: "%.1fk", v / 1_000) }
        return String(format: "%.0f", v)
    }
}
