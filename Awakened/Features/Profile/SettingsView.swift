import SwiftUI

/// Dedicated Settings screen (Anime mockup), reached from the gear on Profile.
/// Reuses the existing `SettingsSection` content so there is a single source
/// of truth for the settings rows.
struct SettingsView: View {
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    SettingsSection()
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
