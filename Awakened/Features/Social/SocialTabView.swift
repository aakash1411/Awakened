import SwiftUI

/// Main social tab — hub linking to friends, guild, feed, leaderboards, and duels
struct SocialTabView: View {
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var scope: CommunityScope = .forYou

    /// Community feed scopes, matching the mockup's segmented header.
    enum CommunityScope: String, CaseIterable, Identifiable {
        case forYou = "For You"
        case following = "Following"
        case groups = "Groups"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        searchField
                        scopePicker
                        if scope == .forYou && searchText.isEmpty {
                            socialStatsBanner
                        }
                        scopedLinks
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Community")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Header

    private var searchField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)
            TextField("Search posts, people, topics", text: $searchText)
                .foregroundColor(AppColors.textPrimary)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius, style: .continuous)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }

    private var scopePicker: some View {
        Picker("", selection: $scope) {
            ForEach(CommunityScope.allCases) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Nav Cards
    
    /// True when a row title matches the current search (or search is empty).
    private func matches(_ title: String) -> Bool {
        searchText.isEmpty || title.localizedCaseInsensitiveContains(searchText)
    }

    /// Hub destinations, organized by the selected scope and filtered by search.
    /// (The mockup's free-text post feed needs a posts data model; until then
    /// these tabs organize the existing social hub.)
    private var scopedLinks: some View {
        VStack(spacing: AppSpacing.sm) {
            if scope != .groups {
                if matches("Friends") { friendsLink }
                if matches("Activity Feed") { feedLink }
                if matches("Leaderboards") { leaderboardsLink }
            }
            if scope != .following {
                if matches("Guild") { guildLink }
                if matches("Duels") { duelsLink }
                if matches("Seasons") { seasonsLink }
            }
        }
    }
    
    private var friendsLink: some View {
        let subtitle = "\(appState.friendService.friendCount) friends"
        let badge = appState.friendService.pendingRequestCount
        return NavigationLink {
            FriendsListView(friendService: appState.friendService, syncEngine: appState.profileSyncEngine)
        } label: {
            SocialNavRow(icon: "person.2.fill", title: "Friends", subtitle: subtitle, badge: badge, color: AppColors.primaryBlue)
        }
    }
    
    private var feedLink: some View {
        NavigationLink {
            ActivityFeedView(feedService: appState.feedService, friendService: appState.friendService)
        } label: {
            SocialNavRow(icon: "newspaper.fill", title: "Activity Feed", subtitle: "See what your friends are up to", badge: 0, color: AppColors.success)
        }
    }
    
    private var guildLink: some View {
        let guildSubtitle = appState.guildService.myGuild?.name ?? "Join or create a guild"
        return NavigationLink {
            GuildHubView(guildService: appState.guildService, feedService: appState.feedService, guildQuestService: appState.guildQuestService)
        } label: {
            SocialNavRow(icon: "shield.lefthalf.filled", title: "Guild", subtitle: guildSubtitle, badge: 0, color: AppColors.accentCyan)
        }
    }
    
    private var leaderboardsLink: some View {
        NavigationLink {
            LeaderboardsView(leaderboardService: appState.leaderboardService, friendService: appState.friendService, guildService: appState.guildService)
        } label: {
            SocialNavRow(icon: "trophy.fill", title: "Leaderboards", subtitle: "Compete for the top spot", badge: 0, color: .orange)
        }
    }
    
    private var duelsLink: some View {
        let subtitle = "\(appState.duelService.wins)W / \(appState.duelService.losses)L"
        let badge = appState.duelService.pendingChallenges.count
        return NavigationLink {
            DuelsHubView(duelService: appState.duelService, friendService: appState.friendService)
        } label: {
            SocialNavRow(icon: "bolt.fill", title: "Duels", subtitle: subtitle, badge: badge, color: AppColors.strengthColor)
        }
    }
    
    private var seasonsLink: some View {
        let subtitle = appState.seasonService.currentSeason?.name ?? "Ranked seasons & titles"
        return NavigationLink {
            SeasonsView(seasonService: appState.seasonService)
        } label: {
            SocialNavRow(icon: "calendar.badge.clock", title: "Seasons", subtitle: subtitle, badge: 0, color: AppColors.accentPurple)
        }
    }
    
    // MARK: - Stats Banner
    
    private var socialStatsBanner: some View {
        let guildValue: String = {
            if let guild = appState.guildService.myGuild {
                return "Lv.\(guild.guildLevel)"
            }
            return "—"
        }()
        
        return HStack(spacing: 0) {
            SocialQuickStat(value: "\(appState.friendService.friendCount)", label: "Friends", icon: "person.2.fill", color: AppColors.primaryBlue)
            
            Divider()
                .frame(height: 30)
                .background(AppColors.border)
            
            SocialQuickStat(value: guildValue, label: "Guild", icon: "shield.fill", color: AppColors.accentCyan)
            
            Divider()
                .frame(height: 30)
                .background(AppColors.border)
            
            SocialQuickStat(value: "\(appState.duelService.wins)", label: "Wins", icon: "bolt.fill", color: AppColors.strengthColor)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
}

// MARK: - Social Nav Row

/// Reusable row for social navigation cards
struct SocialNavRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let badge: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            if badge > 0 {
                Text("\(badge)")
                    .font(AppFonts.caption1)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(AppColors.error)
                    .cornerRadius(10)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Quick Stat

struct SocialQuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
