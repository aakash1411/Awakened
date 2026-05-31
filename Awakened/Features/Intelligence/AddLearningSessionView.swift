import SwiftUI
import SwiftData

/// Sheet for logging a new learning session
struct AddLearningSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    @State private var title: String = ""
    @State private var selectedCategory: LearningCategory = .course
    @State private var durationMinutes: Int = 30
    @State private var notes: String = ""
    
    var onComplete: ((LearningSession) -> Void)?
    
    private var player: Player? { players.first }
    
    private var isValid: Bool { !title.isEmpty }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Title
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("What did you learn?")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Topic or title", text: $title)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface.opacity(0.5))
                                .cornerRadius(AppSpacing.cardCornerRadius)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Category
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Category")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: AppSpacing.sm) {
                                ForEach(LearningCategory.allCases) { cat in
                                    Button {
                                        selectedCategory = cat
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 20))
                                            Text(cat.displayName)
                                                .font(AppFonts.caption2)
                                        }
                                        .foregroundColor(selectedCategory == cat ? .white : AppColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(selectedCategory == cat ? AppColors.intelligenceColor : AppColors.surface.opacity(0.5))
                                        .cornerRadius(AppSpacing.cardCornerRadius)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Duration
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Duration")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack {
                                Text("\(durationMinutes) min")
                                    .font(AppFonts.title2)
                                    .foregroundColor(AppColors.intelligenceColor)
                                    .frame(width: 80)
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(durationMinutes) },
                                        set: { durationMinutes = Int($0) }
                                    ),
                                    in: 5...180,
                                    step: 5
                                )
                                .tint(AppColors.intelligenceColor)
                            }
                            
                            HStack(spacing: AppSpacing.sm) {
                                ForEach([15, 30, 45, 60, 90, 120], id: \.self) { mins in
                                    Button {
                                        durationMinutes = mins
                                    } label: {
                                        Text("\(mins)m")
                                            .font(AppFonts.caption1)
                                            .foregroundColor(durationMinutes == mins ? .white : AppColors.textSecondary)
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, 4)
                                            .background(durationMinutes == mins ? AppColors.intelligenceColor : AppColors.surface.opacity(0.5))
                                            .cornerRadius(AppSpacing.buttonCornerRadius)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Notes
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Notes (optional)")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Key takeaways...", text: $notes, axis: .vertical)
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
                        
                        // XP Preview
                        let baseMinutes: Double = [.course, .coding, .problemSolving].contains(selectedCategory) ? Double(durationMinutes) * 1.5 : Double(durationMinutes)
                        let xp = XPCalculator.intelligenceXP(readingMinutes: baseMinutes)
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppColors.intelligenceColor)
                            Text("Estimated XP:")
                                .font(AppFonts.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("+\(xp) INT XP")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.intelligenceColor)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.intelligenceColor.opacity(0.1))
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Save
                        Button {
                            saveSession()
                        } label: {
                            Text("Log Session")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(isValid ? AppColors.intelligenceColor : AppColors.textTertiary)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        .disabled(!isValid)
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Log Learning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    private func saveSession() {
        guard let player = player, isValid else { return }
        
        let service = IntelligenceService(modelContext: modelContext)
        let session = service.addLearningSession(
            title: title,
            category: selectedCategory,
            durationMinutes: Double(durationMinutes),
            notes: notes.isEmpty ? nil : notes,
            player: player
        )
        
        onComplete?(session)
        dismiss()
    }
}
