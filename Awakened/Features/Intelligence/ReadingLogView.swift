import SwiftUI
import SwiftData

/// Full reading log with all entries grouped by book
struct ReadingLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReadingEntry.date, order: .reverse) private var entries: [ReadingEntry]
    @State private var showAddEntry = false
    
    /// Group entries by book title
    private var groupedByBook: [(String, [ReadingEntry])] {
        let grouped = Dictionary(grouping: entries) { $0.bookTitle }
        return grouped.sorted { lhs, rhs in
            guard let lhsDate = lhs.value.first?.date,
                  let rhsDate = rhs.value.first?.date else { return false }
            return lhsDate > rhsDate
        }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            if entries.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 50))
                        .foregroundColor(AppColors.textTertiary)
                    Text("No reading entries yet")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textSecondary)
                    Text("Tap + to log your first reading session.")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        ForEach(groupedByBook, id: \.0) { bookTitle, bookEntries in
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                // Book header
                                HStack {
                                    Image(systemName: "book.fill")
                                        .foregroundColor(AppColors.intelligenceColor)
                                    Text(bookTitle)
                                        .font(AppFonts.headline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Spacer()
                                    let totalPages = bookEntries.reduce(0) { $0 + $1.pagesRead }
                                    Text("\(totalPages) pages total")
                                        .font(AppFonts.caption2)
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .padding(.horizontal, AppSpacing.screenHorizontal)
                                
                                VStack(spacing: 0) {
                                    ForEach(bookEntries) { entry in
                                        entryRow(entry)
                                        
                                        if entry.id != bookEntries.last?.id {
                                            Divider()
                                                .background(AppColors.border)
                                                .padding(.leading, 48)
                                        }
                                    }
                                }
                                .background(AppColors.surface)
                                .cornerRadius(AppSpacing.cardCornerRadius)
                                .padding(.horizontal, AppSpacing.screenHorizontal)
                            }
                        }
                    }
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
            }
        }
        .navigationTitle("Reading Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddEntry = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.intelligenceColor)
                }
            }
        }
        .sheet(isPresented: $showAddEntry) {
            AddReadingEntryView()
        }
    }
    
    private func entryRow(_ entry: ReadingEntry) -> some View {
        HStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.pagesRead) pages • \(entry.durationFormatted)")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text(entry.formattedDate)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Text("+\(entry.xpEarned) XP")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.intelligenceColor)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }
}
