import SwiftUI

/// View for creating a new guild
struct CreateGuildView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var guildService: GuildService
    
    @State private var name = ""
    @State private var description = ""
    @State private var emblem = "⚔️"
    @State private var isPublic = true
    @State private var minRank: PlayerRank = .e
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    private let emblemOptions = [
        "⚔️", "🗡️", "🛡️", "🏹", "🔮", "🐉", "🦅", "🐺",
        "🦁", "🔥", "⚡", "💎", "👑", "🌟", "🎖️", "🏰"
    ]
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Emblem preview
                    VStack(spacing: AppSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryBlue.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Circle()
                                .stroke(AppColors.primaryBlue, lineWidth: 3)
                                .frame(width: 80, height: 80)
                            Text(emblem)
                                .font(.system(size: 36))
                        }
                        
                        // Emblem picker
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: AppSpacing.xs) {
                            ForEach(emblemOptions, id: \.self) { emoji in
                                Button {
                                    emblem = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 24))
                                        .frame(width: 36, height: 36)
                                        .background(emblem == emoji ? AppColors.primaryBlue.opacity(0.3) : Color.clear)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Name
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Guild Name")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("Enter guild name", text: $name)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                            .textInputAutocapitalization(.words)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Description")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("What is your guild about?", text: $description, axis: .vertical)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                            .lineLimit(3...5)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                    
                    // Settings
                    VStack(spacing: 0) {
                        HStack {
                            Text("Public Guild")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Toggle("", isOn: $isPublic)
                                .labelsHidden()
                                .tint(AppColors.primaryBlue)
                        }
                        .padding(AppSpacing.md)
                        
                        Divider().background(AppColors.border)
                        
                        HStack {
                            Text("Minimum Rank")
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Picker("", selection: $minRank) {
                                ForEach(PlayerRank.allCases, id: \.self) { rank in
                                    Text(rank.displayName)
                                        .foregroundColor(rank.color)
                                        .tag(rank)
                                }
                            }
                            .tint(minRank.color)
                        }
                        .padding(AppSpacing.md)
                    }
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Error message
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.error)
                    }
                    
                    // Create button
                    Button {
                        createGuild()
                    } label: {
                        HStack {
                            if isCreating {
                                ProgressView().tint(.white)
                            }
                            Text(isCreating ? "Creating..." : "Create Guild")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(name.isEmpty ? AppColors.textTertiary : AppColors.primaryBlue)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(name.isEmpty || isCreating)
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Create Guild")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private func createGuild() {
        isCreating = true
        errorMessage = nil
        
        Task {
            do {
                try await guildService.createGuild(
                    name: name,
                    description: description,
                    emblem: emblem,
                    isPublic: isPublic,
                    minRank: minRank
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}
