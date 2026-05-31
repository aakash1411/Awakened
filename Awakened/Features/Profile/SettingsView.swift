import SwiftUI
import UIKit

/// Dedicated Settings screen (Anime mockup): grouped Preferences / Account /
/// Support sections plus Log Out. Every row maps to a real action or stored
/// preference — no placeholder controls.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openURL) private var openURL
    @ObservedObject private var themeManager = ThemeManager.shared

    @AppStorage("preferDarkMode") private var preferDarkMode = true
    @AppStorage("useMetricUnits") private var useMetricUnits = true

    @State private var showHealthSettings = false
    @State private var showLogoutConfirm = false

    private var soundsOn: Binding<Bool> {
        Binding(get: { !SoundManager.shared.isMuted },
                set: { SoundManager.shared.isMuted = !$0 })
    }
    private var hapticsOn: Binding<Bool> {
        Binding(get: { SoundManager.shared.hapticsEnabled },
                set: { SoundManager.shared.hapticsEnabled = $0 })
    }

    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    preferencesSection
                    accountSection
                    supportSection
                    logOutButton
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showHealthSettings) {
            HealthSettingsView()
        }
        .alert("Log Out?", isPresented: $showLogoutConfirm) {
            Button("Log Out", role: .destructive) { appState.resetOnboarding() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll return to onboarding. Your saved progress stays on this device.")
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        section("Preferences") {
            // Grouped to stay within SwiftUI's 10-view ViewBuilder limit.
            Group {
                navRow(icon: "paintpalette.fill", title: "Theme",
                       trailing: themeManager.current.displayName) {
                    ThemePickerView()
                }
                divider
                toggleRow(icon: "moon.fill", title: "Dark Mode", isOn: $preferDarkMode)
                divider
                navRow(icon: "drop.fill", title: "Accent Color",
                       trailing: "Purple", trailingColor: AppColors.accentPurple) {
                    ThemePickerView()
                }
                divider
                unitsRow
            }
            divider
            Group {
                toggleRow(icon: "speaker.wave.2.fill", title: "Sounds", isOn: soundsOn)
                divider
                toggleRow(icon: "iphone.radiowaves.left.and.right", title: "Haptics", isOn: hapticsOn)
                divider
                buttonRow(icon: "bell.fill", title: "Notifications") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                divider
                navRow(icon: "eye.slash.fill", title: "Privacy") {
                    ProfilePrivacySettingsView()
                }
            }
        }
    }

    private var unitsRow: some View {
        HStack(spacing: AppSpacing.md) {
            icon("ruler.fill")
            Text("Units")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Menu {
                Button("Metric") { useMetricUnits = true }
                Button("Imperial") { useMetricUnits = false }
            } label: {
                HStack(spacing: 4) {
                    Text(useMetricUnits ? "Metric" : "Imperial")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.md)
    }

    // MARK: - Account

    private var accountSection: some View {
        section("Account") {
            buttonRow(icon: "heart.fill", title: "Apple Health",
                      trailing: HealthKitManager.shared.isAuthorized ? "Connected" : "Not connected") {
                showHealthSettings = true
            }
            divider
            navRow(icon: "person.crop.circle", title: "Edit Profile") {
                EditDisplayProfileView(syncEngine: appState.profileSyncEngine)
            }
            divider
            navRow(icon: "slider.horizontal.3", title: "Quest Settings") {
                QuestConfigView()
            }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        section("Support") {
            buttonRow(icon: "questionmark.circle.fill", title: "Help Center") {
                if let url = URL(string: "https://github.com/aakash1411/Awakened") {
                    openURL(url)
                }
            }
            divider
            buttonRow(icon: "envelope.fill", title: "Send Feedback") {
                if let url = URL(string: "mailto:support@awakened.app?subject=Awakened%20Feedback") {
                    openURL(url)
                }
            }
            divider
            HStack(spacing: AppSpacing.md) {
                icon("info.circle.fill")
                Text("About").font(AppFonts.body).foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("Version 1.0.0").font(AppFonts.caption1).foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
        }
    }

    private var logOutButton: some View {
        Button {
            showLogoutConfirm = true
        } label: {
            Text("Log Out")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.error)
                .frame(maxWidth: .infinity)
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                        .stroke(AppColors.error.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Row builders

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            VStack(spacing: 0) { content() }
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                        .stroke(AppColors.border, lineWidth: 1)
                )
        }
    }

    private func navRow<Destination: View>(icon name: String, title: String,
                                           trailing: String? = nil,
                                           trailingColor: Color = AppColors.textTertiary,
                                           @ViewBuilder destination: @escaping () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: AppSpacing.md) {
                icon(name)
                Text(title).font(AppFonts.body).foregroundColor(AppColors.textPrimary)
                Spacer()
                if let trailing {
                    Text(trailing).font(AppFonts.caption1).foregroundColor(trailingColor)
                }
                chevron
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private func buttonRow(icon name: String, title: String,
                           trailing: String? = nil,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                icon(name)
                Text(title).font(AppFonts.body).foregroundColor(AppColors.textPrimary)
                Spacer()
                if let trailing {
                    Text(trailing).font(AppFonts.caption1).foregroundColor(AppColors.textTertiary)
                }
                chevron
            }
            .padding(AppSpacing.md)
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(icon name: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: AppSpacing.md) {
            icon(name)
            Toggle(title, isOn: isOn)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
                .tint(AppColors.accentPurple)
        }
        .padding(AppSpacing.md)
    }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .foregroundColor(AppColors.accentPurple)
            .frame(width: 24)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(AppColors.textTertiary)
    }

    private var divider: some View {
        Divider().background(AppColors.border)
    }
}
