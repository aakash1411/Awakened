import SwiftUI
import SwiftData

/// View for editing display name, avatar emoji, and bio tagline
struct EditDisplayProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    @ObservedObject var syncEngine: ProfileSyncEngine
    
    @State private var displayName: String = ""
    @State private var avatarEmoji: String = "⚔️"
    @State private var bio: String = ""
    @State private var isPublic: Bool = true
    @State private var isSaving: Bool = false
    
    private var player: Player? { players.first }
    
    private let emojiOptions = [
        "⚔️", "🗡️", "🛡️", "🏹", "🔮", "🧙‍♂️", "🧝‍♂️", "🐉",
        "🦅", "🐺", "🦁", "🔥", "⚡", "💎", "👑", "🎯",
        "🏋️", "🧘", "🏃", "📖", "🧠", "💪", "🌟", "🎖️"
    ]
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Avatar preview
                    VStack(spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryBlue.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Circle()
                                .stroke(AppColors.primaryBlue, lineWidth: 3)
                                .frame(width: 100, height: 100)
                            Text(avatarEmoji)
                                .font(.system(size: 44))
                        }
                        
                        Text("Tap to choose avatar")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    // Emoji picker
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: AppSpacing.sm) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button {
                                avatarEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 40, height: 40)
                                    .background(avatarEmoji == emoji ? AppColors.primaryBlue.opacity(0.3) : Color.clear)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Display name
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Display Name")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        TextField("Enter your hunter name", text: $displayName)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                            .textInputAutocapitalization(.words)
                    }
                    
                    // Bio
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack {
                            Text("Bio")
                                .font(AppFonts.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("\(bio.count)/80")
                                .font(AppFonts.caption2)
                                .foregroundColor(bio.count > 80 ? AppColors.error : AppColors.textTertiary)
                        }
                        
                        TextField("Short tagline about yourself", text: $bio)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                            .onChange(of: bio) { _, newValue in
                                if newValue.count > 80 {
                                    bio = String(newValue.prefix(80))
                                }
                            }
                    }
                    
                    // Public toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Public Profile")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                            Text("Allow other hunters to find and view your profile")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $isPublic)
                            .labelsHidden()
                            .tint(AppColors.primaryBlue)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Save button
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSaving ? "Saving..." : "Save Profile")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(displayName.isEmpty ? AppColors.textTertiary : AppColors.primaryBlue)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(displayName.isEmpty || isSaving)
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentValues()
        }
    }
    
    // MARK: - Helpers
    
    private func loadCurrentValues() {
        displayName = player?.name ?? ""
        avatarEmoji = UserDefaults.standard.string(forKey: "avatarEmoji") ?? "⚔️"
        bio = UserDefaults.standard.string(forKey: "profileBio") ?? ""
        isPublic = UserDefaults.standard.bool(forKey: "profileIsPublic")
    }
    
    private func saveProfile() {
        guard let player = player else { return }
        isSaving = true
        
        // Update local player name
        player.name = displayName
        
        // Save customization to UserDefaults
        syncEngine.updateAvatarEmoji(avatarEmoji)
        syncEngine.updateBio(bio)
        syncEngine.setProfilePublic(isPublic)
        
        // Push to CloudKit
        Task {
            await syncEngine.forceSync(for: player)
            isSaving = false
            dismiss()
        }
    }
}
