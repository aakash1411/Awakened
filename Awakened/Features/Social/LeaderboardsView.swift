import SwiftUI

/// Competitive leaderboards with type and scope toggles
struct LeaderboardsView: View {
    @ObservedObject var leaderboardService: LeaderboardService
    @ObservedObject var friendService: FriendService
    @ObservedObject var guildService: GuildService
    
    @State private var selectedType: LeaderboardType = .totalXP
    @State private var selectedScope: LeaderboardScope = .global
    @State private var showTypeSheet = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Controls
                VStack(spacing: AppSpacing.sm) {
                    // Scope picker
                    Picker("", selection: $selectedScope) {
                        ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                            Text(scope.rawValue).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Type selector
                    Button {
                        showTypeSheet = true
                    } label: {
                        HStack {
                            Image(systemName: selectedType.icon)
                                .foregroundColor(AppColors.primaryBlue)
                            Text(selectedType.displayName)
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.md)
                
                // My position banner
                if let pos = leaderboardService.myPosition {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(AppColors.primaryBlue)
                        Text("Your Rank: #\(pos)")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding(AppSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primaryBlue.opacity(0.1))
                }
                
                // Leaderboard list
                ScrollView {
                    LazyVStack(spacing: AppSpacing.xs) {
                        if leaderboardService.isLoading {
                            ProgressView()
                                .tint(AppColors.primaryBlue)
                                .padding(.top, AppSpacing.xxl)
                        } else if leaderboardService.entries.isEmpty {
                            Text("No entries")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textTertiary)
                                .padding(.top, AppSpacing.xxl)
                        } else {
                            ForEach(leaderboardService.entries) { entry in
                                LeaderboardRow(entry: entry, type: selectedType)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .navigationTitle("Leaderboards")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadBoard() }
        .task { await loadBoard() }
        .onChange(of: selectedScope) { _, _ in Task { await loadBoard() } }
        .onChange(of: selectedType) { _, _ in Task { await loadBoard() } }
        .sheet(isPresented: $showTypeSheet) {
            leaderboardTypePicker
        }
    }
    
    // MARK: - Type Picker
    
    private var leaderboardTypePicker: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient.ignoresSafeArea()
                
                List(LeaderboardType.allCases) { type in
                    Button {
                        selectedType = type
                        showTypeSheet = false
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: type.icon)
                                .foregroundColor(AppColors.primaryBlue)
                                .frame(width: 24)
                            Text(type.displayName)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            if type == selectedType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primaryBlue)
                            }
                        }
                    }
                    .listRowBackground(AppColors.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Board Type")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Load
    
    private func loadBoard() async {
        let friendIDs = friendService.friends.map(\.id)
        let guildMemberIDs = guildService.members.map(\.playerID)
        
        await leaderboardService.fetchLeaderboard(
            type: selectedType,
            scope: selectedScope,
            friendIDs: friendIDs,
            guildMemberIDs: guildMemberIDs
        )
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let type: LeaderboardType
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Position
            ZStack {
                if let medalIcon = entry.medalIcon {
                    Image(systemName: medalIcon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(entry.medalColor)
                        .frame(width: 32)
                } else {
                    Text("#\(entry.position)")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 32)
                }
            }
            
            // Avatar
            ZStack {
                Circle()
                    .fill(entry.rank.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Circle()
                    .stroke(entry.isCurrentUser ? AppColors.primaryBlue : entry.rank.color, lineWidth: entry.isCurrentUser ? 2 : 1)
                    .frame(width: 40, height: 40)
                Text(entry.avatarEmoji)
                    .font(.system(size: 18))
            }
            
            // Name + rank
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(AppFonts.body)
                    .foregroundColor(entry.isCurrentUser ? AppColors.primaryBlue : AppColors.textPrimary)
                Text("\(entry.rank.displayName) • Lv. \(entry.level)")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            // Score
            Text(formattedScore)
                .font(AppFonts.headline)
                .foregroundColor(entry.isCurrentUser ? AppColors.primaryBlue : AppColors.textPrimary)
        }
        .padding(AppSpacing.sm)
        .background(entry.isCurrentUser ? AppColors.primaryBlue.opacity(0.08) : AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private var formattedScore: String {
        if entry.score >= 1_000_000 {
            return String(format: "%.1fM", Double(entry.score) / 1_000_000)
        } else if entry.score >= 1_000 {
            return String(format: "%.1fk", Double(entry.score) / 1_000)
        }
        return "\(entry.score)"
    }
}
