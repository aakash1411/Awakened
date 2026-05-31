import SwiftUI
import SwiftData

/// Browse and search for public guilds to join
struct GuildBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var guildService: GuildService
    @Query private var players: [Player]
    
    @State private var searchText = ""
    @State private var guilds: [Guild] = []
    @State private var isSearching = false
    @State private var joinError: String?
    
    private var player: Player? { players.first }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textTertiary)
                    TextField("Search guilds...", text: $searchText)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .onSubmit { Task { await performSearch() } }
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.md)
                
                // Results
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        if isSearching {
                            ProgressView()
                                .tint(AppColors.primaryBlue)
                                .padding(.top, AppSpacing.xxl)
                        } else if guilds.isEmpty {
                            VStack(spacing: AppSpacing.md) {
                                Image(systemName: "shield.slash")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppColors.textTertiary)
                                Text("No guilds found")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.top, AppSpacing.xxl)
                        } else {
                            ForEach(guilds) { guild in
                                guildCard(guild)
                            }
                        }
                        
                        if let joinError {
                            Text(joinError)
                                .font(AppFonts.caption1)
                                .foregroundColor(AppColors.error)
                                .padding(.top, AppSpacing.md)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .navigationTitle("Browse Guilds")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .task {
            await performSearch()
        }
    }
    
    // MARK: - Guild Card
    
    private func guildCard(_ guild: Guild) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                // Emblem
                ZStack {
                    Circle()
                        .fill(guild.bannerColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text(guild.emblem)
                        .font(.system(size: 22))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(guild.name)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: guild.guildRank.icon)
                            .font(.system(size: 10))
                            .foregroundColor(guild.guildRank.color)
                        Text(guild.guildRank.rawValue)
                            .font(AppFonts.caption2)
                            .foregroundColor(guild.guildRank.color)
                        Text("Lv. \(guild.guildLevel)")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                        Text("\(guild.memberCount)/\(guild.maxMembers)")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                // Join button
                Button {
                    joinGuild(guild)
                } label: {
                    Text("Join")
                        .font(AppFonts.caption1)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.xs)
                        .background(guild.hasRoom ? AppColors.primaryBlue : AppColors.textTertiary)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(!guild.hasRoom)
            }
            
            if !guild.description.isEmpty {
                Text(guild.description)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                    .lineLimit(2)
            }
            
            if guild.minRankToJoin != .e {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                    Text("Requires \(guild.minRankToJoin.displayName)")
                        .font(AppFonts.caption2)
                }
                .foregroundColor(guild.minRankToJoin.color)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Actions
    
    private func performSearch() async {
        isSearching = true
        guilds = await guildService.searchGuilds(query: searchText)
        isSearching = false
    }
    
    private func joinGuild(_ guild: Guild) {
        joinError = nil
        Task {
            do {
                let rank = player?.rank ?? .e
                try await guildService.joinGuild(guild, playerRank: rank)
                dismiss()
            } catch {
                joinError = error.localizedDescription
            }
        }
    }
}
