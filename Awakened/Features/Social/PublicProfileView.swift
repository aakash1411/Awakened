import SwiftUI

/// Displays a player's public profile — used for viewing friends, guild members, or own profile
struct PublicProfileView: View {
    let profile: CloudProfile
    var isOwnProfile: Bool = false
    var onAddFriend: (() -> Void)?
    var onChallenge: (() -> Void)?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header card
                    profileHeaderCard
                    
                    // Stat radar chart
                    statRadarCard
                    
                    // Stats detail
                    statBarsCard
                    
                    // Social stats
                    socialStatsCard
                    
                    // Action buttons (not shown on own profile)
                    if !isOwnProfile {
                        actionButtonsSection
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle(profile.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Profile Header
    
    private var profileHeaderCard: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar + rank badge
            ZStack {
                Circle()
                    .fill(profile.rank.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                Circle()
                    .stroke(profile.rank.color, lineWidth: 3)
                    .frame(width: 80, height: 80)
                Text(profile.avatarEmoji)
                    .font(.system(size: 36))
            }
            
            // Name + title
            VStack(spacing: 4) {
                Text(profile.displayName)
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.textPrimary)
                
                if !profile.activeTitle.isEmpty {
                    Text(profile.activeTitle)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.accentPurple)
                }
                
                if !profile.bio.isEmpty {
                    Text(profile.bio)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            
            // Rank + level bar
            HStack(spacing: AppSpacing.lg) {
                VStack(spacing: 2) {
                    Image(systemName: profile.rank.icon)
                        .font(.system(size: 20))
                        .foregroundColor(profile.rank.color)
                    Text(profile.rank.displayName)
                        .font(AppFonts.caption2)
                        .foregroundColor(profile.rank.color)
                }
                
                VStack(spacing: 2) {
                    Text("Lv. \(profile.level)")
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.textPrimary)
                    Text("\(profile.totalXP) XP")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        Text("\(profile.currentStreak)")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    Text("Streak")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Guild badge
            if let guildName = profile.guildName {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.accentCyan)
                    Text(guildName)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.accentCyan)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(AppColors.accentCyan.opacity(0.15))
                .cornerRadius(AppSpacing.buttonCornerRadius)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Stat Radar Chart
    
    private var statRadarCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Stats")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            ProfileRadarChart(
                values: profile.statLevels.map { Double($0) },
                labels: StatType.orderedCases.map(\.shortName),
                colors: StatType.orderedCases.map(\.color)
            )
            .frame(height: 200)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Stat Bars
    
    private var statBarsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            let statData: [(StatType, Int)] = [
                (.strength, profile.strengthLevel),
                (.agility, profile.agilityLevel),
                (.vitality, profile.vitalityLevel),
                (.sense, profile.senseLevel),
                (.intelligence, profile.intelligenceLevel)
            ]
            
            ForEach(statData, id: \.0) { type, level in
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: type.icon)
                        .font(.system(size: 14))
                        .foregroundColor(type.color)
                        .frame(width: 20)
                    
                    Text(type.shortName)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 30, alignment: .leading)
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppColors.surface)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(type.color)
                                .frame(width: max(0, geo.size.width * min(Double(level) / 50.0, 1.0)), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(level)")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Social Stats
    
    private var socialStatsCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Activity")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                SocialStatTile(icon: "checkmark.circle.fill", title: "Quests", value: "\(profile.questsCompleted)", color: AppColors.success)
                SocialStatTile(icon: "trophy.fill", title: "Achievements", value: "\(profile.achievementsUnlocked)", color: AppColors.accentPurple)
                SocialStatTile(icon: "flame.fill", title: "Best Streak", value: "\(profile.longestStreak)d", color: .orange)
                SocialStatTile(icon: "crossed.swords", title: "Duels", value: profile.duelRecord, color: AppColors.strengthColor)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        HStack(spacing: AppSpacing.md) {
            if let onAddFriend {
                Button(action: onAddFriend) {
                    Label("Add Friend", systemImage: "person.badge.plus")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primaryBlue)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
            
            if let onChallenge {
                Button(action: onChallenge) {
                    Label("Challenge", systemImage: "bolt.fill")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.strengthColor)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
        }
    }
}

// MARK: - Social Stat Tile

struct SocialStatTile: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(title)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.md)
        .background(color.opacity(0.08))
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Radar Chart

/// Pentagon radar chart for displaying 5 stats
struct ProfileRadarChart: View {
    let values: [Double]
    let labels: [String]
    let colors: [Color]
    var maxValue: Double = 50.0
    
    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 30
            
            ZStack {
                // Grid lines
                ForEach(1...4, id: \.self) { ring in
                    let scale = Double(ring) / 4.0
                    pentagonPath(center: center, radius: radius * scale, count: values.count)
                        .stroke(AppColors.border.opacity(0.3), lineWidth: 1)
                }
                
                // Axis lines
                ForEach(0..<values.count, id: \.self) { i in
                    let angle = angleFor(index: i, total: values.count) - .pi / 2
                    Path { p in
                        p.move(to: center)
                        p.addLine(to: CGPoint(
                            x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius
                        ))
                    }
                    .stroke(AppColors.border.opacity(0.2), lineWidth: 1)
                }
                
                // Value polygon fill
                valuePath(center: center, radius: radius)
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primaryBlue.opacity(0.3), AppColors.accentPurple.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Value polygon stroke
                valuePath(center: center, radius: radius)
                    .stroke(AppColors.primaryBlue, lineWidth: 2)
                
                // Value dots and labels
                ForEach(0..<values.count, id: \.self) { i in
                    let angle = angleFor(index: i, total: values.count) - .pi / 2
                    let normalizedValue = min(values[i] / maxValue, 1.0)
                    let dotPoint = CGPoint(
                        x: center.x + cos(angle) * radius * normalizedValue,
                        y: center.y + sin(angle) * radius * normalizedValue
                    )
                    let labelPoint = CGPoint(
                        x: center.x + cos(angle) * (radius + 20),
                        y: center.y + sin(angle) * (radius + 20)
                    )
                    
                    // Dot
                    Circle()
                        .fill(colors[i])
                        .frame(width: 8, height: 8)
                        .position(dotPoint)
                    
                    // Label
                    Text(labels[i])
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(colors[i])
                        .position(labelPoint)
                }
            }
        }
    }
    
    /// Calculate angle for a vertex
    private func angleFor(index: Int, total: Int) -> Double {
        (2 * .pi / Double(total)) * Double(index)
    }
    
    /// Create a pentagon path
    private func pentagonPath(center: CGPoint, radius: Double, count: Int) -> Path {
        Path { path in
            for i in 0..<count {
                let angle = angleFor(index: i, total: count) - .pi / 2
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }
    
    /// Create the value polygon path
    private func valuePath(center: CGPoint, radius: Double) -> Path {
        Path { path in
            for i in 0..<values.count {
                let angle = angleFor(index: i, total: values.count) - .pi / 2
                let normalizedValue = min(values[i] / maxValue, 1.0)
                let point = CGPoint(
                    x: center.x + cos(angle) * radius * normalizedValue,
                    y: center.y + sin(angle) * radius * normalizedValue
                )
                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
            }
            path.closeSubpath()
        }
    }
}
