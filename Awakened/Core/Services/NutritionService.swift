import Foundation
import SwiftData
import Combine

/// Manages meal entries, food items, and daily nutrition tracking
@MainActor
class NutritionService: ObservableObject {
    
    private let modelContext: ModelContext
    
    @Published var todaysMeals: [MealEntry] = []
    @Published var recentFoods: [FoodItem] = []
    @Published var todayCalories: Int = 0
    @Published var todayProtein: Double = 0
    @Published var todayCarbs: Double = 0
    @Published var todayFat: Double = 0
    @Published var todayFiber: Double = 0
    
    /// The currently selected date for browsing meal logs (defaults to today)
    @Published var selectedDate: Date = Date()
    
    // MARK: - Targets (user-configurable)
    
    var calorieTarget: Int {
        UserDefaults.standard.integer(forKey: "calorieTarget").nonZero ?? 2000
    }
    
    var proteinTarget: Double {
        let val = UserDefaults.standard.double(forKey: "proteinTarget")
        return val > 0 ? val : 150
    }
    
    var carbsTarget: Double {
        let val = UserDefaults.standard.double(forKey: "carbsTarget")
        return val > 0 ? val : 250
    }
    
    var fatTarget: Double {
        let val = UserDefaults.standard.double(forKey: "fatTarget")
        return val > 0 ? val : 65
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Fetch Today's Meals
    
    /// Fetch all meals for `selectedDate` grouped by meal type
    func fetchTodaysMeals() {
        fetchMeals(for: selectedDate)
    }
    
    /// Fetch meals for a specific date (updates `selectedDate`)
    func fetchMeals(for date: Date) {
        selectedDate = date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        
        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate { $0.date >= startOfDay && $0.date < endOfDay },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            todaysMeals = try modelContext.fetch(descriptor)
            calculateDailyTotals()
        } catch {
            print("NutritionService: Failed to fetch meals — \(error)")
        }
    }
    
    /// Calculate the selected day's macro totals
    private func calculateDailyTotals() {
        todayCalories = todaysMeals.reduce(0) { $0 + $1.totalCalories }
        todayProtein = todaysMeals.reduce(0.0) { $0 + $1.totalProtein }
        todayCarbs = todaysMeals.reduce(0.0) { $0 + $1.totalCarbs }
        todayFat = todaysMeals.reduce(0.0) { $0 + $1.totalFat }
        todayFiber = todaysMeals.reduce(0.0) { acc, entry in
            acc + (entry.foodItem?.fiber ?? 0) * entry.servings
        }
    }
    
    // MARK: - Add Meal
    
    /// Log a meal entry
    @discardableResult
    func addMealEntry(
        foodItem: FoodItem,
        mealType: MealType,
        servings: Double = 1.0,
        notes: String? = nil,
        player: Player
    ) -> MealEntry {
        // Place the entry on the currently-viewed day at the current time of day
        let entryDate = combineDate(selectedDate, withTimeOf: Date())
        let entry = MealEntry(
            mealType: mealType,
            servings: servings,
            date: entryDate,
            notes: notes
        )
        entry.foodItem = foodItem
        entry.player = player
        
        foodItem.useCount += 1
        
        modelContext.insert(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("NutritionService: Failed to save meal — \(error)")
        }
        
        // Refresh the visible day's totals
        fetchMeals(for: selectedDate)
        
        // Update protein quest progress
        for quest in player.todayQuests where quest.isActive && quest.category == .protein {
            quest.updateProgress(todayProtein)
            if quest.progress >= 1.0 && !quest.isCompleted {
                player.completeQuest(quest)
            }
        }
        
        return entry
    }
    
    /// Delete a meal entry
    func deleteMealEntry(_ entry: MealEntry) {
        modelContext.delete(entry)
        todaysMeals.removeAll { $0.id == entry.id }
        calculateDailyTotals()
        
        do {
            try modelContext.save()
        } catch {
            print("NutritionService: Failed to delete meal — \(error)")
        }
    }
    
    // MARK: - Food Items
    
    /// Create a custom food item
    @discardableResult
    func createFood(
        name: String,
        brand: String? = nil,
        servingSize: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0
    ) -> FoodItem {
        let food = FoodItem(
            name: name,
            brand: brand,
            servingSize: servingSize,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber
        )
        modelContext.insert(food)
        
        do {
            try modelContext.save()
        } catch {
            print("NutritionService: Failed to save food — \(error)")
        }
        
        return food
    }
    
    /// Search food items by name
    func searchFoods(query: String) -> [FoodItem] {
        let descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.useCount, order: .reverse)]
        )
        
        do {
            let allFoods = try modelContext.fetch(descriptor)
            if query.isEmpty { return allFoods }
            return allFoods.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                ($0.brand?.localizedCaseInsensitiveContains(query) ?? false)
            }
        } catch {
            return []
        }
    }
    
    /// Fetch frequently used foods
    func fetchRecentFoods(limit: Int = 10) {
        var descriptor = FetchDescriptor<FoodItem>(
            sortBy: [SortDescriptor(\.useCount, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            recentFoods = try modelContext.fetch(descriptor)
        } catch {
            print("NutritionService: Failed to fetch recent foods — \(error)")
        }
    }
    
    // MARK: - Weekly Stats
    
    /// Fetch meals grouped by day for the current week
    func fetchWeeklyBreakdown() -> [(calories: Int, protein: Double)] {
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        components.weekday = 2
        let weekStart = calendar.date(from: components) ?? now
        
        let descriptor = FetchDescriptor<MealEntry>(
            predicate: #Predicate { $0.date >= weekStart }
        )
        
        var daily = Array(repeating: (calories: 0, protein: 0.0), count: 7)
        
        do {
            let meals = try modelContext.fetch(descriptor)
            for meal in meals {
                let dayIndex = (calendar.component(.weekday, from: meal.date) + 5) % 7
                daily[dayIndex].calories += meal.totalCalories
                daily[dayIndex].protein += meal.totalProtein
            }
        } catch {
            print("NutritionService: Failed to fetch weekly breakdown — \(error)")
        }
        
        return daily
    }
    
    // MARK: - Helpers
    
    /// Combine a calendar day with the time-of-day from another date.
    /// Used so meals logged for a past/future day get a sensible timestamp.
    private func combineDate(_ day: Date, withTimeOf time: Date) -> Date {
        let calendar = Calendar.current
        let dayComps = calendar.dateComponents([.year, .month, .day], from: day)
        let timeComps = calendar.dateComponents([.hour, .minute, .second], from: time)
        var merged = DateComponents()
        merged.year = dayComps.year
        merged.month = dayComps.month
        merged.day = dayComps.day
        merged.hour = timeComps.hour
        merged.minute = timeComps.minute
        merged.second = timeComps.second
        return calendar.date(from: merged) ?? day
    }
}

// MARK: - Int Extension

private extension Int {
    /// Returns self if non-zero, nil otherwise
    var nonZero: Int? {
        self != 0 ? self : nil
    }
}
