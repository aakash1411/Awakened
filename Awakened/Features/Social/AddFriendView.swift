import SwiftUI

/// Search for and add friends by display name, or invite via share sheet
struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var friendService: FriendService
    @ObservedObject var syncEngine: ProfileSyncEngine
    
    @State private var searchText = ""
    @State private var searchResults: [CloudProfile] = []
    @State private var isSearching = false
    @State private var sentRequests: Set<String> = []
    @State private var showingInvite = false
    @State private var selectedProfile: CloudProfile?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppColors.textTertiary)
                    TextField("Search by hunter name...", text: $searchText)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onSubmit { performSearch() }
                        .onChange(of: searchText) { _, newValue in
                            if newValue.count >= 2 {
                                performSearch()
                            } else {
                                searchResults = []
                            }
                        }
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
                
                // Results
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        if isSearching {
                            ProgressView()
                                .tint(AppColors.primaryBlue)
                                .padding(.top, AppSpacing.xxl)
                        } else if searchResults.isEmpty && searchText.count >= 2 {
                            noResultsView
                        } else {
                            ForEach(searchResults) { profile in
                                searchResultRow(profile)
                            }
                        }
                        
                        // Invite section
                        if !isSearching {
                            inviteSection
                                .padding(.top, AppSpacing.lg)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
        }
        .navigationTitle("Add Friend")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .sheet(item: $selectedProfile) { profile in
            NavigationStack {
                PublicProfileView(
                    profile: profile,
                    onAddFriend: {
                        sendRequest(to: profile)
                        selectedProfile = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingInvite) {
            InviteFriendView()
        }
    }
    
    // MARK: - Search Result Row
    
    private func searchResultRow(_ profile: CloudProfile) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Tappable profile area
            Button {
                selectedProfile = profile
            } label: {
                HStack(spacing: AppSpacing.md) {
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
                }
            }
            
            Spacer()
            
            // Add button
            if sentRequests.contains(profile.id) {
                Text("Sent")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
            } else {
                Button {
                    sendRequest(to: profile)
                } label: {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(AppSpacing.sm)
                        .background(AppColors.primaryBlue)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - No Results
    
    private var noResultsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "person.slash")
                .font(.system(size: 36))
                .foregroundColor(AppColors.textTertiary)
            Text("No hunters found")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("Try a different name or invite your friends to join!")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.xxl)
    }
    
    // MARK: - Invite Section
    
    private var inviteSection: some View {
        Button {
            showingInvite = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.accentCyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite Friends")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Share a link to invite friends who aren't on Awakened yet")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.accentCyan.opacity(0.1))
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
    }
    
    // MARK: - Helpers
    
    private func performSearch() {
        guard searchText.count >= 2 else { return }
        isSearching = true
        Task {
            searchResults = await friendService.searchPlayers(query: searchText)
            isSearching = false
        }
    }
    
    private func sendRequest(to profile: CloudProfile) {
        Task {
            do {
                try await friendService.sendFriendRequest(to: profile.id)
                sentRequests.insert(profile.id)
                SoundManager.shared.haptic(.success)
            } catch {
                print("Failed to send friend request: \(error)")
            }
        }
    }
}
