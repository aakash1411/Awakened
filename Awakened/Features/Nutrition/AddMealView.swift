import SwiftUI
import SwiftData

/// Sheet for logging a meal — search/create food, set servings
struct AddMealView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    
    let mealType: MealType
    var onComplete: (() -> Void)?
    
    @State private var service: NutritionService?
    @State private var searchText = ""
    @State private var searchResults: [FoodItem] = []
    @State private var selectedFood: FoodItem?
    @State private var servings: Double = 1.0
    @State private var showCreateFood = false
    
    private var player: Player? { players.first }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if let food = selectedFood {
                        // Selected food detail
                        selectedFoodView(food)
                    } else {
                        // Search
                        searchView
                    }
                }
            }
            .navigationTitle("Add \(mealType.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .sheet(isPresented: $showCreateFood) {
                FoodSearchView { food in
                    selectedFood = food
                }
            }
            .onAppear {
                if service == nil {
                    service = NutritionService(modelContext: modelContext)
                }
                service?.fetchRecentFoods()
                searchResults = service?.recentFoods ?? []
            }
        }
    }
    
    // MARK: - Search View
    
    private var searchView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textTertiary)
                TextField("Search foods...", text: $searchText)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .onChange(of: searchText) { _, newValue in
                        searchResults = service?.searchFoods(query: newValue) ?? []
                    }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            
            // Create new button
            Button {
                showCreateFood = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Custom Food")
                }
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.vitalityColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(AppColors.vitalityColor.opacity(0.1))
            }
            
            // Results
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchResults) { food in
                        Button {
                            selectedFood = food
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                    HStack(spacing: 4) {
                                        Text("\(food.calories) cal")
                                        Text("•")
                                        Text(food.macroSummary)
                                    }
                                    .font(AppFonts.caption2)
                                    .foregroundColor(AppColors.textTertiary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                            .padding(.vertical, AppSpacing.md)
                        }
                        Divider().background(AppColors.border)
                    }
                }
            }
        }
    }
    
    // MARK: - Selected Food
    
    private func selectedFoodView(_ food: FoodItem) -> some View {
        VStack(spacing: AppSpacing.lg) {
            // Food info
            VStack(spacing: AppSpacing.sm) {
                Text(food.name)
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.textPrimary)
                if let brand = food.brand {
                    Text(brand)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                Text(food.servingSize)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
            // Servings
            VStack(spacing: AppSpacing.sm) {
                Text("Servings")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.lg) {
                    Button { servings = max(0.5, servings - 0.5) } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.textTertiary)
                    }
                    
                    Text(String(format: "%.1f", servings))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 80)
                    
                    Button { servings += 0.5 } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.vitalityColor)
                    }
                }
            }
            
            // Calculated macros
            let cals = Int(Double(food.calories) * servings)
            let prot = food.protein * servings
            let carb = food.carbs * servings
            let fats = food.fat * servings
            
            HStack(spacing: AppSpacing.lg) {
                macroBubble(value: "\(cals)", label: "cal", color: AppColors.vitalityColor)
                macroBubble(value: String(format: "%.0f", prot), label: "protein", color: .blue)
                macroBubble(value: String(format: "%.0f", carb), label: "carbs", color: .orange)
                macroBubble(value: String(format: "%.0f", fats), label: "fat", color: .red)
            }
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            
            Spacer()
            
            // Add buttons
            HStack(spacing: AppSpacing.md) {
                Button {
                    selectedFood = nil
                } label: {
                    Text("Change Food")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                
                Button {
                    logMeal(food)
                } label: {
                    Text("Log Meal")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.vitalityColor)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                }
            }
            .padding(.bottom, AppSpacing.lg)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }
    
    private func macroBubble(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(AppFonts.headline)
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func logMeal(_ food: FoodItem) {
        guard let player = player else { return }
        service?.addMealEntry(
            foodItem: food,
            mealType: mealType,
            servings: servings,
            player: player
        )
        onComplete?()
        dismiss()
    }
}
