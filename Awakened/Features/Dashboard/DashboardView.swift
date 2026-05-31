import SwiftUI
import SwiftData

/// Main dashboard view showing player stats and progress
struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    @State private var showWeeklyRecap = false
    @State private var weeklyRecap: WeeklyRecap?
    @State private var selectedStat: StatType?
    
    private var player: Player? {
        players.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                if let player = player {
                    ScrollView {
                        VStack(spacing: AppSpacing.lg) {
                            // Penalty Zone Warning
                            if player.isInPenaltyZone {
                                PenaltyZoneWarning()
                                    .padding(.horizontal, AppSpacing.screenHorizontal)
                            }
                            
                            // 1. Hero header — greeting, level/rank, total power, EXP
                            HomeHeroCard(player: player)
                                .padding(.horizontal, AppSpacing.screenHorizontal)
                            
                            // 2. Five Fields Overview (pentagon radar)
                            FiveFieldsOverviewCard(player: player) { statType in
                                selectedStat = statType
                            }
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                            
                            // 3. Daily Quests
                            DailyQuestCard(quests: player.todayQuests)
                                .padding(.horizontal, AppSpacing.screenHorizontal)
                            
                            // 4. Streak Stats
                            StreakCard(player: player)
                                .padding(.horizontal, AppSpacing.screenHorizontal)
                            
                            // 5. Goal Progress
                            if let syncEngine = appState.healthSyncEngine {
                                GoalProgressCard(player: player, syncEngine: syncEngine)
                                    .padding(.horizontal, AppSpacing.screenHorizontal)
                            }
                            
                            Spacer(minLength: AppSpacing.xxl)
                        }
                        .padding(.top, AppSpacing.md)
                    }
                    .refreshable {
                        await appState.healthSyncEngine?.syncAll()
                    }
                } else {
                    // No player - should not happen after onboarding
                    VStack(spacing: AppSpacing.lg) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text("No player found")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppSpacing.sm) {
                        // Sync status
                        if appState.healthSyncEngine?.isSyncing == true {
                            ProgressView()
                                .tint(AppColors.primaryBlue)
                                .scaleEffect(0.7)
                        }
                        
                        Button {
                            // TODO: Show notifications
                        } label: {
                            Image(systemName: "bell.fill")
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showWeeklyRecap) {
                if let recap = weeklyRecap {
                    WeeklyRecapView(recap: recap)
                }
            }
            .onAppear {
                checkWeeklyRecap()
            }
            .navigationDestination(item: $selectedStat) { statType in
                switch statType {
                case .strength:
                    WorkoutsView()
                case .vitality:
                    CardioView()
                case .agility:
                    AgilityView()
                case .sense:
                    SenseView()
                case .intelligence:
                    IntelligenceView()
                }
            }
        }
    }
    
    /// Show weekly recap sheet on Monday if not already shown
    private func checkWeeklyRecap() {
        guard let player = player, let syncEngine = appState.healthSyncEngine else { return }
        let recapService = WeeklyRecapService(modelContext: modelContext)
        guard recapService.shouldShowRecap else { return }
        weeklyRecap = recapService.generateRecap(for: player, syncEngine: syncEngine)
        recapService.markRecapShown()
        showWeeklyRecap = true
    }
}

// MARK: - Home Hero Card

/// Anime-mockup home header: greeting + avatar, level/rank, total power, EXP bar.
struct HomeHeroCard: View {
    let player: Player

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning,"
        case 12..<17: return "Good afternoon,"
        case 17..<22: return "Good evening,"
        default: return "Good night,"
        }
    }

    private var totalPower: Int {
        player.sortedStats.reduce(0) { $0 + $1.effectiveLevel }
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Greeting + avatar
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    Text(player.name)
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.textPrimary)
                    Text("The shadow monarch never stops.")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }

                Spacer()

                // Avatar placeholder — drop in character art asset later.
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentPurple, AppColors.primaryBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white.opacity(0.9))
                }
                .overlay(
                    Circle().stroke(AppColors.accentPurple.opacity(0.5), lineWidth: 2)
                )
            }

            // Level / Rank + Total Power
            HStack(spacing: AppSpacing.md) {
                statBlock(title: "LEVEL", value: "\(player.level)", subtitle: player.rank.displayName, color: player.rank.color)

                Rectangle()
                    .fill(AppColors.border)
                    .frame(width: 1, height: 36)

                statBlock(title: "TOTAL POWER", value: "\(totalPower)", subtitle: "Across five fields", color: AppColors.accentPurple)

                Spacer()
            }

            // EXP bar
            VStack(alignment: .leading, spacing: 4) {
                XPProgressBar(progress: player.levelProgress, height: 6, showShine: true)
                Text("EXP \(player.xpProgressInCurrentLevel) / \(player.xpNeededForNextLevel)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [AppColors.surface, AppColors.surfaceElevated],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.accentPurple.opacity(0.35), lineWidth: 1)
        )
    }

    private func statBlock(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(AppColors.textTertiary)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Text(subtitle)
                .font(AppFonts.caption2)
                .foregroundColor(color)
        }
    }
}

// MARK: - Five Fields Overview Card

/// Titled card wrapping the pentagon radar for the home screen.
struct FiveFieldsOverviewCard: View {
    let player: Player
    var onStatTap: ((StatType) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Five Fields Overview")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)

            RadarChartView(stats: player.sortedStats) { statType in
                onStatTap?(statType)
            }
            .frame(height: 260)
        }
        .padding(AppSpacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Player Level Card

struct PlayerLevelCard: View {
    let player: Player
    
    /// Approximate XP gained today from completed quests
    private var todayXP: Int {
        player.todayQuests.filter(\.isCompleted).reduce(0) { $0 + $1.xpReward }
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            // Top row: Level + Job/Title + AP
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                // Level number — prominent like the status window
                VStack(spacing: 0) {
                    Text("\(player.level)")
                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("LEVEL")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(width: 64)
                
                // Job + Title + Rank
                VStack(alignment: .leading, spacing: 4) {
                    // Job (Hunter Class)
                    HStack(spacing: 4) {
                        Text("JOB:")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AppColors.textTertiary)
                        if let hunterClass = player.hunterClass {
                            Text(hunterClass.displayName)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(hunterClass.color)
                        } else {
                            Text("None")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    // Title
                    HStack(spacing: 4) {
                        Text("TITLE:")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AppColors.textTertiary)
                        Text(player.currentTitle?.name ?? "None")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(player.currentTitle != nil ? AppColors.accentCyan : AppColors.textSecondary)
                    }
                    
                    // Rank
                    Text(player.rank.displayName)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(player.rank.color)
                }
                
                Spacer()
                
                // XP gained today + Available points
                VStack(alignment: .trailing, spacing: 4) {
                    Text("+\(todayXP) XP")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.accentCyan)
                    
                    Text("today")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    
                }
            }
            
            // XP Progress bar
            HStack(spacing: AppSpacing.sm) {
                XPProgressBar(
                    progress: player.levelProgress,
                    height: 6,
                    showShine: true
                )
                
                Text("\(player.xpProgressInCurrentLevel)/\(player.xpNeededForNextLevel)")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.textTertiary)
                    .fixedSize()
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.primaryBlue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Penalty Zone Warning

struct PenaltyZoneWarning: View {
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(AppColors.error)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("PENALTY ZONE")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.error)
                
                Text("Complete the penalty challenge to restore full XP gains")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.error.opacity(0.1))
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(AppColors.error.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Daily Quest Card

struct DailyQuestCard: View {
    let quests: [Quest]
    @State private var isExpanded = false
    
    private var completedCount: Int {
        quests.filter { $0.isCompleted }.count
    }
    
    private var totalCount: Int {
        quests.count
    }
    
    /// Quests to display based on expanded state
    private var visibleQuests: [Quest] {
        isExpanded ? Array(quests) : Array(quests.prefix(3))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Today's Quests")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount) Completed")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            if quests.isEmpty {
                Text("No quests for today")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.lg)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(visibleQuests) { quest in
                        QuestPreviewRow(quest: quest)
                    }
                    
                    if quests.count > 3 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(isExpanded ? "Show less" : "+\(quests.count - 3) more")
                                    .font(AppFonts.caption1)
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(AppColors.primaryBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.top, AppSpacing.xs)
                        }
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Quest Preview Row

struct QuestPreviewRow: View {
    let quest: Quest
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Status icon
            Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : quest.category.icon)
                .foregroundColor(quest.isCompleted ? AppColors.success : AppColors.textTertiary)
                .frame(width: 24)
            
            // Quest info
            VStack(alignment: .leading, spacing: 2) {
                Text(quest.title)
                    .font(AppFonts.subheadline)
                    .foregroundColor(quest.isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                    .strikethrough(quest.isCompleted)
                
                Text(quest.progressText)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Progress
            CircularProgressBar(
                progress: quest.progress,
                color: quest.isCompleted ? AppColors.success : AppColors.primaryBlue,
                lineWidth: 3,
                showLabel: false
            )
            .frame(width: 30, height: 30)
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: AppSpacing.lg) {
            // Current streak
            VStack(spacing: AppSpacing.xxs) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(player.currentStreak > 0 ? AppColors.warning : AppColors.textTertiary)
                    
                    Text("\(player.currentStreak)")
                        .font(AppFonts.statValueSmall)
                        .foregroundColor(player.currentStreak > 0 ? AppColors.warning : AppColors.textTertiary)
                }
                
                Text("Day Streak")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // Streak bonus
            VStack(spacing: AppSpacing.xxs) {
                Text("+\(player.streakBonusPercent)%")
                    .font(AppFonts.headline)
                    .foregroundColor(player.streakBonusPercent > 0 ? AppColors.success : AppColors.textTertiary)
                
                Text("XP Bonus")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Divider()
                .frame(height: 40)
            
            // Longest streak
            VStack(spacing: AppSpacing.xxs) {
                Text("\(player.longestStreak)")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("Best Streak")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Goal Progress Card

struct GoalProgressCard: View {
    let player: Player
    @ObservedObject var syncEngine: HealthSyncEngine
    
    private var goal: FitnessGoal {
        FitnessGoal.currentGoal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Image(systemName: goal.icon)
                    .foregroundColor(AppColors.primaryBlue)
                Text(goal.title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textSecondary)
                Spacer()
                NavigationLink {
                    goalDestination
                } label: {
                    Text("Details")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            
            // Goal-specific content
            switch goal {
            case .strength:
                strengthProgress
            case .weightLoss:
                weightLossProgress
            case .cardio:
                cardioProgress
            case .flexibility:
                flexibilityProgress
            case .balance:
                balanceProgress
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Strength Progress
    
    private var strengthProgress: some View {
        let strStat = player.stat(for: .strength)
        return VStack(spacing: AppSpacing.sm) {
            HStack {
                progressItem(
                    label: "STR Level",
                    value: "\(strStat?.effectiveLevel ?? 0)",
                    color: AppColors.strengthColor
                )
                progressItem(
                    label: "Workouts Today",
                    value: "\(syncEngine.todayWorkoutCount)",
                    color: AppColors.primaryBlue
                )
                progressItem(
                    label: "Active Cal",
                    value: String(format: "%.0f", syncEngine.todayActiveEnergy),
                    color: AppColors.warning
                )
            }
            
            // Strength XP bar
            if let stat = strStat {
                HStack(spacing: AppSpacing.sm) {
                    Text("STR XP")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    XPProgressBar(
                        progress: stat.levelProgress,
                        height: 4,
                        showShine: false
                    )
                    Text("Lv.\(stat.effectiveLevel)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.strengthColor)
                }
            }
        }
    }
    
    // MARK: - Weight Loss Progress
    
    private var weightLossProgress: some View {
        let latestWeights = player.bodyMeasurements
            .filter { $0.typeRaw == BodyMeasurementType.weight.rawValue }
            .sorted { $0.date > $1.date }
        let current = latestWeights.first?.value
        let previous = latestWeights.dropFirst().first?.value
        let change: Double? = if let c = current, let p = previous { c - p } else { nil }
        
        return VStack(spacing: AppSpacing.sm) {
            HStack {
                progressItem(
                    label: "Weight",
                    value: current.map { String(format: "%.1f kg", $0) } ?? "—",
                    color: AppColors.vitalityColor
                )
                progressItem(
                    label: "Change",
                    value: change.map { String(format: "%+.1f kg", $0) } ?? "—",
                    color: change.map { $0 <= 0 ? AppColors.success : AppColors.error } ?? AppColors.textTertiary
                )
                progressItem(
                    label: "Calories",
                    value: String(format: "%.0f", syncEngine.todayActiveEnergy),
                    color: AppColors.warning
                )
            }
            
            HStack(spacing: AppSpacing.sm) {
                Text("Steps")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
                GeometryReader { geo in
                    let progress = min(Double(syncEngine.todaySteps) / 10000.0, 1.0)
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColors.surface)
                            .frame(height: 4)
                        Capsule()
                            .fill(AppColors.agilityColor)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
                Text("\(syncEngine.todaySteps)")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.agilityColor)
                    .fixedSize()
            }
        }
    }
    
    // MARK: - Cardio Progress
    
    private var cardioProgress: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                progressItem(
                    label: "Distance",
                    value: String(format: "%.1f km", syncEngine.weeklyCardioDistance),
                    color: AppColors.vitalityColor
                )
                progressItem(
                    label: "Sessions",
                    value: "\(syncEngine.weeklyCardioSessions)",
                    color: AppColors.primaryBlue
                )
                progressItem(
                    label: "Minutes",
                    value: String(format: "%.0f", syncEngine.weeklyCardioMinutes),
                    color: AppColors.warning
                )
            }
            
            HStack(spacing: AppSpacing.sm) {
                Text("VIT XP")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
                if let stat = player.stat(for: .vitality) {
                    XPProgressBar(
                        progress: stat.levelProgress,
                        height: 4,
                        showShine: false
                    )
                    Text("Lv.\(stat.effectiveLevel)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.vitalityColor)
                }
            }
        }
    }
    
    // MARK: - Flexibility / Mind & Body Progress
    
    private var flexibilityProgress: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                progressItem(
                    label: "Meditation",
                    value: String(format: "%.0f min", syncEngine.todayMindfulMinutes),
                    color: AppColors.senseColor
                )
                progressItem(
                    label: "Weekly",
                    value: String(format: "%.0f min", syncEngine.weeklyMeditationMinutes),
                    color: AppColors.senseColor.opacity(0.7)
                )
                progressItem(
                    label: "Sleep",
                    value: String(format: "%.1f hr", syncEngine.todaySleepHours),
                    color: AppColors.intelligenceColor
                )
            }
            
            HStack(spacing: AppSpacing.sm) {
                Text("SEN XP")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
                if let stat = player.stat(for: .sense) {
                    XPProgressBar(
                        progress: stat.levelProgress,
                        height: 4,
                        showShine: false
                    )
                    Text("Lv.\(stat.effectiveLevel)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.senseColor)
                }
            }
        }
    }
    
    // MARK: - Balance Progress
    
    private var balanceProgress: some View {
        let statsList = StatType.orderedCases
        return HStack {
            ForEach(statsList) { statType in
                let stat = player.stat(for: statType)
                VStack(spacing: 2) {
                    Text(statType.shortName)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(statType.color)
                    Text("\(stat?.effectiveLevel ?? 0)")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func progressItem(label: String, value: String, color: Color) -> some View {
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
    
    @ViewBuilder
    private var goalDestination: some View {
        switch goal {
        case .strength:
            WorkoutsView()
        case .weightLoss:
            BodyTrackingView()
        case .cardio:
            CardioView()
        case .flexibility:
            SenseView()
        case .balance:
            WorkoutsView()
        }
    }
}

#Preview("Dashboard") {
    DashboardView()
        .environmentObject(AppState())
        .modelContainer(for: [Player.self, Stat.self, Quest.self, SyncRecord.self, Exercise.self, WorkoutSession.self, WorkoutSet.self, WorkoutTemplate.self, PersonalRecord.self, ReadingEntry.self, LearningSession.self, Achievement.self, FoodItem.self, MealEntry.self, BodyMeasurement.self], inMemory: true)
}
