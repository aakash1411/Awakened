import Foundation
import SwiftData
import Combine

/// Manages reading entries and learning sessions for Intelligence XP
@MainActor
class IntelligenceService: ObservableObject {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    @Published var recentReadingEntries: [ReadingEntry] = []
    @Published var recentLearningSessions: [LearningSession] = []
    @Published var weeklyReadingMinutes: Double = 0
    @Published var weeklyPagesRead: Int = 0
    @Published var weeklyLearningMinutes: Double = 0
    @Published var weeklyLearningSessions: Int = 0
    @Published var totalIntXP: Int = 0
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Reading Entries
    
    /// Fetch recent reading entries
    /// - Parameter limit: Maximum number of entries
    func fetchRecentReadingEntries(limit: Int = 20) {
        var descriptor = FetchDescriptor<ReadingEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            recentReadingEntries = try modelContext.fetch(descriptor)
        } catch {
            print("IntelligenceService: Failed to fetch reading entries — \(error)")
        }
    }
    
    /// Add a new reading entry
    /// - Parameters:
    ///   - bookTitle: Title of the book
    ///   - author: Author name
    ///   - pagesRead: Pages read
    ///   - minutesRead: Minutes spent reading
    ///   - notes: Optional notes
    ///   - player: The player to associate with
    /// - Returns: The created entry
    @discardableResult
    func addReadingEntry(
        bookTitle: String,
        author: String?,
        pagesRead: Int,
        minutesRead: Double,
        notes: String? = nil,
        player: Player
    ) -> ReadingEntry {
        let entry = ReadingEntry(
            bookTitle: bookTitle,
            author: author,
            pagesRead: pagesRead,
            minutesRead: minutesRead,
            notes: notes
        )
        entry.player = player
        modelContext.insert(entry)
        
        // Apply XP to Intelligence stat
        player.addXP(entry.xpEarned, to: .intelligence)
        
        // Update reading quest progress
        updateReadingQuestProgress(player: player)
        
        do {
            try modelContext.save()
        } catch {
            print("IntelligenceService: Failed to save reading entry — \(error)")
        }
        
        recentReadingEntries.insert(entry, at: 0)
        return entry
    }
    
    /// Delete a reading entry
    func deleteReadingEntry(_ entry: ReadingEntry) {
        modelContext.delete(entry)
        recentReadingEntries.removeAll { $0.id == entry.id }
        
        do {
            try modelContext.save()
        } catch {
            print("IntelligenceService: Failed to delete reading entry — \(error)")
        }
    }
    
    /// Get unique book titles from history (for autocomplete)
    func uniqueBookTitles() -> [String] {
        let descriptor = FetchDescriptor<ReadingEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            let titles = entries.map(\.bookTitle)
            return Array(Set(titles)).sorted()
        } catch {
            return []
        }
    }
    
    // MARK: - Learning Sessions
    
    /// Fetch recent learning sessions
    /// - Parameter limit: Maximum number of sessions
    func fetchRecentLearningSessions(limit: Int = 20) {
        var descriptor = FetchDescriptor<LearningSession>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            recentLearningSessions = try modelContext.fetch(descriptor)
        } catch {
            print("IntelligenceService: Failed to fetch learning sessions — \(error)")
        }
    }
    
    /// Add a new learning session
    /// - Parameters:
    ///   - title: Session title
    ///   - category: Learning category
    ///   - durationMinutes: Duration in minutes
    ///   - notes: Optional notes
    ///   - source: Data source
    ///   - player: The player to associate with
    /// - Returns: The created session
    @discardableResult
    func addLearningSession(
        title: String,
        category: LearningCategory,
        durationMinutes: Double,
        notes: String? = nil,
        source: LearningSource = .manual,
        player: Player
    ) -> LearningSession {
        let session = LearningSession(
            title: title,
            category: category,
            durationMinutes: durationMinutes,
            notes: notes,
            source: source
        )
        session.player = player
        modelContext.insert(session)
        
        // Apply XP to Intelligence stat
        player.addXP(session.xpEarned, to: .intelligence)
        
        // Update learning quest progress
        updateLearningQuestProgress(player: player)
        
        do {
            try modelContext.save()
        } catch {
            print("IntelligenceService: Failed to save learning session — \(error)")
        }
        
        recentLearningSessions.insert(session, at: 0)
        return session
    }
    
    /// Delete a learning session
    func deleteLearningSession(_ session: LearningSession) {
        modelContext.delete(session)
        recentLearningSessions.removeAll { $0.id == session.id }
        
        do {
            try modelContext.save()
        } catch {
            print("IntelligenceService: Failed to delete learning session — \(error)")
        }
    }
    
    // MARK: - Weekly Stats
    
    /// Fetch weekly intelligence stats
    func fetchWeeklyStats() {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2 // Monday
        let weekStart = calendar.date(from: components) ?? now
        
        // Reading stats
        let readingDescriptor = FetchDescriptor<ReadingEntry>(
            predicate: #Predicate { $0.date >= weekStart }
        )
        
        do {
            let weeklyReadings = try modelContext.fetch(readingDescriptor)
            weeklyReadingMinutes = weeklyReadings.reduce(0.0) { $0 + $1.minutesRead }
            weeklyPagesRead = weeklyReadings.reduce(0) { $0 + $1.pagesRead }
        } catch {
            print("IntelligenceService: Failed to fetch weekly reading stats — \(error)")
        }
        
        // Learning stats
        let learningDescriptor = FetchDescriptor<LearningSession>(
            predicate: #Predicate { $0.date >= weekStart }
        )
        
        do {
            let weeklySessions = try modelContext.fetch(learningDescriptor)
            weeklyLearningMinutes = weeklySessions.reduce(0.0) { $0 + $1.durationMinutes }
            weeklyLearningSessions = weeklySessions.count
        } catch {
            print("IntelligenceService: Failed to fetch weekly learning stats — \(error)")
        }
        
        // Total INT XP this week
        totalIntXP = Int(weeklyReadingMinutes * 1.5) + (weeklyPagesRead * 3) + Int(weeklyLearningMinutes * 1.5)
    }
    
    // MARK: - Daily Breakdown
    
    /// Get daily reading + learning minutes for the current week
    /// - Returns: Array of 7 tuples (readingMinutes, learningMinutes)
    func fetchDailyBreakdown() -> [(reading: Double, learning: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2
        let weekStart = calendar.date(from: components) ?? now
        
        var daily = Array(repeating: (reading: 0.0, learning: 0.0), count: 7)
        
        let readingDescriptor = FetchDescriptor<ReadingEntry>(
            predicate: #Predicate { $0.date >= weekStart }
        )
        
        let learningDescriptor = FetchDescriptor<LearningSession>(
            predicate: #Predicate { $0.date >= weekStart }
        )
        
        do {
            let readings = try modelContext.fetch(readingDescriptor)
            for entry in readings {
                let dayIndex = (calendar.component(.weekday, from: entry.date) + 5) % 7
                daily[dayIndex].reading += entry.minutesRead
            }
            
            let sessions = try modelContext.fetch(learningDescriptor)
            for session in sessions {
                let dayIndex = (calendar.component(.weekday, from: session.date) + 5) % 7
                daily[dayIndex].learning += session.durationMinutes
            }
        } catch {
            print("IntelligenceService: Failed to fetch daily breakdown — \(error)")
        }
        
        return daily
    }
    
    // MARK: - Quest Progress
    
    /// Update today's reading quest progress from logged entries
    private func updateReadingQuestProgress(player: Player) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let todayReading = player.readingEntries.filter { $0.date >= startOfDay }
        let totalMinutes = todayReading.reduce(0.0) { $0 + $1.minutesRead }
        
        // Feed both .reading and .knowledge (combined INT) quests
        let totalKnowledge = totalMinutes + player.learningSessions
            .filter { $0.date >= startOfDay }
            .reduce(0.0) { $0 + $1.durationMinutes }
        
        for quest in player.todayQuests where quest.isActive && (quest.category == .reading || quest.category == .knowledge) {
            quest.updateProgress(quest.category == .knowledge ? totalKnowledge : totalMinutes)
            if quest.progress >= 1.0 && !quest.isCompleted {
                player.completeQuest(quest)
            }
        }
    }
    
    /// Update today's learning quest progress from logged sessions
    private func updateLearningQuestProgress(player: Player) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let todayLearning = player.learningSessions.filter { $0.date >= startOfDay }
        let totalMinutes = todayLearning.reduce(0.0) { $0 + $1.durationMinutes }
        
        // Feed both .learning and .knowledge (combined INT) quests
        let totalKnowledge = totalMinutes + player.readingEntries
            .filter { $0.date >= startOfDay }
            .reduce(0.0) { $0 + $1.minutesRead }
        
        for quest in player.todayQuests where quest.isActive && (quest.category == .learning || quest.category == .knowledge) {
            quest.updateProgress(quest.category == .knowledge ? totalKnowledge : totalMinutes)
            if quest.progress >= 1.0 && !quest.isCompleted {
                player.completeQuest(quest)
            }
        }
    }
}
