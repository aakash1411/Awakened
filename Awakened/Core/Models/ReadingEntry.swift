import Foundation
import SwiftData

/// A single reading log entry tracked for Intelligence XP
@Model
final class ReadingEntry {
    
    // MARK: - Stored Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Title of the book or article
    var bookTitle: String
    
    /// Author name (optional)
    var author: String?
    
    /// Number of pages read in this entry
    var pagesRead: Int
    
    /// Minutes spent reading
    var minutesRead: Double
    
    /// Date of the reading session
    var date: Date
    
    /// Optional notes about the session
    var notes: String?
    
    /// XP earned for this entry
    var xpEarned: Int
    
    /// Reference to the owning player
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Formatted date string
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Short time string
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Formatted reading duration
    var durationFormatted: String {
        let mins = Int(minutesRead)
        if mins >= 60 {
            let hours = mins / 60
            let remainder = mins % 60
            return remainder > 0 ? "\(hours)h \(remainder)m" : "\(hours)h"
        }
        return "\(mins) min"
    }
    
    /// XP breakdown description
    var xpBreakdown: String {
        let readingXP = Int(minutesRead * 1.5)
        let pagesXP = pagesRead * 3
        return "\(readingXP) (time) + \(pagesXP) (pages)"
    }
    
    // MARK: - Initialization
    
    init(
        bookTitle: String,
        author: String? = nil,
        pagesRead: Int,
        minutesRead: Double,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = UUID()
        self.bookTitle = bookTitle
        self.author = author
        self.pagesRead = pagesRead
        self.minutesRead = minutesRead
        self.date = date
        self.notes = notes
        self.xpEarned = XPCalculator.intelligenceXP(
            readingMinutes: minutesRead,
            pagesRead: pagesRead
        )
    }
}
