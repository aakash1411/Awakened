import Foundation
import SwiftData

/// A single meal log entry
@Model
final class MealEntry {
    
    /// Unique identifier
    var id: UUID
    
    /// Meal type stored as raw string
    var mealTypeRaw: String
    
    /// Number of servings consumed
    var servings: Double
    
    /// Date of the meal
    var date: Date
    
    /// Optional notes
    var notes: String?
    
    /// Reference to the food item
    var foodItem: FoodItem?
    
    /// Reference to the owning player
    var player: Player?
    
    // MARK: - Computed Properties
    
    /// Meal type enum
    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }
    
    /// Calculated calories for this entry
    var totalCalories: Int {
        Int(Double(foodItem?.calories ?? 0) * servings)
    }
    
    /// Calculated protein for this entry
    var totalProtein: Double {
        (foodItem?.protein ?? 0) * servings
    }
    
    /// Calculated carbs for this entry
    var totalCarbs: Double {
        (foodItem?.carbs ?? 0) * servings
    }
    
    /// Calculated fat for this entry
    var totalFat: Double {
        (foodItem?.fat ?? 0) * servings
    }
    
    /// Food name (convenience)
    var foodName: String {
        foodItem?.name ?? "Unknown"
    }
    
    /// Formatted date
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Formatted time
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Initialization
    
    init(
        mealType: MealType,
        servings: Double = 1.0,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = UUID()
        self.mealTypeRaw = mealType.rawValue
        self.servings = servings
        self.date = date
        self.notes = notes
    }
}
