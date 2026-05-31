import SwiftUI

/// Displays the player's friends list with pending requests and search
struct FriendsListView: View {
    @ObservedObject var friendService: FriendService
    @ObservedObject var syncEngine: ProfileSyncEngine
    
    @State private var showingAddFriend = false
    @State private var showingRequests = false
    @State private var selectedProfile: CloudProfile?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Pending requests banner
                    if friendService.pendingRequestCount > 0 {
                        pendingRequestsBanner
                    }
                    
                    // Action buttons
                    HStack(spacing: AppSpacing.md) {
                        Button {
                            showingAddFriend = true
                        } label: {
                            Label("Add Friend", systemImage: "person.badge.plus")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(AppColors.primaryBlue)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        
                        Button {
                            showingRequests = true
                        } label: {
                            Label("Requests", systemImage: "bell.fill")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(AppColors.accentPurple)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                    }
                    
                    // Friends list
                    if friendService.isLoading {
                        ProgressView()
                            .tint(AppColors.primaryBlue)
                            .padding(.top, AppSpacing.xxl)
                    } else if friendService.friends.isEmpty {
                        emptyState
                    } else {
                        friendsList
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Friends (\(friendService.friendCount))")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await friendService.refreshAll()
        }
        .task {
            await friendService.refreshAll()
        }
        .sheet(isPresented: $showingAddFriend) {
            NavigationStack {
                AddFriendView(friendService: friendService, syncEngine: syncEngine)
            }
        }
        .sheet(isPresented: $showingRequests) {
            NavigationStack {
                FriendRequestsView(friendService: friendService, syncEngine: syncEngine)
            }
        }
        .sheet(item: $selectedProfile) { profile in
            NavigationStack {
                PublicProfileView(
                    profile: profile,
                    onChallenge: nil
                )
            }
        }
    }
    
    // MARK: - Pending Requests Banner
    
    private var pendingRequestsBanner: some View {
        Button {
            showingRequests = true
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.orange)
                Text("\(friendService.pendingRequestCount) pending request\(friendService.pendingRequestCount == 1 ? "" : "s")")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
    }
    
    // MARK: - Friends List
    
    private var friendsList: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(friendService.friends) { friend in
                Button {
                    selectedProfile = friend
                } label: {
                    FriendRow(profile: friend)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textTertiary)
            Text("No friends yet")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("Search for other hunters or invite your friends to join!")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xxl)
    }
}

// MARK: - Friend Row

struct FriendRow: View {
    let profile: CloudProfile
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(profile.rank.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Circle()
                    .stroke(profile.rank.color, lineWidth: 2)
                    .frame(width: 44, height: 44)
                Text(profile.avatarEmoji)
                    .font(.system(size: 20))
            }
            
            // Name + rank
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.xs) {
                    Text(profile.rank.displayName)
                        .font(AppFonts.caption2)
                        .foregroundColor(profile.rank.color)
                    Text("Lv. \(profile.level)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            // Streak indicator
            if profile.currentStreak > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(profile.currentStreak)")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
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
