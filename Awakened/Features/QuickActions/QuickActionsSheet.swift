import SwiftUI

/// Quick-action hub presented by the center crest button in the bottom bar.
/// Gives one-tap access to the screens that aren't on the tab bar
/// (Workout Log, Nutrition) plus the per-field logging screens.
struct QuickActionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                        action("Log Workout", "dumbbell.fill", AppColors.strengthColor) { WorkoutsView() }
                        action("Nutrition", "fork.knife", AppColors.vitalityColor) { NutritionView() }
                        action("Cardio", "heart.fill", AppColors.agilityColor) { CardioView() }
                        action("Spirit", "sparkles", AppColors.senseColor) { SenseView() }
                        action("Sensation", "snowflake", AppColors.vitalityColor) { AgilityView() }
                        action("Intelligence", "brain.head.profile", AppColors.intelligenceColor) { IntelligenceView() }
                    }
                    .padding(AppSpacing.screenHorizontal)
                }
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppColors.accentPurple)
                }
            }
        }
    }

    private func action<Destination: View>(
        _ title: String,
        _ icon: String,
        _ color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 56, height: 56)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())

                Text(title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
