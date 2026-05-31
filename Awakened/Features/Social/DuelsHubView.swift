import SwiftUI

/// Hub for PvP duels — active, pending, and history
struct DuelsHubView: View {
    @ObservedObject var duelService: DuelService
    @ObservedObject var friendService: FriendService
    
    @State private var showingCreateDuel = false
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Stats banner
                HStack(spacing: AppSpacing.xl) {
                    DuelStatBadge(value: "\(duelService.wins)", label: "Wins", color: AppColors.success)
                    DuelStatBadge(value: "\(duelService.losses)", label: "Losses", color: AppColors.error)
                    DuelStatBadge(value: winRate, label: "Win Rate", color: AppColors.primaryBlue)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Active (\(duelService.activeDuels.count))").tag(0)
                    Text("Challenges (\(duelService.pendingChallenges.count))").tag(1)
                    Text("History").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.md)
                
                // Content
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        switch selectedTab {
                        case 0: activeSection
                        case 1: challengesSection
                        default: historySection
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .navigationTitle("Duels")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateDuel = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
        .task {
            await duelService.refreshAll()
        }
        .sheet(isPresented: $showingCreateDuel) {
            NavigationStack {
                CreateDuelView(duelService: duelService, friendService: friendService)
            }
        }
    }
    
    // MARK: - Active Duels
    
    private var activeSection: some View {
        Group {
            if duelService.activeDuels.isEmpty {
                emptyState(icon: "bolt.slash", message: "No active duels", subtitle: "Challenge a friend to get started!")
            } else {
                ForEach(duelService.activeDuels) { duel in
                    DuelCard(duel: duel, myPlayerID: UserDefaults.standard.string(forKey: "currentPlayerId") ?? "")
                }
            }
        }
    }
    
    // MARK: - Challenges
    
    private var challengesSection: some View {
        Group {
            if duelService.pendingChallenges.isEmpty {
                emptyState(icon: "bell.slash", message: "No pending challenges", subtitle: "")
            } else {
                ForEach(duelService.pendingChallenges) { duel in
                    VStack(spacing: AppSpacing.sm) {
                        DuelCard(duel: duel, myPlayerID: UserDefaults.standard.string(forKey: "currentPlayerId") ?? "")
                        
                        HStack(spacing: AppSpacing.md) {
                            Button {
                                Task { try? await duelService.respondToChallenge(duel, accept: true) }
                            } label: {
                                Text("Accept")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColors.success)
                                    .cornerRadius(AppSpacing.buttonCornerRadius)
                            }
                            
                            Button {
                                Task { try? await duelService.respondToChallenge(duel, accept: false) }
                            } label: {
                                Text("Decline")
                                    .font(AppFonts.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(AppColors.error)
                                    .cornerRadius(AppSpacing.buttonCornerRadius)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - History
    
    private var historySection: some View {
        Group {
            if duelService.duelHistory.isEmpty {
                emptyState(icon: "clock", message: "No duel history", subtitle: "")
            } else {
                ForEach(duelService.duelHistory) { duel in
                    DuelCard(duel: duel, myPlayerID: UserDefaults.standard.string(forKey: "currentPlayerId") ?? "")
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var winRate: String {
        let total = duelService.wins + duelService.losses
        guard total > 0 else { return "—" }
        return "\(Int(Double(duelService.wins) / Double(total) * 100))%"
    }
    
    private func emptyState(icon: String, message: String, subtitle: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(AppColors.textTertiary)
            Text(message)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl)
    }
}

// MARK: - Duel Stat Badge

struct DuelStatBadge: View {
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

// MARK: - Duel Card

struct DuelCard: View {
    let duel: Duel
    let myPlayerID: String
    
    private var isChallenger: Bool { duel.challengerID == myPlayerID }
    private var myScore: Int { isChallenger ? duel.challengerScore : duel.opponentScore }
    private var theirScore: Int { isChallenger ? duel.opponentScore : duel.challengerScore }
    private var isWin: Bool { duel.winnerID == myPlayerID }
    private var isTie: Bool { duel.winnerID == "tie" }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header
            HStack {
                Image(systemName: duel.duelType.icon)
                    .foregroundColor(duel.duelType.color)
                Text(duel.duelType.displayName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                
                if duel.status == .completed {
                    Text(isWin ? "WON" : (isTie ? "TIE" : "LOST"))
                        .font(AppFonts.caption1)
                        .foregroundColor(isWin ? AppColors.success : (isTie ? .orange : AppColors.error))
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background((isWin ? AppColors.success : (isTie ? Color.orange : AppColors.error)).opacity(0.15))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                } else {
                    Text(duel.timeRemaining)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Score comparison
            HStack {
                VStack(spacing: 2) {
                    Text("You")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    Text("\(myScore)")
                        .font(AppFonts.title3)
                        .foregroundColor(myScore >= theirScore ? AppColors.success : AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                
                Text("vs")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                
                VStack(spacing: 2) {
                    Text("Them")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                    Text("\(theirScore)")
                        .font(AppFonts.title3)
                        .foregroundColor(theirScore > myScore ? AppColors.error : AppColors.textPrimary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Stakes
            if duel.stakes > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.primaryBlue)
                    Text("Stakes: \(duel.stakes) XP")
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
