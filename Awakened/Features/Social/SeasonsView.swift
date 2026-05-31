import SwiftUI

/// Ranked seasons view — current season progress, tier, and leaderboard
struct SeasonsView: View {
    @ObservedObject var seasonService: SeasonService
    
    @State private var showLeaderboard = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    if seasonService.isLoading {
                        ProgressView()
                            .tint(AppColors.primaryBlue)
                            .padding(.top, AppSpacing.xxl)
                    } else if let season = seasonService.currentSeason {
                        seasonHeader(season)
                        
                        if let entry = seasonService.myEntry {
                            tierProgressCard(entry)
                            seasonStatsCard(entry)
                        }
                        
                        tierRoadmap
                        
                        // Leaderboard button
                        Button {
                            showLeaderboard = true
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(.orange)
                                Text("Season Leaderboard")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                        }
                        
                        // Earned titles
                        if !seasonService.earnedTitles.isEmpty {
                            titlesSection
                        }
                    } else {
                        noSeasonView
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Seasons")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await seasonService.fetchCurrentSeason()
            seasonService.loadEarnedTitles()
        }
        .sheet(isPresented: $showLeaderboard) {
            NavigationStack {
                SeasonLeaderboardView(seasonService: seasonService)
            }
        }
    }
    
    // MARK: - Season Header
    
    private func seasonHeader(_ season: Season) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Season \(season.seasonNumber)")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.accentPurple)
            Text(season.name)
                .font(AppFonts.title2)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)
            Text("\(season.daysRemaining) days remaining")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Tier Progress
    
    private func tierProgressCard(_ entry: SeasonEntry) -> some View {
        VStack(spacing: AppSpacing.md) {
            // Current tier
            HStack {
                Image(systemName: entry.seasonTier.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(entry.seasonTier.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.seasonTier.displayName)
                        .font(AppFonts.title3)
                        .foregroundColor(entry.seasonTier.color)
                    Text(entry.seasonTier.title.isEmpty ? "Keep earning XP!" : entry.seasonTier.title)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.seasonXP)")
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Season XP")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Progress to next tier
            if let nextTier = entry.seasonTier.next {
                VStack(spacing: AppSpacing.xs) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.border)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [entry.seasonTier.color, nextTier.color],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * entry.seasonTier.progress(currentXP: entry.seasonXP)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack {
                        Text(entry.seasonTier.displayName)
                            .font(AppFonts.caption2)
                            .foregroundColor(entry.seasonTier.color)
                        Spacer()
                        Text("\(nextTier.minXP - entry.seasonXP) XP to \(nextTier.displayName)")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            } else {
                Text("Maximum tier reached!")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.accentPurple)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Season Stats
    
    private func seasonStatsCard(_ entry: SeasonEntry) -> some View {
        HStack(spacing: 0) {
            SeasonStatItem(value: "\(entry.seasonXP)", label: "XP", color: AppColors.primaryBlue)
            Divider().frame(height: 30).background(AppColors.border)
            SeasonStatItem(value: "\(entry.questsCompleted)", label: "Quests", color: AppColors.success)
            Divider().frame(height: 30).background(AppColors.border)
            SeasonStatItem(value: "\(entry.duelsWon)", label: "Duel Wins", color: AppColors.strengthColor)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Tier Roadmap
    
    private var tierRoadmap: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Tier Rewards")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(SeasonTier.allCases.filter { $0 != .unranked }) { tier in
                let isReached = (seasonService.myEntry?.seasonXP ?? 0) >= tier.minXP
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: tier.icon)
                        .font(.system(size: 16))
                        .foregroundColor(isReached ? tier.color : AppColors.textTertiary)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tier.displayName)
                            .font(AppFonts.body)
                            .foregroundColor(isReached ? tier.color : AppColors.textSecondary)
                        Text(tier.title)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(tier.xpReward) XP")
                            .font(AppFonts.caption1)
                            .foregroundColor(isReached ? AppColors.primaryBlue : AppColors.textTertiary)
                        Text("\(tier.minXP) XP")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    if isReached {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.success)
                            .font(.system(size: 14))
                    }
                }
                .padding(AppSpacing.sm)
                .background(isReached ? tier.color.opacity(0.05) : Color.clear)
                .cornerRadius(8)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Titles
    
    private var titlesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Earned Titles")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            ForEach(seasonService.earnedTitles, id: \.self) { title in
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(title)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - No Season
    
    private var noSeasonView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text("No Active Season")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.textSecondary)
            Text("Check back soon — a new season will start shortly!")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xxl)
    }
}

// MARK: - Supporting Views

struct SeasonStatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Season Leaderboard

struct SeasonLeaderboardView: View {
    @ObservedObject var seasonService: SeasonService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                LazyVStack(spacing: AppSpacing.xs) {
                    ForEach(Array(seasonService.leaderboard.enumerated()), id: \.element.id) { index, entry in
                        HStack(spacing: AppSpacing.md) {
                            // Position
                            positionBadge(index + 1)
                            
                            // Avatar + name
                            Text(entry.profile?.avatarEmoji ?? "?")
                                .font(.system(size: 20))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.profile?.displayName ?? "Hunter")
                                    .font(AppFonts.body)
                                    .foregroundColor(entry.playerID == UserDefaults.standard.string(forKey: "currentPlayerId") ? AppColors.primaryBlue : AppColors.textPrimary)
                                HStack(spacing: AppSpacing.xxs) {
                                    Image(systemName: entry.seasonTier.icon)
                                        .font(.system(size: 10))
                                    Text(entry.seasonTier.displayName)
                                        .font(AppFonts.caption2)
                                }
                                .foregroundColor(entry.seasonTier.color)
                            }
                            
                            Spacer()
                            
                            Text("\(entry.seasonXP) XP")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .navigationTitle("Season Leaderboard")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .task {
            await seasonService.fetchLeaderboard()
        }
    }
    
    private func positionBadge(_ pos: Int) -> some View {
        Group {
            switch pos {
            case 1:
                Image(systemName: "crown.fill")
                    .foregroundColor(Color(hex: "FFD700"))
            case 2:
                Image(systemName: "medal.fill")
                    .foregroundColor(Color(hex: "C0C0C0"))
            case 3:
                Image(systemName: "medal")
                    .foregroundColor(Color(hex: "CD7F32"))
            default:
                Text("#\(pos)")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(width: 28)
    }
}
