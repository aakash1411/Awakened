import SwiftUI
import SwiftData

/// Sheet for logging a new reading entry
struct AddReadingEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    @State private var bookTitle: String = ""
    @State private var author: String = ""
    @State private var pagesRead: String = ""
    @State private var minutesRead: Int = 30
    @State private var notes: String = ""
    @State private var existingTitles: [String] = []
    @State private var showSuggestions = false
    
    var onComplete: ((ReadingEntry) -> Void)?
    
    private var player: Player? { players.first }
    
    private var isValid: Bool {
        !bookTitle.isEmpty && (Int(pagesRead) ?? 0) > 0
    }
    
    private var filteredSuggestions: [String] {
        guard !bookTitle.isEmpty else { return [] }
        return existingTitles.filter {
            $0.localizedCaseInsensitiveContains(bookTitle) && $0 != bookTitle
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Book info
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Book")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Book title", text: $bookTitle)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface.opacity(0.5))
                                .cornerRadius(AppSpacing.cardCornerRadius)
                                .onChange(of: bookTitle) { _, _ in
                                    showSuggestions = !filteredSuggestions.isEmpty
                                }
                            
                            // Autocomplete suggestions
                            if showSuggestions {
                                VStack(spacing: 0) {
                                    ForEach(filteredSuggestions.prefix(3), id: \.self) { title in
                                        Button {
                                            bookTitle = title
                                            showSuggestions = false
                                        } label: {
                                            Text(title)
                                                .font(AppFonts.subheadline)
                                                .foregroundColor(AppColors.textPrimary)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.horizontal, AppSpacing.md)
                                                .padding(.vertical, AppSpacing.sm)
                                        }
                                        Divider().background(AppColors.border)
                                    }
                                }
                                .background(AppColors.surface)
                                .cornerRadius(AppSpacing.cardCornerRadius)
                            }
                            
                            TextField("Author (optional)", text: $author)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface.opacity(0.5))
                                .cornerRadius(AppSpacing.cardCornerRadius)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Pages & Duration
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Session Details")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack(spacing: AppSpacing.md) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pages Read")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(AppColors.textSecondary)
                                    TextField("0", text: $pagesRead)
                                        .font(AppFonts.title2)
                                        .foregroundColor(AppColors.textPrimary)
                                        .keyboardType(.numberPad)
                                        .padding(AppSpacing.sm)
                                        .background(AppColors.surface.opacity(0.5))
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Duration")
                                        .font(AppFonts.caption1)
                                        .foregroundColor(AppColors.textSecondary)
                                    HStack {
                                        Text("\(minutesRead) min")
                                            .font(AppFonts.title2)
                                            .foregroundColor(AppColors.textPrimary)
                                    }
                                }
                            }
                            
                            Slider(
                                value: Binding(
                                    get: { Double(minutesRead) },
                                    set: { minutesRead = Int($0) }
                                ),
                                in: 5...180,
                                step: 5
                            )
                            .tint(AppColors.intelligenceColor)
                            
                            HStack(spacing: AppSpacing.sm) {
                                ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                                    Button {
                                        minutesRead = mins
                                    } label: {
                                        Text("\(mins)m")
                                            .font(AppFonts.caption1)
                                            .foregroundColor(minutesRead == mins ? .white : AppColors.textSecondary)
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, 4)
                                            .background(minutesRead == mins ? AppColors.intelligenceColor : AppColors.surface.opacity(0.5))
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
                            
                            TextField("Key takeaways, thoughts...", text: $notes, axis: .vertical)
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
                        let pages = Int(pagesRead) ?? 0
                        let xp = XPCalculator.intelligenceXP(readingMinutes: Double(minutesRead), pagesRead: pages)
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
                            saveEntry()
                        } label: {
                            Text("Log Reading")
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
            .navigationTitle("Log Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .onAppear {
                let service = IntelligenceService(modelContext: modelContext)
                existingTitles = service.uniqueBookTitles()
            }
        }
    }
    
    private func saveEntry() {
        guard let player = player, isValid else { return }
        let pages = Int(pagesRead) ?? 0
        
        let service = IntelligenceService(modelContext: modelContext)
        let entry = service.addReadingEntry(
            bookTitle: bookTitle,
            author: author.isEmpty ? nil : author,
            pagesRead: pages,
            minutesRead: Double(minutesRead),
            notes: notes.isEmpty ? nil : notes,
            player: player
        )
        
        onComplete?(entry)
        dismiss()
    }
}
