import SwiftUI

/// Compact nutrition stats card for the dashboard
struct NutritionStatsCard: View {
    let calories: Int
    let calorieTarget: Int
    let protein: Double
    let proteinTarget: Double
    
    private var progress: Double {
        guard calorieTarget > 0 else { return 0 }
        return min(Double(calories) / Double(calorieTarget), 1.0)
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Mini calorie ring
            ZStack {
                Circle()
                    .stroke(AppColors.surface, lineWidth: 4)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.vitalityColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(calories) / \(calorieTarget) cal")
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                Text(String(format: "%.0fg / %.0fg protein", protein, proteinTarget))
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
