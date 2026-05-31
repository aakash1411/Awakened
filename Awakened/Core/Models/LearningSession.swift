import Foundation
import SwiftData

// MARK: - Learning Category

/// Categories of learning activities
enum LearningCategory: String, Codable, CaseIterable, Identifiable {
    case course
    case tutorial
    case podcast
    case research
    case writing
    case coding
    case problemSolving
    case other
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .course: return "Course"
        case .tutorial: return "Tutorial"
        case .podcast: return "Podcast"
        case .research: return "Research"
        case .writing: return "Writing"
        case .coding: return "Coding"
        case .problemSolving: return "Problem Solving"
        case .other: return "Other"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .course: return "graduationcap.fill"
        case .tutorial: return "play.rectangle.fill"
        case .podcast: return "headphones"
        case .research: return "magnifyingglass"
        case .writing: return "pencil.line"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .problemSolving: return "puzzlepiece.fill"
        case .other: return "lightbulb.fill"
        }
    }
}

// MARK: - Learning Source

/// Where the learning session data originated
enum LearningSource: String, Codable, CaseIterable, Identifiable {
    case manual
    case notion
    case github
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .notion: return "Notion"
        case .github: return "GitHub"
        }
    }
    
    /// Badge icon
    var icon: String {
        switch self {
        case .manual: return "pencil.circle.fill"
        case .notion: return "doc.text.fill"
        case .github: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - Learning Session

/// A single learning session tracked for Intelligence XP
@Model
final class LearningSession {
    
    // MARK: - Stored Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Title or topic of the session
    var title: String
    
    /// Category stored as raw string
    var categoryRaw: String
    
    /// Duration in minutes
    var durationMinutes: Double
    
    /// Date of the session
    var date: Date
    
    /// Optional notes
    var notes: String?
    
    /// Source stored as raw string
    var sourceRaw: String
    
    /// XP earned for this session
    var xpEarned: Int
    
    /// Reference to the owning player
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Category enum
    var category: LearningCategory {
        get { LearningCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }
    
    /// Source enum
    var source: LearningSource {
        get { LearningSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Formatted duration
    var durationFormatted: String {
        let mins = Int(durationMinutes)
        if mins >= 60 {
            let hours = mins / 60
            let remainder = mins % 60
            return remainder > 0 ? "\(hours)h \(remainder)m" : "\(hours)h"
        }
        return "\(mins) min"
    }
    
    // MARK: - Initialization
    
    init(
        title: String,
        category: LearningCategory,
        durationMinutes: Double,
        date: Date = Date(),
        notes: String? = nil,
        source: LearningSource = .manual
    ) {
        self.id = UUID()
        self.title = title
        self.categoryRaw = category.rawValue
        self.durationMinutes = durationMinutes
        self.date = date
        self.notes = notes
        self.sourceRaw = source.rawValue
        
        // XP based on duration — courses/coding get higher rates
        let baseMinutes: Double
        switch category {
        case .course, .coding, .problemSolving:
            baseMinutes = durationMinutes * 1.5
        default:
            baseMinutes = durationMinutes
        }
        self.xpEarned = XPCalculator.intelligenceXP(readingMinutes: baseMinutes)
    }
}
