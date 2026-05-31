import SwiftUI
import SwiftData

/// The workout-screen anatomy panel: a rotatable, colour-ranked 3D body with
/// muscle chips down each side, a score banner and weekly tiles — laid out to
/// match the "Workout" mockup.
///
/// Scores come from the player's logged workouts (`MuscleStatsService`) and
/// fall back to rich mock data on first run / in previews.
struct WorkoutAnatomyView: View {
    @StateObject private var controller = AnatomySceneController()
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]

    @State private var selectedRegion: MuscleRegion?
    @State private var scores: [MuscleRegion: MuscleScore] = MuscleScore.mock
    @State private var gender: AnatomyGender = .male

    private let leftRegions: [MuscleRegion] = [.chest, .shoulders, .biceps, .abs]
    private let rightRegions: [MuscleRegion] = [.back, .triceps, .quads, .calves]

    private var player: Player? { players.first }

    private var totalScore: Int { scores.values.reduce(0) { $0 + $1.score } }
    private var overallLevel: Int {
        scores.isEmpty ? 0 : totalScore / scores.count
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            header
            scoreBanner
            bodyWithChips
            controlsRow
            weeklyTiles
            MuscleColorLegend()
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.xs)
        }
        .padding(.vertical, AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .onAppear {
            syncGenderWithPlayer()
            loadScores()
        }
        .onChange(of: player?.workoutSessions.count ?? 0) { _, _ in loadScores() }
        .sheet(item: $selectedRegion) { region in
            MuscleDetailView(score: scores[region] ?? .empty(region))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Muscle Map")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text("Drag to rotate · tap a muscle")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    // MARK: - Score banner

    private var scoreBanner: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Muscle Score")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                Text("\(totalScore)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Label("120 from last week", systemImage: "arrow.up.right")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.success)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("LEVEL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
                Text("\(overallLevel)")
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(AppColors.accentPurple)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadiusSmall)
                    .stroke(AppColors.accentPurple.opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(AppSpacing.cardCornerRadiusSmall)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    // MARK: - Body + side chips

    private var bodyWithChips: some View {
        HStack(spacing: AppSpacing.xs) {
            VStack(spacing: AppSpacing.xs) {
                ForEach(leftRegions, id: \.self) { region in
                    MuscleChip(region: region, score: scores[region], alignment: .leading) {
                        select(region)
                    }
                }
            }
            .frame(width: 96)

            AnatomySceneView(controller: controller,
                             scores: scores,
                             selectedRegion: $selectedRegion)
                .frame(maxWidth: .infinity)
                .frame(height: 340)

            VStack(spacing: AppSpacing.xs) {
                ForEach(rightRegions, id: \.self) { region in
                    MuscleChip(region: region, score: scores[region], alignment: .trailing) {
                        select(region)
                    }
                }
            }
            .frame(width: 96)
        }
        .padding(.horizontal, AppSpacing.sm)
    }

    // MARK: - Controls (gender toggle + reset)

    private var controlsRow: some View {
        HStack(spacing: AppSpacing.sm) {
            Button(action: toggleGender) {
                HStack(spacing: 4) {
                    Image(systemName: gender == .male ? "figure.stand" : "figure.stand.dress")
                    Text(gender == .male ? "Male" : "Female")
                }
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 6)
                .background(AppColors.surfaceElevated)
                .cornerRadius(8)
            }

            Button(action: { controller.resetOrientation() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 6)
                .background(AppColors.surfaceElevated)
                .cornerRadius(8)
            }
            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    // MARK: - Weekly tiles

    private var weeklyTiles: some View {
        HStack(spacing: AppSpacing.xs) {
            weeklyTile(value: "26", label: "Workouts")
            weeklyTile(value: "12,450 kg", label: "Volume")
            weeklyTile(value: "3,120", label: "Calories")
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }

    private func weeklyTile(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
            Text("This Week")
                .font(.system(size: 9))
                .foregroundColor(AppColors.textDisabled)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppSpacing.cardCornerRadiusSmall)
    }

    // MARK: - Actions

    private func select(_ region: MuscleRegion) {
        withAnimation(.easeInOut(duration: 0.2)) { selectedRegion = region }
    }

    private func toggleGender() {
        gender = (gender == .male) ? .female : .male
        controller.setBody(gender: gender)
        controller.apply(scores: scores, selected: selectedRegion)
        if let player {
            player.sexRaw = (gender == .female) ? "female" : "male"
            try? modelContext.save()
        }
    }

    private func syncGenderWithPlayer() {
        if (player?.sexRaw ?? "male") == "female" {
            gender = .female
            controller.setBody(gender: .female)
        }
    }

    private func loadScores() {
        guard let player else {
            scores = MuscleScore.mock
            return
        }
        let service = MuscleStatsService(modelContext: modelContext, player: player)
        let derived = MuscleScore.from(stats: service.computeAll())
        // Until the player has logged some training, show the demo data.
        scores = MuscleScore.isEmpty(derived) ? MuscleScore.mock : derived
    }
}

// MARK: - Muscle chip

private struct MuscleChip: View {
    let region: MuscleRegion
    let score: MuscleScore?
    let alignment: HorizontalAlignment
    let onTap: () -> Void

    private var level: Int { score?.level ?? 0 }
    private var displayLevel: Int { score?.score ?? 0 }
    private var color: Color { MuscleLevel(rawValue: level)?.color ?? MuscleLevel.untrained.color }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.xxs) {
                if alignment == .trailing {
                    textBlock
                    dot
                } else {
                    dot
                    textBlock
                }
            }
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
            .background(AppColors.surfaceElevated)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var dot: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color.opacity(0.6), radius: 3)
    }

    private var textBlock: some View {
        VStack(alignment: alignment == .trailing ? .trailing : .leading, spacing: 0) {
            Text(region.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
            Text("Lv. \(displayLevel)")
                .font(.system(size: 10))
                .foregroundColor(AppColors.textTertiary)
        }
    }
}

// MARK: - Legend

struct MuscleColorLegend: View {
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

#Preview {
    ScrollView {
        WorkoutAnatomyView()
            .padding()
    }
    .background(AppColors.backgroundGradient.ignoresSafeArea())
    .modelContainer(for: Player.self, inMemory: true)
}
