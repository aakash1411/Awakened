import SwiftUI
import SwiftData
import Combine

/// MyFitnessPal-style nutrition tracker with date navigation, calorie + macro rings,
/// and meal sections (Breakfast / Lunch / Dinner / Snacks).
struct NutritionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]
    @StateObject private var service = NutritionServiceHolder()
    
    @State private var addingMealType: MealType?
    @State private var showingTargets = false
    @State private var showingRecipeBuilder = false
    
    private var player: Player? { players.first }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.md) {
                    // Date navigator
                    if let svc = service.service {
                        DateNavigator(
                            date: svc.selectedDate,
                            onPrevious: { changeDay(by: -1) },
                            onNext: { changeDay(by: 1) },
                            onJumpToToday: { jumpToToday() }
                        )
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        
                        // Macro summary
                        MacroSummaryCard(service: svc)
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                        
                        // Meal sections
                        ForEach(MealType.allCases) { mealType in
                            MealSection(
                                mealType: mealType,
                                entries: svc.todaysMeals.filter { $0.mealType == mealType },
                                onAdd: { addingMealType = mealType },
                                onDelete: { entry in deleteMeal(entry) }
                            )
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                        }
                    }
                }
                .padding(.top, AppSpacing.md)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
        .navigationTitle("Nutrition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showingRecipeBuilder = true } label: {
                        Label("Build Custom Meal", systemImage: "square.stack.3d.up")
                    }
                    Button { showingTargets = true } label: {
                        Label("Daily Targets", systemImage: "target")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(item: $addingMealType) { mealType in
            AddMealView(mealType: mealType) {
                service.service?.fetchTodaysMeals()
            }
        }
        .sheet(isPresented: $showingTargets) {
            NutritionTargetsView { service.service?.fetchTodaysMeals() }
        }
        .sheet(isPresented: $showingRecipeBuilder) {
            RecipeBuilderView()
        }
        .onAppear {
            if service.service == nil {
                service.service = NutritionService(modelContext: modelContext)
                service.service?.fetchTodaysMeals()
            }
        }
    }
    
    private func changeDay(by offset: Int) {
        guard let svc = service.service,
              let newDate = Calendar.current.date(byAdding: .day, value: offset, to: svc.selectedDate)
        else { return }
        svc.fetchMeals(for: newDate)
    }
    
    private func jumpToToday() {
        service.service?.fetchMeals(for: Date())
    }
    
    private func deleteMeal(_ entry: MealEntry) {
        service.service?.deleteMealEntry(entry)
    }
}

/// Holds an optional NutritionService — a workaround so we can use @StateObject
/// while still injecting the modelContext on appear.
@MainActor
final class NutritionServiceHolder: ObservableObject {
    @Published var service: NutritionService?
}

// MARK: - Date Navigator

struct DateNavigator: View {
    let date: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onJumpToToday: () -> Void
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    private var dateLabel: String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        if Calendar.current.isDateInTomorrow(date) { return "Tomorrow" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }
            
            Button(action: onJumpToToday) {
                VStack(spacing: 2) {
                    Text(dateLabel)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    if !isToday {
                        Text("tap to return to today")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppColors.surface)
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Macro Summary Card

struct MacroSummaryCard: View {
    @ObservedObject var service: NutritionService
    
    private var calorieRemaining: Int {
        max(0, service.calorieTarget - service.todayCalories)
    }
    
    private var calorieProgress: Double {
        guard service.calorieTarget > 0 else { return 0 }
        return min(1.0, Double(service.todayCalories) / Double(service.calorieTarget))
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Calorie summary row: eaten - exercise + goal = remaining (MFP layout)
            HStack(alignment: .center) {
                VStack(spacing: 2) {
                    Text("\(service.todayCalories)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Eaten")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                
                Text("−")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                
                VStack(spacing: 2) {
                    Text("\(service.calorieTarget)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Goal")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
                
                Text("=")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColors.textTertiary)
                
                VStack(spacing: 2) {
                    Text("\(calorieRemaining)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.vitalityColor)
                    Text("Remaining")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Calorie progress bar
            XPProgressBar(
                progress: calorieProgress,
                color: calorieProgress > 1.0 ? AppColors.error : AppColors.vitalityColor,
                height: 6,
                showShine: false
            )
            
            // Macros row: P / C / F as mini-rings
            HStack(spacing: AppSpacing.lg) {
                MacroRing(
                    label: "Protein",
                    current: service.todayProtein,
                    target: service.proteinTarget,
                    color: .blue,
                    unit: "g"
                )
                MacroRing(
                    label: "Carbs",
                    current: service.todayCarbs,
                    target: service.carbsTarget,
                    color: .orange,
                    unit: "g"
                )
                MacroRing(
                    label: "Fat",
                    current: service.todayFat,
                    target: service.fatTarget,
                    color: .red,
                    unit: "g"
                )
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Macro Ring

struct MacroRing: View {
    let label: String
    let current: Double
    let target: Double
    let color: Color
    let unit: String
    
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(1.0, current / target)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)
                Text("\(Int(current))")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(AppColors.textPrimary)
            }
            .frame(width: 56, height: 56)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
            
            Text("\(Int(current))/\(Int(target)) \(unit)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(AppColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Section

struct MealSection: View {
    let mealType: MealType
    let entries: [MealEntry]
    let onAdd: () -> Void
    let onDelete: (MealEntry) -> Void
    
    private var totalCalories: Int {
        entries.reduce(0) { $0 + $1.totalCalories }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: mealType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                Text(mealType.displayName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Text("\(totalCalories) cal")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding(AppSpacing.md)
            
            // Entries
            if !entries.isEmpty {
                ForEach(entries) { entry in
                    MealEntryRow(entry: entry, onDelete: { onDelete(entry) })
                    Divider().background(AppColors.border)
                }
            }
            
            // Add button
            Button(action: onAdd) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppColors.vitalityColor)
                    Text("Add Food")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.vitalityColor)
                    Spacer()
                }
                .padding(AppSpacing.md)
            }
        }
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

// MARK: - Meal Entry Row

struct MealEntryRow: View {
    let entry: MealEntry
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.foodName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let food = entry.foodItem {
                        Text("\(String(format: "%.1f", entry.servings))× \(food.servingSize)")
                    } else {
                        Text("\(String(format: "%.1f", entry.servings))×")
                    }
                    Text("•")
                    Text("P:\(Int(entry.totalProtein))  C:\(Int(entry.totalCarbs))  F:\(Int(entry.totalFat))")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            Text("\(entry.totalCalories)")
                .font(.system(size: 14, weight: .semibold, design: .monospaced))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Targets Sheet

struct NutritionTargetsView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void
    
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        Text("Set your daily macro targets to track progress against your nutrition goals.")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        targetField("Calories", text: $calories, unit: "cal")
                        targetField("Protein", text: $protein, unit: "g")
                        targetField("Carbs", text: $carbs, unit: "g")
                        targetField("Fat", text: $fat, unit: "g")
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Daily Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { load() }
        }
    }
    
    private func targetField(_ label: String, text: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.textSecondary)
            HStack {
                TextField("0", text: text)
                    .keyboardType(.numberPad)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text(unit)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
    }
    
    private func load() {
        let cal = UserDefaults.standard.integer(forKey: "calorieTarget")
        let p   = UserDefaults.standard.double(forKey: "proteinTarget")
        let c   = UserDefaults.standard.double(forKey: "carbsTarget")
        let f   = UserDefaults.standard.double(forKey: "fatTarget")
        calories = "\(cal > 0 ? cal : 2000)"
        protein  = "\(p > 0 ? Int(p) : 150)"
        carbs    = "\(c > 0 ? Int(c) : 250)"
        fat      = "\(f > 0 ? Int(f) : 65)"
    }
    
    private func save() {
        UserDefaults.standard.set(Int(calories) ?? 2000, forKey: "calorieTarget")
        UserDefaults.standard.set(Double(protein) ?? 150, forKey: "proteinTarget")
        UserDefaults.standard.set(Double(carbs) ?? 250, forKey: "carbsTarget")
        UserDefaults.standard.set(Double(fat) ?? 65, forKey: "fatTarget")
        onSave()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        NutritionView()
    }
    .environmentObject(AppState())
    .modelContainer(for: [Player.self, Stat.self, Quest.self, SyncRecord.self, Exercise.self, WorkoutSession.self, WorkoutSet.self, WorkoutTemplate.self, PersonalRecord.self, ReadingEntry.self, LearningSession.self, Achievement.self, FoodItem.self, MealEntry.self, BodyMeasurement.self], inMemory: true)
}
