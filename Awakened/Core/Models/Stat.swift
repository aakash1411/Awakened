import Foundation
import SwiftData

/// Represents a single stat (Strength, Agility, Vitality, Sense, Intelligence)
@Model
final class Stat {
    
    // MARK: - Stored Properties
    
    /// Unique identifier
    var id: UUID
    
    /// Stat type stored as string for SwiftData compatibility
    var typeRaw: String
    
    /// Current XP accumulated for this stat
    var currentXP: Int
    
    /// Current level of this stat (earned through XP)
    var level: Int
    
    /// Manually allocated stat points from leveling up.
    /// **Deprecated**: stats now auto-level via XP from their activity area.
    /// Kept for SwiftData migration safety; always 0 going forward.
    var allocatedPoints: Int
    
    /// Reference to the owning player
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// The stat type enum
    var type: StatType {
        get { StatType(rawValue: typeRaw) ?? .strength }
        set { typeRaw = newValue.rawValue }
    }
    
    /// Effective level. Now identical to `level` since stats auto-level
    /// via XP earned in their respective activity area (no manual allocation).
    var effectiveLevel: Int {
        level
    }
    
    /// XP required to reach current level
    var xpForCurrentLevel: Int {
        XPCalculator.xpRequired(forLevel: level)
    }
    
    /// XP required to reach next level
    var xpForNextLevel: Int {
        XPCalculator.xpRequired(forLevel: level + 1)
    }
    
    /// XP progress within current level
    var xpProgressInCurrentLevel: Int {
        currentXP - xpForCurrentLevel
    }
    
    /// XP needed to reach next level from current position
    var xpNeededForNextLevel: Int {
        xpForNextLevel - xpForCurrentLevel
    }
    
    /// Progress toward next level (0.0 to 1.0)
    var levelProgress: Double {
        guard xpNeededForNextLevel > 0 else { return 0 }
        return min(max(Double(xpProgressInCurrentLevel) / Double(xpNeededForNextLevel), 0), 1)
    }
    
    /// Display name of this stat
    var displayName: String {
        type.displayName
    }
    
    /// Short name of this stat
    var shortName: String {
        type.shortName
    }
    
    /// Color associated with this stat
    var color: Color {
        type.color
    }
    
    /// Icon for this stat
    var icon: String {
        type.icon
    }
    
    // MARK: - Initialization
    
    /// Create a new stat with default values
    /// - Parameter type: The type of stat to create
    init(type: StatType) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.currentXP = 0
        self.level = 1
        self.allocatedPoints = 0
    }
    
    /// Create a stat with specific values (for testing/migration)
    init(type: StatType, currentXP: Int, level: Int, allocatedPoints: Int) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.currentXP = currentXP
        self.level = level
        self.allocatedPoints = allocatedPoints
    }
    
    // MARK: - Methods
    
    /// Add XP to this stat and check for level up
    /// - Parameter amount: Amount of XP to add
    /// - Returns: Number of levels gained (0 if none)
    @discardableResult
    func addXP(_ amount: Int) -> Int {
        guard amount > 0 else { return 0 }
        
        let previousLevel = level
        currentXP += amount
        checkForLevelUp()
        
        return level - previousLevel
    }
    
    /// Remove XP from this stat (for penalties)
    /// Does not de-level, just reduces XP
    /// - Parameter amount: Amount of XP to remove
    func removeXP(_ amount: Int) {
        guard amount > 0 else { return }
        
        // Don't go below current level's minimum XP
        let minXP = xpForCurrentLevel
        currentXP = max(minXP, currentXP - amount)
    }
    
    /// Check if stat should level up and apply level ups
    private func checkForLevelUp() {
        while currentXP >= xpForNextLevel {
            level += 1
        }
    }
    
}

// MARK: - Comparable

extension Stat: Comparable {
    static func < (lhs: Stat, rhs: Stat) -> Bool {
        lhs.type.displayOrder < rhs.type.displayOrder
    }
    
    static func == (lhs: Stat, rhs: Stat) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Import for Color

import SwiftUI
