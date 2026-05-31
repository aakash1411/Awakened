import SwiftUI
import SwiftData

/// View for creating a custom food item
struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var onSelect: ((FoodItem) -> Void)?
    
    @State private var name = ""
    @State private var brand = ""
    @State private var servingSize = "1 serving"
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var fiber = ""
    
    private var isValid: Bool {
        !name.isEmpty && (Int(calories) ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Basic info
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Food Info")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            inputField("Food name *", text: $name)
                            inputField("Brand (optional)", text: $brand)
                            inputField("Serving size", text: $servingSize)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Nutrition
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Nutrition Facts")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack(spacing: AppSpacing.md) {
                                numberField("Calories *", text: $calories)
                                numberField("Protein (g)", text: $protein)
                            }
                            HStack(spacing: AppSpacing.md) {
                                numberField("Carbs (g)", text: $carbs)
                                numberField("Fat (g)", text: $fat)
                            }
                            numberField("Fiber (g)", text: $fiber)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Save
                        Button {
                            saveFood()
                        } label: {
                            Text("Create Food")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(isValid ? AppColors.vitalityColor : AppColors.textTertiary)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        .disabled(!isValid)
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Create Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
    
    private func inputField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppFonts.body)
            .foregroundColor(AppColors.textPrimary)
            .padding(AppSpacing.md)
            .background(AppColors.surface.opacity(0.5))
            .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func numberField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppFonts.body)
            .foregroundColor(AppColors.textPrimary)
            .keyboardType(.numberPad)
            .padding(AppSpacing.md)
            .background(AppColors.surface.opacity(0.5))
            .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func saveFood() {
        let service = NutritionService(modelContext: modelContext)
        let food = service.createFood(
            name: name,
            brand: brand.isEmpty ? nil : brand,
            servingSize: servingSize,
            calories: Int(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            fiber: Double(fiber) ?? 0
        )
        onSelect?(food)
        dismiss()
    }
}
