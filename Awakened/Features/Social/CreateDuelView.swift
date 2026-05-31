import SwiftUI

/// Create a new duel challenge — pick friend, type, duration, and stakes
struct CreateDuelView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var duelService: DuelService
    @ObservedObject var friendService: FriendService
    
    @State private var selectedFriend: CloudProfile?
    @State private var selectedType: DuelType = .xpSprint
    @State private var durationDays: Double = 7
    @State private var stakes: Double = 100
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Select friend
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Challenge")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if friendService.friends.isEmpty {
                            Text("Add friends first to challenge them!")
                                .font(AppFonts.caption1)
                                .foregroundColor(AppColors.textTertiary)
                                .padding(AppSpacing.md)
                                .frame(maxWidth: .infinity)
                                .background(AppColors.surface)
                                .cornerRadius(AppSpacing.cardCornerRadius)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppSpacing.sm) {
                                    ForEach(friendService.friends) { friend in
                                        Button {
                                            selectedFriend = friend
                                        } label: {
                                            VStack(spacing: 4) {
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedFriend?.id == friend.id ? AppColors.primaryBlue.opacity(0.3) : AppColors.surface)
                                                        .frame(width: 52, height: 52)
                                                    Circle()
                                                        .stroke(selectedFriend?.id == friend.id ? AppColors.primaryBlue : friend.rank.color, lineWidth: 2)
                                                        .frame(width: 52, height: 52)
                                                    Text(friend.avatarEmoji)
                                                        .font(.system(size: 22))
                                                }
                                                Text(friend.displayName)
                                                    .font(AppFonts.caption2)
                                                    .foregroundColor(selectedFriend?.id == friend.id ? AppColors.primaryBlue : AppColors.textSecondary)
                                                    .lineLimit(1)
                                            }
                                            .frame(width: 64)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Select type
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Duel Type")
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                            ForEach(DuelType.allCases) { type in
                                Button {
                                    selectedType = type
                                } label: {
                                    VStack(spacing: AppSpacing.xs) {
                                        Image(systemName: type.icon)
                                            .font(.system(size: 22))
                                            .foregroundColor(type.color)
                                        Text(type.displayName)
                                            .font(AppFonts.caption1)
                                            .foregroundColor(AppColors.textPrimary)
                                        Text(type.description)
                                            .font(AppFonts.caption2)
                                            .foregroundColor(AppColors.textTertiary)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(AppSpacing.md)
                                    .background(selectedType == type ? type.color.opacity(0.15) : AppColors.surface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                                            .stroke(selectedType == type ? type.color : Color.clear, lineWidth: 2)
                                    )
                                    .cornerRadius(AppSpacing.cardCornerRadius)
                                }
                            }
                        }
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Duration")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(Int(durationDays)) day\(Int(durationDays) == 1 ? "" : "s")")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.primaryBlue)
                        }
                        
                        Slider(value: $durationDays, in: 1...14, step: 1)
                            .tint(AppColors.primaryBlue)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Stakes
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("XP Stakes")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(Int(stakes)) XP")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.accentPurple)
                        }
                        
                        Slider(value: $stakes, in: 0...500, step: 50)
                            .tint(AppColors.accentPurple)
                        
                        Text("Winner earns bonus XP. Loser gets nothing extra.")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Error
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.error)
                    }
                    
                    // Send challenge
                    Button {
                        sendChallenge()
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView().tint(.white)
                            }
                            Text(isCreating ? "Sending..." : "Send Challenge")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(selectedFriend == nil ? AppColors.textTertiary : AppColors.strengthColor)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(selectedFriend == nil || isCreating)
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("New Duel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private func sendChallenge() {
        guard let friend = selectedFriend else { return }
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                try await duelService.challengeFriend(
                    friend.id,
                    type: selectedType,
                    durationHours: Int(durationDays) * 24,
                    stakes: Int(stakes)
                )
                SoundManager.shared.haptic(.success)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}
