import SwiftUI

/// Social activity feed showing friends' and guild members' events with reactions
struct ActivityFeedView: View {
    @ObservedObject var feedService: FeedService
    @ObservedObject var friendService: FriendService
    
    @State private var selectedScope: FeedScope = .friends
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scope picker
                Picker("", selection: $selectedScope) {
                    Text("Friends").tag(FeedScope.friends)
                    Text("Guild").tag(FeedScope.guild)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.md)
                
                // Feed content
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        let events = selectedScope == .friends ? feedService.friendFeed : feedService.guildFeed
                        
                        if feedService.isLoading {
                            ProgressView()
                                .tint(AppColors.primaryBlue)
                                .padding(.top, AppSpacing.xxl)
                        } else if events.isEmpty {
                            emptyFeedView
                        } else {
                            ForEach(events) { event in
                                FeedEventCard(event: event, onReact: { type in
                                    Task {
                                        await feedService.addReaction(to: event.id, type: type)
                                    }
                                })
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await loadFeed()
        }
        .task {
            await loadFeed()
        }
        .onChange(of: selectedScope) { _, _ in
            Task { await loadFeed() }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyFeedView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text("No activity yet")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            Text(selectedScope == .friends
                 ? "Add friends to see their achievements, quest completions, and more!"
                 : "Join a guild to see guild activity here.")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
        }
        .padding(.top, AppSpacing.xxl)
    }
    
    // MARK: - Load Feed
    
    private func loadFeed() async {
        switch selectedScope {
        case .friends:
            let friendIDs = friendService.friends.map(\.id)
            await feedService.fetchFriendFeed(friendIDs: friendIDs)
        case .guild:
            // Guild feed loaded via guild ID (set when guilds are implemented)
            break
        }
    }
}

/// Feed scope toggle
enum FeedScope: String {
    case friends
    case guild
}

// MARK: - Feed Event Card

/// A single event card in the activity feed
struct FeedEventCard: View {
    let event: FeedEvent
    var onReact: ((ReactionType) -> Void)?
    
    @State private var showReactions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Header: player + event type + time
            HStack(spacing: AppSpacing.sm) {
                // Event icon
                Image(systemName: event.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(event.color)
                    .frame(width: 32, height: 32)
                    .background(event.color.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.playerName)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(event.eventType.label)
                        .font(AppFonts.caption2)
                        .foregroundColor(event.color)
                }
                
                Spacer()
                
                Text(event.timeAgo)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            // Detail text
            Text(event.detail)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
            
            // Value badge (if applicable)
            if event.value > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.primaryBlue)
                    Text("+\(event.value) XP")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.primaryBlue)
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xxs)
                .background(AppColors.primaryBlue.opacity(0.1))
                .cornerRadius(AppSpacing.buttonCornerRadius)
            }
            
            // Reaction bar
            ReactionBar(
                reactions: event.reactions,
                isExpanded: $showReactions,
                onReact: onReact
            )
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Reaction Bar

/// Horizontal bar of reaction emoji buttons with counts
struct ReactionBar: View {
    let reactions: [ReactionType: Int]
    @Binding var isExpanded: Bool
    var onReact: ((ReactionType) -> Void)?
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            // Existing reactions with counts
            ForEach(sortedReactions, id: \.type) { item in
                Button {
                    onReact?(item.type)
                } label: {
                    HStack(spacing: 2) {
                        Text(item.type.emoji)
                            .font(.system(size: 14))
                        if item.count > 0 {
                            Text("\(item.count)")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, AppSpacing.xxs)
                    .background(AppColors.surfaceElevated)
                    .cornerRadius(12)
                }
            }
            
            // Add reaction button
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "xmark" : "face.smiling")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(AppColors.surfaceElevated)
                    .cornerRadius(14)
            }
            
            Spacer()
        }
        
        // Expanded reaction picker
        if isExpanded {
            HStack(spacing: AppSpacing.sm) {
                ForEach(ReactionType.allCases, id: \.self) { type in
                    Button {
                        onReact?(type)
                        withAnimation { isExpanded = false }
                    } label: {
                        Text(type.emoji)
                            .font(.system(size: 22))
                            .frame(width: 36, height: 36)
                            .background(AppColors.surfaceElevated)
                            .cornerRadius(8)
                    }
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
        }
    }
    
    /// Sorted reactions (only those with counts > 0)
    private var sortedReactions: [(type: ReactionType, count: Int)] {
        reactions
            .filter { $0.value > 0 }
            .map { (type: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }
}
