import SwiftUI

/// View showing active and completed guild quests with contribution tracking
struct GuildQuestsView: View {
    @ObservedObject var questService: GuildQuestService
    @ObservedObject var guildService: GuildService
    
    @State private var selectedTab = 0
    @State private var showingCreateQuest = false
    @State private var selectedQuest: GuildQuest?
    
    private var guildID: String { guildService.myGuild?.id ?? "" }
    
    private var isLeaderOrOfficer: Bool {
        guard let myID = UserDefaults.standard.string(forKey: "currentPlayerId") else { return false }
        guard let guild = guildService.myGuild else { return false }
        if guild.leaderID == myID { return true }
        return guildService.members.first(where: { $0.playerID == myID })?.role == .officer
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Picker("", selection: $selectedTab) {
                    Text("Active (\(questService.activeQuests.count))").tag(0)
                    Text("Completed").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.md)
                
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        if selectedTab == 0 {
                            if questService.activeQuests.isEmpty {
                                emptyState
                            } else {
                                ForEach(questService.activeQuests) { quest in
                                    GuildQuestCard(quest: quest)
                                        .onTapGesture { selectedQuest = quest }
                                }
                            }
                        } else {
                            ForEach(questService.completedQuests) { quest in
                                GuildQuestCard(quest: quest)
                                    .onTapGesture { selectedQuest = quest }
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .navigationTitle("Guild Quests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isLeaderOrOfficer {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateQuest = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
            }
        }
        .task {
            await questService.fetchActiveQuests(guildID: guildID)
            await questService.fetchCompletedQuests(guildID: guildID)
        }
        .sheet(isPresented: $showingCreateQuest) {
            NavigationStack {
                CreateGuildQuestView(
                    questService: questService,
                    guildID: guildID,
                    memberCount: guildService.members.count
                )
            }
        }
        .sheet(item: $selectedQuest) { quest in
            NavigationStack {
                GuildQuestDetailView(quest: quest, questService: questService)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "flag.2.crossed")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            Text("No active guild quests")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            if isLeaderOrOfficer {
                Text("Tap + to create a new guild quest")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl)
    }
}

// MARK: - Guild Quest Card

struct GuildQuestCard: View {
    let quest: GuildQuest
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: quest.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(quest.color)
                    .frame(width: 36, height: 36)
                    .background(quest.color.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(quest.description)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if quest.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.success)
                } else {
                    Text(quest.timeRemaining)
                        .font(AppFonts.caption2)
                        .foregroundColor(quest.isExpired ? AppColors.error : AppColors.textTertiary)
                }
            }
            
            // Progress bar
            VStack(spacing: AppSpacing.xxs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppColors.border)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(quest.isCompleted ? AppColors.success : quest.color)
                            .frame(width: max(0, geo.size.width * quest.progress), height: 8)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text("\(quest.currentValue) / \(quest.targetValue)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textSecondary)
                    Spacer()
                    Text("\(Int(quest.progress * 100))%")
                        .font(AppFonts.caption2)
                        .foregroundColor(quest.color)
                }
            }
            
            // Rewards
            HStack(spacing: AppSpacing.md) {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.accentCyan)
                    Text("+\(quest.guildXPReward) Guild XP")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.accentCyan)
                }
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.primaryBlue)
                    Text("+\(quest.individualXPBonus) XP each")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Create Guild Quest View

struct CreateGuildQuestView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var questService: GuildQuestService
    let guildID: String
    let memberCount: Int
    
    @State private var selectedType: GuildQuestType = .totalXP
    @State private var isCreating = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    Text("Select a quest type for the guild to tackle together.")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    ForEach(GuildQuestType.allCases) { type in
                        Button {
                            selectedType = type
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(type.color)
                                    .frame(width: 36, height: 36)
                                    .background(type.color.opacity(0.15))
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(type.questTitle)
                                        .font(AppFonts.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text(type.questDescription)
                                        .font(AppFonts.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                
                                Spacer()
                                
                                if selectedType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(type.color)
                                }
                            }
                            .padding(AppSpacing.md)
                            .background(selectedType == type ? type.color.opacity(0.08) : AppColors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                                    .stroke(selectedType == type ? type.color : Color.clear, lineWidth: 2)
                            )
                            .cornerRadius(AppSpacing.cardCornerRadius)
                        }
                    }
                    
                    // Preview
                    let preview = GuildQuest.weeklyTemplate(guildID: guildID, type: selectedType, memberCount: memberCount)
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Quest Preview")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                        HStack {
                            Text("Target:")
                            Spacer()
                            Text("\(preview.targetValue)")
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        HStack {
                            Text("Guild XP Reward:")
                            Spacer()
                            Text("+\(preview.guildXPReward)")
                                .foregroundColor(AppColors.accentCyan)
                        }
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        HStack {
                            Text("Individual Bonus:")
                            Spacer()
                            Text("+\(preview.individualXPBonus) XP")
                                .foregroundColor(AppColors.primaryBlue)
                        }
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        HStack {
                            Text("Duration:")
                            Spacer()
                            Text("7 days")
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    Button {
                        isCreating = true
                        Task {
                            _ = try? await questService.createQuest(guildID: guildID, type: selectedType, memberCount: memberCount)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if isCreating { ProgressView().tint(.white) }
                            Text(isCreating ? "Creating..." : "Create Quest")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.primaryBlue)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(isCreating)
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("New Guild Quest")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - Guild Quest Detail View

struct GuildQuestDetailView: View {
    let quest: GuildQuest
    @ObservedObject var questService: GuildQuestService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Quest info
                    VStack(spacing: AppSpacing.md) {
                        Image(systemName: quest.icon)
                            .font(.system(size: 36))
                            .foregroundColor(quest.color)
                        
                        Text(quest.title)
                            .font(AppFonts.title2)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text(quest.description)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                        
                        // Progress
                        VStack(spacing: AppSpacing.xs) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppColors.border)
                                        .frame(height: 12)
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(quest.isCompleted ? AppColors.success : quest.color)
                                        .frame(width: max(0, geo.size.width * quest.progress), height: 12)
                                }
                            }
                            .frame(height: 12)
                            
                            HStack {
                                Text("\(quest.currentValue) / \(quest.targetValue)")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Text("\(Int(quest.progress * 100))%")
                                    .font(AppFonts.headline)
                                    .foregroundColor(quest.color)
                            }
                        }
                        
                        Text(quest.timeRemaining)
                            .font(AppFonts.caption1)
                            .foregroundColor(quest.isCompleted ? AppColors.success : (quest.isExpired ? AppColors.error : AppColors.textTertiary))
                    }
                    .padding(AppSpacing.cardPadding)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Contributions
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Contributions")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if questService.currentContributions.isEmpty {
                            Text("No contributions yet")
                                .font(AppFonts.caption1)
                                .foregroundColor(AppColors.textTertiary)
                                .frame(maxWidth: .infinity)
                                .padding(AppSpacing.md)
                        } else {
                            ForEach(questService.currentContributions) { contribution in
                                HStack(spacing: AppSpacing.md) {
                                    Text(contribution.profile?.avatarEmoji ?? "?")
                                        .font(.system(size: 20))
                                    
                                    Text(contribution.profile?.displayName ?? "Hunter")
                                        .font(AppFonts.body)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("+\(contribution.contributionValue)")
                                        .font(AppFonts.headline)
                                        .foregroundColor(quest.color)
                                }
                                .padding(AppSpacing.sm)
                                .background(AppColors.surface)
                                .cornerRadius(AppSpacing.cardCornerRadius)
                            }
                        }
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Quest Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .task {
            await questService.fetchContributions(questID: quest.id)
        }
    }
}
