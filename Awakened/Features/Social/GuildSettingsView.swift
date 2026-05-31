import SwiftUI

/// Guild settings for leader/officers — edit info, manage roles, disband
struct GuildSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var guildService: GuildService
    
    @State private var showDisbandConfirm = false
    @State private var showLeaveConfirm = false
    @State private var actionError: String?
    
    private var isLeader: Bool {
        guildService.myGuild?.leaderID == UserDefaults.standard.string(forKey: "currentPlayerId")
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if let guild = guildService.myGuild {
                        // Guild info
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Guild Info")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textSecondary)
                            
                            infoRow("Name", value: guild.name)
                            infoRow("Level", value: "\(guild.guildLevel)")
                            infoRow("Rank", value: guild.guildRank.rawValue)
                            infoRow("Members", value: "\(guild.memberCount)/\(guild.maxMembers)")
                            infoRow("Visibility", value: guild.isPublic ? "Public" : "Private")
                            infoRow("Min Rank", value: guild.minRankToJoin.displayName)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Member management (leader only)
                        if isLeader {
                            memberManagement
                        }
                        
                        // Danger zone
                        dangerZone
                    }
                    
                    if let actionError {
                        Text(actionError)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.error)
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Guild Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .alert("Disband Guild?", isPresented: $showDisbandConfirm) {
            Button("Disband", role: .destructive) { disband() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the guild and remove all members. This cannot be undone.")
        }
        .alert("Leave Guild?", isPresented: $showLeaveConfirm) {
            Button("Leave", role: .destructive) { leave() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to be re-invited or re-join to come back.")
        }
    }
    
    // MARK: - Info Row
    
    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
            Text(value)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
        }
    }
    
    // MARK: - Member Management
    
    private var memberManagement: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Manage Members")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(guildService.members.filter { $0.role != .leader }) { member in
                HStack(spacing: AppSpacing.md) {
                    Text(member.profile?.avatarEmoji ?? "?")
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.profile?.displayName ?? "Hunter")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                        Text(member.role.displayName)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Promote/demote
                    if member.role == .member {
                        Button("Promote") {
                            Task {
                                try? await guildService.promoteToOfficer(member.playerID)
                            }
                        }
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.primaryBlue)
                    } else {
                        Button("Demote") {
                            Task {
                                try? await guildService.demoteToMember(member.playerID)
                            }
                        }
                        .font(AppFonts.caption1)
                        .foregroundColor(.orange)
                    }
                    
                    // Kick
                    Button {
                        Task {
                            try? await guildService.kickMember(member.playerID)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.error)
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
            }
        }
    }
    
    // MARK: - Danger Zone
    
    private var dangerZone: some View {
        VStack(spacing: AppSpacing.md) {
            if !isLeader {
                Button {
                    showLeaveConfirm = true
                } label: {
                    Text("Leave Guild")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.error.opacity(0.15))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            } else {
                Button {
                    showDisbandConfirm = true
                } label: {
                    Text("Disband Guild")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.error.opacity(0.15))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func disband() {
        Task {
            do {
                try await guildService.disbandGuild()
                dismiss()
            } catch {
                actionError = error.localizedDescription
            }
        }
    }
    
    private func leave() {
        Task {
            do {
                try await guildService.leaveGuild()
                dismiss()
            } catch {
                actionError = error.localizedDescription
            }
        }
    }
}
