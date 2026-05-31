import SwiftUI
import SwiftData

/// Share sheet view for inviting friends who aren't on the app yet
struct InviteFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    
    @State private var showingShareSheet = false
    
    private var player: Player? { players.first }
    
    private var inviteMessage: String {
        guard let player = player else {
            return "Join me on Awakened — the gamified fitness app that turns your real-life workouts into RPG stats! Download: https://apps.apple.com/app/awakened"
        }
        return "I'm a Level \(player.level) \(player.rank.displayName) Hunter on Awakened! Join me and level up your real life. Download: https://apps.apple.com/app/awakened"
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Illustration
                VStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppColors.accentCyan.opacity(0.15))
                            .frame(width: 120, height: 120)
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.accentCyan)
                    }
                    
                    Text("Invite Friends")
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Share Awakened with your friends so you can track progress, compete, and level up together!")
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppSpacing.lg)
                }
                
                // Preview card
                VStack(spacing: AppSpacing.sm) {
                    Text("Your invite message:")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text(inviteMessage)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .padding(AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                
                Spacer()
                
                // Share button
                Button {
                    showingShareSheet = true
                } label: {
                    Label("Share Invite", systemImage: "square.and.arrow.up")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.accentCyan)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.lg)
            }
        }
        .navigationTitle("Invite")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [inviteMessage])
        }
    }
}

// MARK: - UIKit Share Sheet Bridge

/// UIActivityViewController wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
