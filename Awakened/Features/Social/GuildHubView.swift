import SwiftUI

/// Main guild view — shows current guild details or guild browser if not in a guild
struct GuildHubView: View {
    @ObservedObject var guildService: GuildService
    @ObservedObject var feedService: FeedService
    @ObservedObject var guildQuestService: GuildQuestService
    
    @State private var showingCreateGuild = false
    @State private var showingBrowser = false
    @State private var showingSettings = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            if guildService.isLoading {
                ProgressView()
                    .tint(AppColors.primaryBlue)
            } else if let guild = guildService.myGuild {
                guildDetailView(guild)
            } else {
                noGuildView
            }
        }
        .navigationTitle(guildService.myGuild?.name ?? "Guild")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await guildService.fetchMyGuild()
        }
        .sheet(isPresented: $showingCreateGuild) {
            NavigationStack {
                CreateGuildView(guildService: guildService)
            }
        }
        .sheet(isPresented: $showingBrowser) {
            NavigationStack {
                GuildBrowserView(guildService: guildService)
            }
        }
        .sheet(isPresented: $showingSettings) {
            if guildService.myGuild != nil {
                NavigationStack {
                    GuildSettingsView(guildService: guildService)
                }
            }
        }
    }
    
    // MARK: - Guild Detail
    
    private func guildDetailView(_ guild: Guild) -> some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Guild header card
                guildHeaderCard(guild)
                
                // Guild quests link
                NavigationLink {
                    GuildQuestsView(questService: guildQuestService, guildService: guildService)
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "flag.2.crossed.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.orange)
                            .frame(width: 36, height: 36)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(8)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Guild Quests")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text("\(guildQuestService.activeQuests.count) active")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                }
                
                // Members section
                membersSection
                
                // Guild stats
                guildStatsCard(guild)
                
                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.md)
        }
        .refreshable {
            await guildService.fetchMyGuild()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if guild.leaderID == UserDefaults.standard.string(forKey: "currentPlayerId") {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Guild Header
    
    private func guildHeaderCard(_ guild: Guild) -> some View {
        VStack(spacing: AppSpacing.md) {
            // Emblem + name
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(guild.bannerColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                    Circle()
                        .stroke(guild.bannerColor, lineWidth: 2)
                        .frame(width: 60, height: 60)
                    Text(guild.emblem)
                        .font(.system(size: 28))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(guild.name)
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.textPrimary)
                    
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: guild.guildRank.icon)
                            .foregroundColor(guild.guildRank.color)
                        Text(guild.guildRank.rawValue)
                            .font(AppFonts.caption1)
                            .foregroundColor(guild.guildRank.color)
                        Text("Guild")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
            }
            
            // Level progress
            VStack(spacing: AppSpacing.xs) {
                HStack {
                    Text("Guild Lv. \(guild.guildLevel)")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(guild.totalGuildXP) / \(guild.xpForNextLevel) XP")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.border)
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(guild.bannerColor)
                            .frame(width: max(0, geo.size.width * guild.levelProgress), height: 6)
                    }
                }
                .frame(height: 6)
            }
            
            // Stats row
            HStack(spacing: AppSpacing.lg) {
                GuildStatPill(icon: "person.2.fill", value: "\(guild.memberCount)/\(guild.maxMembers)", label: "Members")
                GuildStatPill(icon: "bolt.fill", value: "+\(guild.xpBonusPercent)%", label: "XP Bonus")
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Members Section
    
    private var membersSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Members")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(guildService.members) { member in
                GuildMemberRow(member: member)
            }
        }
    }
    
    // MARK: - Guild Stats
    
    private func guildStatsCard(_ guild: Guild) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Guild Info")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            if !guild.description.isEmpty {
                Text(guild.description)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack {
                Text("Created")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text(guild.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            HStack {
                Text("Min Rank")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                Spacer()
                Text(guild.minRankToJoin.displayName)
                    .font(AppFonts.caption1)
                    .foregroundColor(guild.minRankToJoin.color)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - No Guild View
    
    private var noGuildView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppColors.accentCyan.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 44))
                    .foregroundColor(AppColors.accentCyan)
            }
            
            Text("No Guild Yet")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Create your own guild or join an existing one to team up with other hunters!")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            
            VStack(spacing: AppSpacing.md) {
                Button {
                    showingCreateGuild = true
                } label: {
                    Label("Create Guild", systemImage: "plus.circle.fill")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primaryBlue)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                Button {
                    showingBrowser = true
                } label: {
                    Label("Browse Guilds", systemImage: "magnifyingglass")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primaryBlue.opacity(0.15))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct GuildStatPill: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(AppColors.accentCyan)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textPrimary)
                Text(label)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

struct GuildMemberRow: View {
    let member: GuildMember
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Role icon
            Image(systemName: member.role.icon)
                .font(.system(size: 14))
                .foregroundColor(member.role == .leader ? .orange : member.role == .officer ? AppColors.primaryBlue : AppColors.textTertiary)
                .frame(width: 20)
            
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.surface)
                    .frame(width: 36, height: 36)
                Text(member.profile?.avatarEmoji ?? "?")
                    .font(.system(size: 16))
            }
            
            // Name + rank
            VStack(alignment: .leading, spacing: 2) {
                Text(member.profile?.displayName ?? "Hunter")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Text("Lv. \(member.profile?.level ?? 1) • \(member.totalXPContribution) XP contributed")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Text(member.role.displayName)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
