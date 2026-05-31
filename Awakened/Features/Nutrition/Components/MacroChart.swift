import SwiftUI

/// Donut chart showing macro breakdown (P/C/F)
struct MacroChart: View {
    let protein: Double
    let carbs: Double
    let fat: Double
    
    private var total: Double {
        max(protein + carbs + fat, 1)
    }
    
    private var proteinAngle: Double { protein / total * 360 }
    private var carbsAngle: Double { carbs / total * 360 }
    private var fatAngle: Double { fat / total * 360 }
    
    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                // Fat arc
                arcSegment(
                    startAngle: proteinAngle + carbsAngle,
                    endAngle: proteinAngle + carbsAngle + fatAngle,
                    color: .red
                )
                
                // Carbs arc
                arcSegment(
                    startAngle: proteinAngle,
                    endAngle: proteinAngle + carbsAngle,
                    color: .orange
                )
                
                // Protein arc
                arcSegment(
                    startAngle: 0,
                    endAngle: proteinAngle,
                    color: .blue
                )
                
                // Center label
                VStack(spacing: 0) {
                    Text("\(Int(total))g")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    Text("total")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .frame(width: 100, height: 100)
            
            // Legend
            HStack(spacing: AppSpacing.md) {
                legendItem(color: .blue, label: "Protein", value: protein)
                legendItem(color: .orange, label: "Carbs", value: carbs)
                legendItem(color: .red, label: "Fat", value: fat)
            }
        }
    }
    
    private func arcSegment(startAngle: Double, endAngle: Double, color: Color) -> some View {
        Circle()
            .trim(from: startAngle / 360, to: endAngle / 360)
            .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
            .frame(width: 80, height: 80)
            .rotationEffect(.degrees(-90))
    }
    
    private func legendItem(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(String(format: "%.0fg %@", value, label))
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
        }
    }
}
