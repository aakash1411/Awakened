import Foundation
import SwiftData

/// Seeds a starter food database with ~50 common foods on first launch.
/// Inspired by MyFitnessPal's quick-add catalog. All values per the listed serving size.
///
/// Idempotent: only inserts foods that don't already exist by name.
struct FoodDatabase {
    
    private static let seedFlagKey = "foodDatabaseSeededV1"
    
    /// Seed the food database if it hasn't been seeded yet.
    @MainActor
    static func seedIfNeeded(in context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: seedFlagKey) else { return }
        
        // Avoid duplicates if the user already has foods
        let existingDescriptor = FetchDescriptor<FoodItem>()
        let existingNames: Set<String> = (try? context.fetch(existingDescriptor))
            .map { Set($0.map { $0.name.lowercased() }) } ?? []
        
        for entry in seedFoods where !existingNames.contains(entry.name.lowercased()) {
            let food = FoodItem(
                name: entry.name,
                brand: entry.brand,
                servingSize: entry.servingSize,
                calories: entry.calories,
                protein: entry.protein,
                carbs: entry.carbs,
                fat: entry.fat,
                fiber: entry.fiber,
                isCustom: false
            )
            context.insert(food)
        }
        
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
        } catch {
            print("FoodDatabase: failed to seed — \(error)")
        }
    }
    
    // MARK: - Seed Data
    
    private struct SeedEntry {
        let name: String
        let brand: String?
        let servingSize: String
        let calories: Int
        let protein: Double
        let carbs: Double
        let fat: Double
        let fiber: Double
    }
    
    /// Common foods covering proteins, carbs, fats, fruits, vegetables, dairy, drinks, snacks.
    private static let seedFoods: [SeedEntry] = [
        // MARK: Proteins
        .init(name: "Chicken Breast (grilled)",   brand: nil, servingSize: "100 g",      calories: 165, protein: 31,   carbs: 0,    fat: 3.6,  fiber: 0),
        .init(name: "Chicken Thigh (grilled)",    brand: nil, servingSize: "100 g",      calories: 209, protein: 26,   carbs: 0,    fat: 11,   fiber: 0),
        .init(name: "Ground Beef 85/15",          brand: nil, servingSize: "100 g",      calories: 215, protein: 26,   carbs: 0,    fat: 12,   fiber: 0),
        .init(name: "Ground Beef 93/7",           brand: nil, servingSize: "100 g",      calories: 152, protein: 21,   carbs: 0,    fat: 7,    fiber: 0),
        .init(name: "Ribeye Steak",               brand: nil, servingSize: "100 g",      calories: 271, protein: 25,   carbs: 0,    fat: 19,   fiber: 0),
        .init(name: "Salmon (cooked)",            brand: nil, servingSize: "100 g",      calories: 206, protein: 22,   carbs: 0,    fat: 12,   fiber: 0),
        .init(name: "Tuna (canned in water)",     brand: nil, servingSize: "1 can (142 g)", calories: 142, protein: 30, carbs: 0, fat: 1, fiber: 0),
        .init(name: "Tilapia (cooked)",           brand: nil, servingSize: "100 g",      calories: 128, protein: 26,   carbs: 0,    fat: 2.7,  fiber: 0),
        .init(name: "Shrimp (cooked)",            brand: nil, servingSize: "100 g",      calories: 99,  protein: 24,   carbs: 0,    fat: 0.3,  fiber: 0),
        .init(name: "Pork Tenderloin",            brand: nil, servingSize: "100 g",      calories: 143, protein: 26,   carbs: 0,    fat: 3.5,  fiber: 0),
        .init(name: "Bacon",                      brand: nil, servingSize: "1 slice (8 g)", calories: 43,  protein: 3,  carbs: 0.1,  fat: 3.3,  fiber: 0),
        .init(name: "Eggs (whole, large)",        brand: nil, servingSize: "1 egg",      calories: 72,  protein: 6,    carbs: 0.4,  fat: 5,    fiber: 0),
        .init(name: "Egg Whites",                 brand: nil, servingSize: "1 large",    calories: 17,  protein: 3.6,  carbs: 0.2,  fat: 0,    fiber: 0),
        .init(name: "Tofu (firm)",                brand: nil, servingSize: "100 g",      calories: 144, protein: 17,   carbs: 3,    fat: 9,    fiber: 2),
        .init(name: "Tempeh",                     brand: nil, servingSize: "100 g",      calories: 192, protein: 20,   carbs: 8,    fat: 11,   fiber: 0),
        
        // MARK: Carbs / Grains
        .init(name: "White Rice (cooked)",        brand: nil, servingSize: "1 cup (158 g)", calories: 205, protein: 4.3, carbs: 45, fat: 0.4, fiber: 0.6),
        .init(name: "Brown Rice (cooked)",        brand: nil, servingSize: "1 cup (195 g)", calories: 216, protein: 5,   carbs: 45, fat: 1.8, fiber: 3.5),
        .init(name: "Quinoa (cooked)",            brand: nil, servingSize: "1 cup (185 g)", calories: 222, protein: 8,   carbs: 39, fat: 3.6, fiber: 5),
        .init(name: "Oats (rolled, dry)",         brand: nil, servingSize: "1/2 cup (40 g)", calories: 150, protein: 5, carbs: 27, fat: 2.5, fiber: 4),
        .init(name: "Whole Wheat Bread",          brand: nil, servingSize: "1 slice (28 g)", calories: 80, protein: 4, carbs: 14, fat: 1, fiber: 2),
        .init(name: "Bagel (plain)",              brand: nil, servingSize: "1 medium",  calories: 245, protein: 10,   carbs: 48,   fat: 1.5,  fiber: 2),
        .init(name: "Pasta (cooked)",             brand: nil, servingSize: "1 cup (140 g)", calories: 220, protein: 8, carbs: 43, fat: 1.3, fiber: 2.5),
        .init(name: "Sweet Potato (baked)",       brand: nil, servingSize: "1 medium (150 g)", calories: 130, protein: 2.5, carbs: 30, fat: 0.2, fiber: 4),
        .init(name: "Potato (baked)",             brand: nil, servingSize: "1 medium (170 g)", calories: 161, protein: 4.3, carbs: 37, fat: 0.2, fiber: 3.8),
        .init(name: "Tortilla (flour, 8\")",      brand: nil, servingSize: "1 tortilla", calories: 140, protein: 4,   carbs: 23,  fat: 4,    fiber: 1),
        
        // MARK: Fruits
        .init(name: "Banana",                     brand: nil, servingSize: "1 medium (118 g)", calories: 105, protein: 1.3, carbs: 27, fat: 0.4, fiber: 3),
        .init(name: "Apple",                      brand: nil, servingSize: "1 medium (182 g)", calories: 95, protein: 0.5, carbs: 25, fat: 0.3, fiber: 4.4),
        .init(name: "Strawberries",               brand: nil, servingSize: "1 cup (152 g)", calories: 49, protein: 1, carbs: 12, fat: 0.5, fiber: 3),
        .init(name: "Blueberries",                brand: nil, servingSize: "1 cup (148 g)", calories: 84, protein: 1.1, carbs: 21, fat: 0.5, fiber: 3.6),
        .init(name: "Orange",                     brand: nil, servingSize: "1 medium (131 g)", calories: 62, protein: 1.2, carbs: 15, fat: 0.2, fiber: 3),
        .init(name: "Avocado",                    brand: nil, servingSize: "1/2 medium (100 g)", calories: 160, protein: 2, carbs: 9, fat: 15, fiber: 7),
        
        // MARK: Vegetables
        .init(name: "Broccoli (cooked)",          brand: nil, servingSize: "1 cup (156 g)", calories: 55, protein: 3.7, carbs: 11, fat: 0.6, fiber: 5.1),
        .init(name: "Spinach (raw)",              brand: nil, servingSize: "1 cup (30 g)", calories: 7, protein: 0.9, carbs: 1, fat: 0.1, fiber: 0.7),
        .init(name: "Mixed Greens Salad",         brand: nil, servingSize: "2 cups (60 g)", calories: 15, protein: 1.5, carbs: 3, fat: 0.2, fiber: 1.5),
        .init(name: "Bell Pepper",                brand: nil, servingSize: "1 medium (119 g)", calories: 31, protein: 1, carbs: 7, fat: 0.3, fiber: 2.5),
        .init(name: "Carrots (raw)",              brand: nil, servingSize: "1 cup (128 g)", calories: 52, protein: 1.2, carbs: 12, fat: 0.3, fiber: 3.6),
        
        // MARK: Dairy
        .init(name: "Greek Yogurt (plain, nonfat)", brand: nil, servingSize: "1 cup (245 g)", calories: 130, protein: 22, carbs: 9, fat: 0.7, fiber: 0),
        .init(name: "Cottage Cheese (low-fat)",   brand: nil, servingSize: "1 cup (226 g)", calories: 163, protein: 28, carbs: 6.2, fat: 2.3, fiber: 0),
        .init(name: "Cheddar Cheese",             brand: nil, servingSize: "1 oz (28 g)", calories: 113, protein: 7, carbs: 0.4, fat: 9, fiber: 0),
        .init(name: "Milk (2%)",                  brand: nil, servingSize: "1 cup (244 g)", calories: 122, protein: 8, carbs: 12, fat: 4.8, fiber: 0),
        .init(name: "Almond Milk (unsweetened)",  brand: nil, servingSize: "1 cup (240 g)", calories: 30, protein: 1, carbs: 1, fat: 2.5, fiber: 0.5),
        .init(name: "Butter",                     brand: nil, servingSize: "1 tbsp (14 g)", calories: 102, protein: 0.1, carbs: 0, fat: 12, fiber: 0),
        
        // MARK: Fats / Nuts
        .init(name: "Almonds",                    brand: nil, servingSize: "1 oz (28 g)", calories: 164, protein: 6, carbs: 6, fat: 14, fiber: 3.5),
        .init(name: "Peanut Butter",              brand: nil, servingSize: "2 tbsp (32 g)", calories: 188, protein: 8, carbs: 7, fat: 16, fiber: 2),
        .init(name: "Olive Oil",                  brand: nil, servingSize: "1 tbsp (14 g)", calories: 119, protein: 0, carbs: 0, fat: 14, fiber: 0),
        
        // MARK: Beans / Legumes
        .init(name: "Black Beans (cooked)",       brand: nil, servingSize: "1 cup (172 g)", calories: 227, protein: 15, carbs: 41, fat: 0.9, fiber: 15),
        .init(name: "Lentils (cooked)",           brand: nil, servingSize: "1 cup (198 g)", calories: 230, protein: 18, carbs: 40, fat: 0.8, fiber: 16),
        .init(name: "Chickpeas (cooked)",         brand: nil, servingSize: "1 cup (164 g)", calories: 269, protein: 15, carbs: 45, fat: 4.2, fiber: 12.5),
        
        // MARK: Drinks
        .init(name: "Coffee (black)",             brand: nil, servingSize: "1 cup (240 mL)", calories: 2, protein: 0.3, carbs: 0, fat: 0, fiber: 0),
        .init(name: "Orange Juice",               brand: nil, servingSize: "1 cup (248 g)", calories: 112, protein: 1.7, carbs: 26, fat: 0.5, fiber: 0.5),
        .init(name: "Protein Shake (whey)",       brand: nil, servingSize: "1 scoop (30 g) + water", calories: 120, protein: 24, carbs: 3, fat: 1.5, fiber: 1),
        
        // MARK: Snacks / Common Dishes
        .init(name: "Cheeseburger (fast food)",   brand: nil, servingSize: "1 burger",     calories: 535, protein: 25, carbs: 40, fat: 30, fiber: 2),
        .init(name: "Pepperoni Pizza",            brand: nil, servingSize: "1 slice",      calories: 298, protein: 13, carbs: 36, fat: 12, fiber: 2.5),
        .init(name: "Burrito Bowl (chicken)",     brand: nil, servingSize: "1 bowl",       calories: 650, protein: 45, carbs: 65, fat: 22, fiber: 10),
        .init(name: "Caesar Salad (with chicken)", brand: nil, servingSize: "1 salad",     calories: 470, protein: 35, carbs: 12, fat: 32, fiber: 4),
        .init(name: "Sushi Roll (California)",    brand: nil, servingSize: "8 pieces",     calories: 255, protein: 9,  carbs: 38, fat: 7, fiber: 6),
    ]
}
