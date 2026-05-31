import SwiftUI

/// Stacked bar chart showing daily reading + learning minutes
struct WeeklyLearningChart: View {
    let dailyData: [(reading: Double, learning: Double)]
    
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
    
    private var maxMinutes: Double {
        max(dailyData.map { $0.reading + $0.learning }.max() ?? 1, 1)
    }
    
    private var totalReading: Double {
        dailyData.reduce(0) { $0 + $1.reading }
    }
    
    private var totalLearning: Double {
        dailyData.reduce(0) { $0 + $1.learning }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("This Week")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            // Chart
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 2) {
                        let reading = dailyData[index].reading
                        let learning = dailyData[index].learning
                        let total = reading + learning
                        
                        // Learning bar (top)
                        if learning > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppColors.intelligenceColor.opacity(0.5))
                                .frame(height: max(2, CGFloat(learning / maxMinutes) * 70))
                        }
                        
                        // Reading bar (bottom)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(total > 0 ? AppColors.intelligenceColor : AppColors.surface)
                            .frame(height: max(4, CGFloat(reading / maxMinutes) * 70))
                        
                        Text(dayLabels[index])
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
            
            // Legend
            HStack(spacing: AppSpacing.lg) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.intelligenceColor)
                        .frame(width: 8, height: 8)
                    Text("Reading \(String(format: "%.0f", totalReading))m")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppColors.intelligenceColor.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Text("Learning \(String(format: "%.0f", totalLearning))m")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}
