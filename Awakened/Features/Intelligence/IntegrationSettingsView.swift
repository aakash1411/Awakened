import SwiftUI

/// Settings view for Notion & GitHub integrations
struct IntegrationSettingsView: View {
    @StateObject private var notionService = NotionService()
    @StateObject private var githubService = GitHubService()
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Header
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "link")
                            .font(.system(size: 36))
                            .foregroundColor(AppColors.intelligenceColor)
                        
                        Text("Intelligence Integrations")
                            .font(AppFonts.title3)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Connect external services to automatically track learning activities.")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, AppSpacing.lg)
                    
                    // Notion
                    integrationCard(
                        name: "Notion",
                        icon: "doc.text.fill",
                        description: "Track reading notes and learning databases",
                        isConnected: notionService.isConnected,
                        isLoading: notionService.isAuthenticating,
                        error: notionService.authError,
                        connectAction: { notionService.authenticate() },
                        disconnectAction: { notionService.disconnect() }
                    )
                    
                    // GitHub
                    integrationCard(
                        name: "GitHub",
                        icon: "chevron.left.forwardslash.chevron.right",
                        description: "Track coding contributions and commits",
                        isConnected: githubService.isConnected,
                        isLoading: githubService.isAuthenticating,
                        error: githubService.authError,
                        connectAction: { githubService.authenticate() },
                        disconnectAction: { githubService.disconnect() }
                    )
                    
                    // Info
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "info.circle")
                                .foregroundColor(AppColors.textTertiary)
                            Text("Coming Soon")
                                .font(AppFonts.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        
                        Text("These integrations are being developed. For now, you can manually log reading and learning sessions to earn Intelligence XP.")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(AppSpacing.cardPadding)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
        }
        .navigationTitle("Integrations")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Integration Card
    
    private func integrationCard(
        name: String,
        icon: String,
        description: String,
        isConnected: Bool,
        isLoading: Bool,
        error: String?,
        connectAction: @escaping () -> Void,
        disconnectAction: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppColors.intelligenceColor)
                    .frame(width: 40, height: 40)
                    .background(AppColors.intelligenceColor.opacity(0.15))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text(description)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                // Status
                if isConnected {
                    Text("Connected")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.success)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(AppColors.success.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            
            if let error = error {
                Text(error)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.warning)
            }
            
            // Action button
            if isConnected {
                Button {
                    disconnectAction()
                } label: {
                    Text("Disconnect")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            } else {
                Button {
                    connectAction()
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Connect \(name)")
                    }
                    .font(AppFonts.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.intelligenceColor)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(isLoading)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
