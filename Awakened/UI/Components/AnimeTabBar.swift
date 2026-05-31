import SwiftUI

/// Custom bottom navigation bar matching the Anime mockup:
/// `Home · Progress · (center crest button) · Community · Profile`.
///
/// The center crest is a persistent quick-action button (it opens the
/// `QuickActionsSheet`), which is how Workout Log and Nutrition are reached.
struct AnimeTabBar: View {
    @Binding var selection: AppTab
    var onCenterTap: () -> Void

    /// Height of the solid bar (excludes the protruding center crest).
    static let barHeight: CGFloat = 64

    var body: some View {
        ZStack(alignment: .bottom) {
            // The four standard destinations, with a gap reserved for the crest.
            HStack(spacing: 0) {
                tabButton(.home)
                tabButton(.progress)
                Color.clear.frame(width: 72)
                tabButton(.community)
                tabButton(.profile)
            }
            .frame(height: Self.barHeight)
            .frame(maxWidth: .infinity)
            .background(
                AppColors.surface
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(AppColors.border),
                        alignment: .top
                    )
            )

            centerButton
                .offset(y: -16)
        }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(tab.title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? AppColors.accentPurple : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The glowing monarch crest. Uses an SF Symbol placeholder; drop in a
    /// dedicated crest asset later and swap the `Image` without other changes.
    private var centerButton: some View {
        Button(action: onCenterTap) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.accentPurple, AppColors.primaryBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 58, height: 58)
                    .overlay(
                        Circle().stroke(AppColors.accentPurple.opacity(0.5), lineWidth: 3)
                    )
                    .shadow(color: AppColors.accentPurple.opacity(0.6), radius: 12, y: 4)

                Image(systemName: "crown.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
    }
}
