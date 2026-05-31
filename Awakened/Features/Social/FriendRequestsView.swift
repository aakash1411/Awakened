import SwiftUI

/// Displays incoming and outgoing friend requests
struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var friendService: FriendService
    @ObservedObject var syncEngine: ProfileSyncEngine
    
    @State private var selectedTab = 0
    @State private var senderProfiles: [String: CloudProfile] = [:]
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    Text("Incoming (\(friendService.incomingRequests.count))").tag(0)
                    Text("Outgoing (\(friendService.outgoingRequests.count))").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.md)
                
                ScrollView {
                    VStack(spacing: AppSpacing.sm) {
                        if selectedTab == 0 {
                            incomingSection
                        } else {
                            outgoingSection
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                }
            }
        }
        .navigationTitle("Friend Requests")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .task {
            await loadSenderProfiles()
        }
    }
    
    // MARK: - Incoming
    
    private var incomingSection: some View {
        Group {
            if friendService.incomingRequests.isEmpty {
                emptyState(message: "No pending requests")
            } else {
                ForEach(friendService.incomingRequests) { request in
                    incomingRequestRow(request)
                }
            }
        }
    }
    
    private func incomingRequestRow(_ request: FriendRequestRecord) -> some View {
        let profile = senderProfiles[request.senderID]
        
        return HStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill((profile?.rank.color ?? AppColors.textTertiary).opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(profile?.avatarEmoji ?? "?")
                    .font(.system(size: 20))
            }
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(profile?.displayName ?? "Loading...")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                if let profile {
                    Text("\(profile.rank.displayName) • Lv. \(profile.level)")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            Spacer()
            
            // Accept / Decline
            HStack(spacing: AppSpacing.xs) {
                Button {
                    respond(to: request, accept: true)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(AppColors.success)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                Button {
                    respond(to: request, accept: false)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(AppColors.error)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Outgoing
    
    private var outgoingSection: some View {
        Group {
            if friendService.outgoingRequests.isEmpty {
                emptyState(message: "No outgoing requests")
            } else {
                ForEach(friendService.outgoingRequests) { request in
                    outgoingRequestRow(request)
                }
            }
        }
    }
    
    private func outgoingRequestRow(_ request: FriendRequestRecord) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "paperplane.fill")
                .foregroundColor(AppColors.primaryBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sent to \(request.receiverID.prefix(8))...")
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                Text("Pending")
                    .font(AppFonts.caption2)
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            Text(request.sentAt.formatted(.relative(presentation: .named)))
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Empty State
    
    private func emptyState(message: String) -> some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundColor(AppColors.textTertiary)
            Text(message)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xxl)
    }
    
    // MARK: - Helpers
    
    private func loadSenderProfiles() async {
        for request in friendService.incomingRequests {
            if senderProfiles[request.senderID] == nil {
                if let profile = await syncEngine.fetchProfile(playerID: request.senderID) {
                    senderProfiles[request.senderID] = profile
                }
            }
        }
    }
    
    private func respond(to request: FriendRequestRecord, accept: Bool) {
        Task {
            do {
                try await friendService.respondToRequest(request, accept: accept)
                SoundManager.shared.haptic(accept ? .success : .light)
            } catch {
                print("Failed to respond to request: \(error)")
            }
        }
    }
}
