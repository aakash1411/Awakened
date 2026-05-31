import SwiftUI
import SwiftData

/// Main hub for Intelligence stat — reading & learning
struct IntelligenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    @State private var service: IntelligenceService?
    @State private var dailyData: [(reading: Double, learning: Double)] = Array(repeating: (0, 0), count: 7)
    @State private var showAddReading = false
    @State private var showAddLearning = false
    
    private var player: Player? { players.first }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Weekly Stats
                    weeklyStatsCard
                    
                    // Weekly Chart
                    WeeklyLearningChart(dailyData: dailyData)
                    
                    // Quick Actions
                    HStack(spacing: AppSpacing.md) {
                        Button {
                            showAddReading = true
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Log Reading")
                            }
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.intelligenceColor)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        
                        Button {
                            showAddLearning = true
                        } label: {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                Text("Log Learning")
                            }
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.intelligenceColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.intelligenceColor.opacity(0.15))
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                    }
                    
                    // Reading Log
                    readingSection
                    
                    // Learning Sessions
                    learningSection
                    
                    // Integrations
                    integrationsCard
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Intelligence")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showAddReading) {
            AddReadingEntryView { _ in refreshData() }
        }
        .sheet(isPresented: $showAddLearning) {
            AddLearningSessionView { _ in refreshData() }
        }
        .onAppear {
            if service == nil {
                service = IntelligenceService(modelContext: modelContext)
            }
            refreshData()
        }
    }
    
    private func refreshData() {
        service?.fetchRecentReadingEntries()
        service?.fetchRecentLearningSessions()
        service?.fetchWeeklyStats()
        dailyData = service?.fetchDailyBreakdown() ?? Array(repeating: (0, 0), count: 7)
    }
    
    // MARK: - Weekly Stats Card
    
    private var weeklyStatsCard: some View {
        HStack(spacing: AppSpacing.lg) {
            statBubble(
                value: String(format: "%.0f", service?.weeklyReadingMinutes ?? 0),
                label: "Reading",
                icon: "book.fill"
            )
            statBubble(
                value: "\(service?.weeklyPagesRead ?? 0)",
                label: "Pages",
                icon: "doc.text.fill"
            )
            statBubble(
                value: "\(service?.weeklyLearningSessions ?? 0)",
                label: "Sessions",
                icon: "lightbulb.fill"
            )
            statBubble(
                value: "\(service?.totalIntXP ?? 0)",
                label: "INT XP",
                icon: "sparkles"
            )
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func statBubble(value: String, label: String, icon: String) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppColors.intelligenceColor)
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Reading Section
    
    private var readingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Reading Log")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                NavigationLink {
                    ReadingLogView()
                } label: {
                    Text("See All")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.intelligenceColor)
                }
            }
            
            if let entries = service?.recentReadingEntries, !entries.isEmpty {
                ForEach(entries.prefix(3)) { entry in
                    readingRow(entry)
                }
            } else {
                emptyState(icon: "book.closed.fill", text: "No reading entries yet")
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func readingRow(_ entry: ReadingEntry) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "book.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.intelligenceColor)
                .frame(width: 32, height: 32)
                .background(AppColors.intelligenceColor.opacity(0.15))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.bookTitle)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text("\(entry.pagesRead) pages • \(entry.durationFormatted)")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Text("+\(entry.xpEarned) XP")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.intelligenceColor)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Learning Section
    
    private var learningSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Learning Sessions")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                NavigationLink {
                    LearningSessionsView()
                } label: {
                    Text("See All")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.intelligenceColor)
                }
            }
            
            if let sessions = service?.recentLearningSessions, !sessions.isEmpty {
                ForEach(sessions.prefix(3)) { session in
                    learningRow(session)
                }
            } else {
                emptyState(icon: "lightbulb", text: "No learning sessions yet")
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func learningRow(_ session: LearningSession) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: session.category.icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.intelligenceColor)
                .frame(width: 32, height: 32)
                .background(AppColors.intelligenceColor.opacity(0.15))
                .cornerRadius(6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                Text("\(session.category.displayName) • \(session.durationFormatted)")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Text("+\(session.xpEarned) XP")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.intelligenceColor)
        }
        .padding(.vertical, 2)
    }
    
    // MARK: - Integrations Card
    
    private var integrationsCard: some View {
        NavigationLink {
            IntegrationSettingsView()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "link")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.intelligenceColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Integrations")
                        .font(AppFonts.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Connect Notion & GitHub")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Empty State
    
    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(AppColors.textTertiary)
            Text(text)
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
    }
}
