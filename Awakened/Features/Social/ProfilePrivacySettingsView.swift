import SwiftUI

/// View for configuring what data is visible on the public profile
struct ProfilePrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings = ProfilePrivacySettings.load()
    @State private var hasChanges = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Info header
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(AppColors.primaryBlue)
                        Text("Control what other players can see on your public profile.")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.primaryBlue.opacity(0.1))
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Visibility toggles
                    VStack(spacing: 0) {
                        SectionHeader(title: "Profile Visibility")
                        
                        PrivacyToggle(
                            icon: "star.fill",
                            title: "Level & Rank",
                            subtitle: "Show your level and hunter rank",
                            isOn: $settings.showLevel
                        )
                        
                        Divider().background(AppColors.border)
                        
                        PrivacyToggle(
                            icon: "chart.bar.fill",
                            title: "Stat Levels",
                            subtitle: "Show individual stat levels on radar chart",
                            isOn: $settings.showStats
                        )
                        
                        Divider().background(AppColors.border)
                        
                        PrivacyToggle(
                            icon: "flame.fill",
                            title: "Streak",
                            subtitle: "Show current and longest streak",
                            isOn: $settings.showStreak
                        )
                        
                        Divider().background(AppColors.border)
                        
                        PrivacyToggle(
                            icon: "dumbbell.fill",
                            title: "Workouts",
                            subtitle: "Show workout count and activity",
                            isOn: $settings.showWorkouts
                        )
                        
                        Divider().background(AppColors.border)
                        
                        PrivacyToggle(
                            icon: "trophy.fill",
                            title: "Achievements",
                            subtitle: "Show unlocked achievement count",
                            isOn: $settings.showAchievements
                        )
                        
                        Divider().background(AppColors.border)
                        
                        PrivacyToggle(
                            icon: "crossed.swords",
                            title: "Duel Record",
                            subtitle: "Show win/loss record",
                            isOn: $settings.showDuelRecord
                        )
                    }
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Social permissions
                    VStack(spacing: 0) {
                        SectionHeader(title: "Social Permissions")
                        
                        PrivacyToggle(
                            icon: "person.badge.plus",
                            title: "Friend Requests",
                            subtitle: "Allow others to send you friend requests",
                            isOn: $settings.allowFriendRequests
                        )
                        
                        Divider().background(AppColors.border)
                        
                        PrivacyToggle(
                            icon: "shield.lefthalf.filled",
                            title: "Guild Invites",
                            subtitle: "Allow guilds to invite you",
                            isOn: $settings.allowGuildInvites
                        )
                        
                        Divider().background(AppColors.border)
                        
                        PrivacyToggle(
                            icon: "bolt.fill",
                            title: "Duel Challenges",
                            subtitle: "Allow friends to challenge you to duels",
                            isOn: $settings.allowDuelChallenges
                        )
                    }
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Privacy Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: settings.showLevel) { _, _ in hasChanges = true }
        .onChange(of: settings.showStats) { _, _ in hasChanges = true }
        .onChange(of: settings.showStreak) { _, _ in hasChanges = true }
        .onChange(of: settings.showWorkouts) { _, _ in hasChanges = true }
        .onChange(of: settings.showAchievements) { _, _ in hasChanges = true }
        .onChange(of: settings.showDuelRecord) { _, _ in hasChanges = true }
        .onChange(of: settings.allowFriendRequests) { _, _ in hasChanges = true }
        .onChange(of: settings.allowGuildInvites) { _, _ in hasChanges = true }
        .onChange(of: settings.allowDuelChallenges) { _, _ in hasChanges = true }
        .onDisappear {
            if hasChanges {
                settings.save()
            }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}

// MARK: - Privacy Toggle Row

private struct PrivacyToggle: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primaryBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppColors.primaryBlue)
        }
        .padding(AppSpacing.md)
    }
}
