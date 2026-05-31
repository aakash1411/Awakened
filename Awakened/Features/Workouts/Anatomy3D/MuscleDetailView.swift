import SwiftUI

/// Muscle detail sheet shown when a muscle is selected — matches the
/// "Muscle Details" mockup (header + progress, top exercises, muscle stats).
struct MuscleDetailView: View {
    let score: MuscleScore
    @Environment(\.dismiss) private var dismiss

    private var color: Color {
        MuscleLevel(rawValue: score.level)?.color ?? MuscleLevel.untrained.color
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerBlock
                topExercisesBlock
                muscleStatsBlock
            }
            .padding(AppSpacing.lg)
        }
        .background(AppColors.background.ignoresSafeArea())
    }

    // MARK: - Header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: score.region.symbol)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.18))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(score.region.displayName)
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Level \(score.score) – \(score.levelLabel)")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text("\(score.score) / 100")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }

            progressBar
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppColors.surfaceElevated)
                Capsule()
                    .fill(LinearGradient(colors: [color.opacity(0.7), color],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(score.normalizedScore))
            }
        }
        .frame(height: 8)
    }

    // MARK: - Top exercises

    private var topExercisesBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Top Exercises")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)

            ForEach(MuscleDetailView.topExercises(for: score.region), id: \.name) { exercise in
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 14))
                        .foregroundColor(color)
                        .frame(width: 28, height: 28)
                        .background(AppColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(exercise.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text(exercise.detail)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    Spacer()
                    Text(exercise.metric)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }

    // MARK: - Muscle stats

    private var muscleStatsBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Muscle Stats")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: AppSpacing.sm) {
                statTile(title: "Volume",
                         value: "\(Int(score.activation * 3200)) kg",
                         delta: deltaString(score.growthTrend),
                         icon: "scalemass.fill")
                statTile(title: "Strength",
                         value: "\(score.score) / 100",
                         delta: deltaString(score.growthTrend * 0.8),
                         icon: "bolt.fill")
                statTile(title: "Endurance",
                         value: "\(Int((1 - score.fatigue) * 100)) / 100",
                         delta: deltaString(max(0, 4 - score.growthTrend)),
                         icon: "wind")
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }

    private func statTile(title: String, value: String, delta: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(title)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
            Text(delta)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.success)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppSpacing.cardCornerRadiusSmall)
    }

    private func deltaString(_ value: Double) -> String {
        let rounded = Int(value.rounded())
        return rounded >= 0 ? "↑ \(rounded)%" : "↓ \(abs(rounded))%"
    }
}

// MARK: - Mock exercises

extension MuscleDetailView {
    struct MockExercise {
        let name: String
        let detail: String
        let metric: String
    }

    /// Representative top exercises per region (mock data — the live exercise
    /// DB can replace this later via `PersonalRecord`s).
    static func topExercises(for region: MuscleRegion) -> [MockExercise] {
        switch region {
        case .chest:
            return [.init(name: "Bench Press", detail: "4 sets × 8 reps", metric: "1RM 100 kg"),
                    .init(name: "Incline Dumbbell Press", detail: "4 sets × 10 reps", metric: "1RM 32 kg"),
                    .init(name: "Push Up", detail: "3 sets × 15 reps", metric: "BW")]
        case .back:
            return [.init(name: "Pull Up", detail: "4 sets × 8 reps", metric: "BW +10 kg"),
                    .init(name: "Barbell Row", detail: "4 sets × 8 reps", metric: "1RM 100 kg"),
                    .init(name: "Lat Pulldown", detail: "3 sets × 12 reps", metric: "70 kg")]
        case .shoulders:
            return [.init(name: "Overhead Press", detail: "4 sets × 8 reps", metric: "1RM 55 kg"),
                    .init(name: "Lateral Raise", detail: "3 sets × 15 reps", metric: "12 kg"),
                    .init(name: "Face Pull", detail: "3 sets × 15 reps", metric: "30 kg")]
        case .biceps:
            return [.init(name: "Barbell Curl", detail: "4 sets × 10 reps", metric: "40 kg"),
                    .init(name: "Hammer Curl", detail: "3 sets × 12 reps", metric: "16 kg"),
                    .init(name: "Preacher Curl", detail: "3 sets × 12 reps", metric: "30 kg")]
        case .triceps:
            return [.init(name: "Tricep Pushdown", detail: "3 sets × 12 reps", metric: "1RM 35 kg"),
                    .init(name: "Skull Crusher", detail: "3 sets × 10 reps", metric: "30 kg"),
                    .init(name: "Dips", detail: "3 sets × 12 reps", metric: "BW")]
        case .forearms:
            return [.init(name: "Wrist Curl", detail: "3 sets × 15 reps", metric: "20 kg"),
                    .init(name: "Farmer's Carry", detail: "3 sets × 30 m", metric: "40 kg"),
                    .init(name: "Reverse Curl", detail: "3 sets × 12 reps", metric: "20 kg")]
        case .abs, .obliques:
            return [.init(name: "Hanging Leg Raise", detail: "3 sets × 12 reps", metric: "BW"),
                    .init(name: "Cable Crunch", detail: "3 sets × 15 reps", metric: "40 kg"),
                    .init(name: "Russian Twist", detail: "3 sets × 20 reps", metric: "10 kg")]
        case .glutes:
            return [.init(name: "Hip Thrust", detail: "4 sets × 10 reps", metric: "1RM 80 kg"),
                    .init(name: "Bulgarian Split Squat", detail: "3 sets × 12 reps", metric: "1RM 16 kg"),
                    .init(name: "Glute Bridge", detail: "3 sets × 15 reps", metric: "BW")]
        case .quads:
            return [.init(name: "Barbell Squat", detail: "4 sets × 8 reps", metric: "1RM 90 kg"),
                    .init(name: "Leg Press", detail: "4 sets × 10 reps", metric: "180 kg"),
                    .init(name: "Lunge", detail: "3 sets × 12 reps", metric: "20 kg")]
        case .hamstrings:
            return [.init(name: "Romanian Deadlift", detail: "3 sets × 10 reps", metric: "80 kg"),
                    .init(name: "Leg Curl", detail: "3 sets × 12 reps", metric: "45 kg"),
                    .init(name: "Good Morning", detail: "3 sets × 10 reps", metric: "40 kg")]
        case .calves:
            return [.init(name: "Standing Calf Raise", detail: "4 sets × 15 reps", metric: "60 kg"),
                    .init(name: "Seated Calf Raise", detail: "3 sets × 15 reps", metric: "40 kg"),
                    .init(name: "Jump Rope", detail: "3 sets × 60 s", metric: "BW")]
        }
    }
}

#Preview {
    MuscleDetailView(score: MuscleScore.mock[.chest]!)
}
