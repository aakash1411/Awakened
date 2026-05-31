import Foundation
import SwiftData

// MARK: - Meal Type

/// Types of meals
enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast
    case lunch
    case dinner
    case snack
    
    var id: String { rawValue }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        }
    }
    
    /// SF Symbol icon
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }
}

// MARK: - Food Item

/// A single food item with nutritional info
@Model
final class FoodItem {
    
    /// Unique identifier
    var id: UUID
    
    /// Food name
    var name: String
    
    /// Brand or source (optional)
    var brand: String?
    
    /// Serving size description (e.g., "1 cup", "100g")
    var servingSize: String
    
    /// Calories per serving
    var calories: Int
    
    /// Protein in grams
    var protein: Double
    
    /// Carbohydrates in grams
    var carbs: Double
    
    /// Fat in grams
    var fat: Double
    
    /// Fiber in grams (optional)
    var fiber: Double
    
    /// Whether this is a user-created custom food
    var isCustom: Bool
    
    /// How many times this food has been logged (for sorting by frequency)
    var useCount: Int
    
    /// Relationship to meal entries
    @Relationship(deleteRule: .nullify, inverse: \MealEntry.foodItem)
    var mealEntries: [MealEntry]
    
    // MARK: - Computed
    
    /// Total macros summary
    var macroSummary: String {
        "P: \(String(format: "%.0f", protein))g  C: \(String(format: "%.0f", carbs))g  F: \(String(format: "%.0f", fat))g"
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        brand: String? = nil,
        servingSize: String = "1 serving",
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0,
        isCustom: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.isCustom = isCustom
        self.useCount = 0
        self.mealEntries = []
    }
}
