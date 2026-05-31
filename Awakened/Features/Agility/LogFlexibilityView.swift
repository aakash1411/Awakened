import SwiftUI
import SwiftData

/// Form for manually logging a flexibility/agility session
struct LogFlexibilityView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    @StateObject private var service = AgilityService()
    
    private var player: Player? { players.first }
    
    @State private var selectedType: FlexibilityType = .yoga
    @State private var durationMinutes: Int = 30
    @State private var selectedIntensity: ActivityIntensity = .medium
    @State private var notes: String = ""
    @State private var showXPResult: Bool = false
    @State private var earnedXP: Int = 0
    
    /// Callback when session is logged
    var onComplete: ((FlexibilitySession) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Activity Type
                        typeSection
                        
                        // Duration
                        durationSection
                        
                        // Intensity
                        intensitySection
                        
                        // Notes
                        notesSection
                        
                        // XP Preview
                        xpPreview
                        
                        // Save Button
                        Button {
                            saveSession()
                        } label: {
                            Text("Log Session")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(AppColors.agilityColor)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Log Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .overlay {
                if showXPResult {
                    xpResultOverlay
                }
            }
        }
    }
    
    // MARK: - Type Section
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Activity Type")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: AppSpacing.sm) {
                ForEach(FlexibilityType.allCases) { type in
                    Button {
                        selectedType = type
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: type.icon)
                                .font(.system(size: 22))
                            Text(type.displayName)
                                .font(AppFonts.caption2)
                        }
                        .foregroundColor(selectedType == type ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(selectedType == type ? AppColors.agilityColor : AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Duration Section
    
    private var durationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Duration")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack {
                Text("\(durationMinutes) min")
                    .font(AppFonts.title2)
                    .foregroundColor(AppColors.agilityColor)
                    .frame(width: 80)
                
                Slider(
                    value: Binding(
                        get: { Double(durationMinutes) },
                        set: { durationMinutes = Int($0) }
                    ),
                    in: 5...120,
                    step: 5
                )
                .tint(AppColors.agilityColor)
            }
            
            // Quick preset buttons
            HStack(spacing: AppSpacing.sm) {
                ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                    Button {
                        durationMinutes = mins
                    } label: {
                        Text("\(mins)m")
                            .font(AppFonts.caption1)
                            .foregroundColor(durationMinutes == mins ? .white : AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 4)
                            .background(durationMinutes == mins ? AppColors.agilityColor : AppColors.surface.opacity(0.5))
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Intensity Section
    
    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Intensity")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(spacing: AppSpacing.md) {
                ForEach(ActivityIntensity.allCases) { intensity in
                    Button {
                        selectedIntensity = intensity
                    } label: {
                        VStack(spacing: 4) {
                            Text(intensity.displayName)
                                .font(AppFonts.subheadline)
                                .fontWeight(.medium)
                            Text(intensity.description)
                                .font(AppFonts.caption2)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .foregroundColor(selectedIntensity == intensity ? .white : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.sm)
                        .background(selectedIntensity == intensity ? AppColors.agilityColor : AppColors.surface.opacity(0.5))
                        .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Notes (optional)")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            TextField("How was the session?", text: $notes, axis: .vertical)
                .font(AppFonts.body)
                .foregroundColor(AppColors.textPrimary)
                .padding(AppSpacing.md)
                .background(AppColors.surface.opacity(0.5))
                .cornerRadius(AppSpacing.cardCornerRadius)
                .lineLimit(3...5)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - XP Preview
    
    private var xpPreview: some View {
        let xp = XPCalculator.agilityXP(
            durationMinutes: Double(durationMinutes),
            intensity: selectedIntensity
        )
        
        return HStack {
            Image(systemName: "sparkles")
                .foregroundColor(AppColors.agilityColor)
            
            Text("Estimated XP:")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text("+\(xp) AGI XP")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.agilityColor)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.agilityColor.opacity(0.1))
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Actions
    
    private func saveSession() {
        let session = service.logManualSession(
            type: selectedType,
            duration: Double(durationMinutes * 60),
            intensity: selectedIntensity,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Apply XP to Agility stat
        player?.addXP(session.xpEarned, to: .agility)
        
        // Update flexibility quest progress
        if let player = player {
            for quest in player.todayQuests where quest.isActive && quest.category == .flexibility {
                quest.addProgress(Double(durationMinutes))
                if quest.progress >= 1.0 && !quest.isCompleted {
                    player.completeQuest(quest)
                }
            }
        }
        
        earnedXP = session.xpEarned
        
        withAnimation {
            showXPResult = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onComplete?(session)
            dismiss()
        }
    }
    
    // MARK: - XP Result Overlay
    
    private var xpResultOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.lg) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.success)
                
                Text("Session Logged!")
                    .font(AppFonts.title2)
                    .foregroundColor(.white)
                
                Text("+\(earnedXP) AGI XP")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.agilityColor)
            }
            .transition(.scale.combined(with: .opacity))
        }
    }
}
