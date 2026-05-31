import SwiftUI

/// User-configurable quest targets and category toggles
struct QuestConfigView: View {
    @State private var questTargets: [String: Double] = [:]
    @State private var disabledCategories: Set<String> = []
    
    private let configurableCategories: [QuestCategory] = QuestCategory.defaultDailyCategories
    
    private let targetsKey = "questCustomTargets"
    private let disabledKey = "questDisabledCategories"
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Info
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppColors.primaryBlue)
                        Text("Customize daily quest targets and toggle categories on or off.")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(AppSpacing.cardPadding)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                    
                    // Category rows
                    ForEach(configurableCategories) { category in
                        questCategoryRow(category)
                    }
                    
                    // Reset button
                    Button {
                        resetToDefaults()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(AppColors.error.opacity(0.1))
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Quest Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadSettings() }
        .onDisappear { saveSettings() }
    }
    
    // MARK: - Category Row
    
    private func questCategoryRow(_ category: QuestCategory) -> some View {
        let isEnabled = !disabledCategories.contains(category.rawValue)
        let target = questTargets[category.rawValue] ?? category.defaultTarget
        
        return VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isEnabled ? category.relatedStat.color : AppColors.textTertiary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.displayName)
                        .font(AppFonts.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isEnabled ? AppColors.textPrimary : AppColors.textTertiary)
                    
                    Text(category.instructions)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Target: \(formattedTarget(target, unit: category.unit))")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { isEnabled },
                    set: { newValue in
                        if newValue {
                            disabledCategories.remove(category.rawValue)
                        } else {
                            disabledCategories.insert(category.rawValue)
                        }
                    }
                ))
                .tint(AppColors.primaryBlue)
            }
            
            if isEnabled {
                Slider(
                    value: Binding(
                        get: { questTargets[category.rawValue] ?? category.defaultTarget },
                        set: { questTargets[category.rawValue] = $0 }
                    ),
                    in: sliderRange(for: category),
                    step: sliderStep(for: category)
                )
                .tint(category.relatedStat.color)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Helpers
    
    private func formattedTarget(_ value: Double, unit: String) -> String {
        if value == Double(Int(value)) {
            return "\(Int(value)) \(unit)"
        }
        return String(format: "%.1f %@", value, unit)
    }
    
    private func sliderRange(for category: QuestCategory) -> ClosedRange<Double> {
        switch category {
        case .steps: return 3000...20000
        case .water: return 4...16
        case .protein: return 50...300
        case .workout: return 15...120
        case .sleep: return 5...10
        case .meditation: return 5...60
        case .reading: return 10...120
        case .cardioDistance: return 10...90
        case .flexibility: return 10...60
        case .learning: return 10...120
        case .strength: return 20...200
        case .knowledge: return 10...120
        case .custom: return 1...100
        }
    }
    
    private func sliderStep(for category: QuestCategory) -> Double {
        switch category {
        case .steps: return 1000
        case .water: return 1
        case .protein: return 10
        case .workout: return 5
        case .sleep: return 0.5
        case .meditation: return 5
        case .reading: return 5
        case .cardioDistance: return 5
        case .flexibility: return 5
        case .learning: return 5
        case .strength: return 5
        case .knowledge: return 5
        case .custom: return 1
        }
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        if let data = UserDefaults.standard.dictionary(forKey: targetsKey) as? [String: Double] {
            questTargets = data
        }
        if let disabled = UserDefaults.standard.array(forKey: disabledKey) as? [String] {
            disabledCategories = Set(disabled)
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(questTargets, forKey: targetsKey)
        UserDefaults.standard.set(Array(disabledCategories), forKey: disabledKey)
    }
    
    private func resetToDefaults() {
        questTargets = [:]
        disabledCategories = []
        UserDefaults.standard.removeObject(forKey: targetsKey)
        UserDefaults.standard.removeObject(forKey: disabledKey)
    }
}
