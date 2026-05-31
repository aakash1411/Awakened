import SwiftUI
import SwiftData

/// Build a custom food (recipe) by combining multiple FoodItem ingredients.
/// Macros are summed across the chosen ingredients × their servings.
/// Saved as a new FoodItem with `isCustom = true`.
struct RecipeBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var recipeName: String = ""
    @State private var servingsInRecipe: Double = 1.0
    @State private var ingredients: [RecipeIngredient] = []
    @State private var showingFoodPicker = false
    
    private var totalCalories: Int {
        ingredients.reduce(0) { $0 + Int(Double($1.food.calories) * $1.servings) }
    }
    private var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.food.protein * $1.servings }
    }
    private var totalCarbs: Double {
        ingredients.reduce(0) { $0 + $1.food.carbs * $1.servings }
    }
    private var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.food.fat * $1.servings }
    }
    private var totalFiber: Double {
        ingredients.reduce(0) { $0 + $1.food.fiber * $1.servings }
    }
    
    /// Per-serving macros after dividing by servingsInRecipe
    private var perServing: (cal: Int, p: Double, c: Double, f: Double, fi: Double) {
        let s = max(1, servingsInRecipe)
        return (Int(Double(totalCalories) / s),
                totalProtein / s,
                totalCarbs / s,
                totalFat / s,
                totalFiber / s)
    }
    
    private var canSave: Bool {
        !recipeName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !ingredients.isEmpty &&
        servingsInRecipe > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Recipe info
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Recipe Info")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("Recipe name (e.g. Chicken Bowl)", text: $recipeName)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.background)
                                .cornerRadius(AppSpacing.cardCornerRadius)
                            
                            HStack {
                                Text("Total servings this recipe makes")
                                    .font(AppFonts.caption1)
                                    .foregroundColor(AppColors.textSecondary)
                                Spacer()
                                HStack(spacing: AppSpacing.sm) {
                                    Button {
                                        servingsInRecipe = max(1, servingsInRecipe - 1)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(AppColors.textTertiary)
                                    }
                                    Text(String(format: "%.0f", servingsInRecipe))
                                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                                        .foregroundColor(AppColors.textPrimary)
                                        .frame(width: 32)
                                    Button {
                                        servingsInRecipe += 1
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(AppColors.vitalityColor)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Ingredients list
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Text("Ingredients")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Button {
                                    showingFoodPicker = true
                                } label: {
                                    Label("Add", systemImage: "plus.circle.fill")
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(AppColors.vitalityColor)
                                }
                            }
                            
                            if ingredients.isEmpty {
                                Text("Add foods to start building your recipe.")
                                    .font(AppFonts.caption1)
                                    .foregroundColor(AppColors.textTertiary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, AppSpacing.lg)
                            } else {
                                ForEach(ingredients) { ing in
                                    ingredientRow(ing)
                                    Divider().background(AppColors.border)
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Per-serving summary
                        if !ingredients.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Per Serving")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                let ps = perServing
                                HStack(spacing: AppSpacing.lg) {
                                    summaryStat("\(ps.cal)", "cal", AppColors.vitalityColor)
                                    summaryStat(String(format: "%.0f", ps.p), "P", .blue)
                                    summaryStat(String(format: "%.0f", ps.c), "C", .orange)
                                    summaryStat(String(format: "%.0f", ps.f), "F", .red)
                                }
                            }
                            .padding(AppSpacing.cardPadding)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                        }
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Build Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveRecipe() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingFoodPicker) {
                FoodPickerSheet { food, servings in
                    ingredients.append(RecipeIngredient(food: food, servings: servings))
                }
            }
        }
    }
    
    private func ingredientRow(_ ing: RecipeIngredient) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(ing.food.name)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                Text("\(String(format: "%.1f", ing.servings))× \(ing.food.servingSize) • \(Int(Double(ing.food.calories) * ing.servings)) cal")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(AppColors.textTertiary)
            }
            Spacer()
            Button {
                ingredients.removeAll { $0.id == ing.id }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(AppColors.error)
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    private func summaryStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func saveRecipe() {
        let ps = perServing
        let recipe = FoodItem(
            name: recipeName.trimmingCharacters(in: .whitespaces),
            brand: "Custom Recipe",
            servingSize: "1 serving",
            calories: ps.cal,
            protein: ps.p,
            carbs: ps.c,
            fat: ps.f,
            fiber: ps.fi,
            isCustom: true
        )
        modelContext.insert(recipe)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Recipe Ingredient (in-memory only)

struct RecipeIngredient: Identifiable {
    let id = UUID()
    let food: FoodItem
    var servings: Double
}

// MARK: - Food Picker Sheet (for recipe building)

struct FoodPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let onPick: (FoodItem, Double) -> Void
    
    @State private var searchText = ""
    @State private var results: [FoodItem] = []
    @State private var selected: FoodItem?
    @State private var servings: Double = 1.0
    
    private var service: NutritionService {
        NutritionService(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient.ignoresSafeArea()
                
                if let food = selected {
                    selectedView(food)
                } else {
                    searchView
                }
            }
            .navigationTitle(selected == nil ? "Pick Food" : "Set Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(selected == nil ? "Cancel" : "Back") {
                        if selected != nil { selected = nil }
                        else { dismiss() }
                    }
                }
            }
            .onAppear { results = service.searchFoods(query: "") }
        }
    }
    
    private var searchView: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textTertiary)
                TextField("Search foods...", text: $searchText)
                    .onChange(of: searchText) { _, newValue in
                        results = service.searchFoods(query: newValue)
                    }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(results) { food in
                        Button { selected = food } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(food.name)
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(AppColors.textPrimary)
                                    Text("\(food.calories) cal • \(food.servingSize)")
                                        .font(.system(size: 11, design: .monospaced))
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
    
    private func selectedView(_ food: FoodItem) -> some View {
        VStack(spacing: AppSpacing.lg) {
            VStack(spacing: AppSpacing.xs) {
                Text(food.name)
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.textPrimary)
                Text(food.servingSize)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
            
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
            
            Button {
                onPick(food, servings)
                dismiss()
            } label: {
                Text("Add to Recipe")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.vitalityColor)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
            }
            .padding(.horizontal, AppSpacing.lg)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }
}
