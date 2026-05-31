import SwiftUI

/// Table of per-kilometer splits with pace, elevation, and HR
struct PaceSplitsTable: View {
    let splits: [SplitData]
    
    private var averagePace: Double {
        guard !splits.isEmpty else { return 0 }
        return splits.reduce(0) { $0 + $1.paceSecondsPerKm } / Double(splits.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("SPLITS")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            if splits.isEmpty {
                Text("No split data available")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.md)
            } else {
                // Header
                HStack {
                    Text("KM")
                        .frame(width: 30, alignment: .leading)
                    Text("PACE")
                        .frame(width: 50, alignment: .trailing)
                    Text("ELEV")
                        .frame(width: 50, alignment: .trailing)
                    if splits.contains(where: { $0.averageHeartRate != nil }) {
                        Text("HR")
                            .frame(width: 50, alignment: .trailing)
                    }
                    Spacer()
                }
                .font(AppFonts.caption2)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textTertiary)
                
                // Split rows
                ForEach(splits) { split in
                    SplitRow(split: split, averagePace: averagePace, showHR: splits.contains(where: { $0.averageHeartRate != nil }))
                    
                    if split.id != splits.last?.id {
                        Divider()
                            .background(AppColors.border)
                    }
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

/// Single split row
private struct SplitRow: View {
    let split: SplitData
    let averagePace: Double
    let showHR: Bool
    
    /// Color based on pace relative to average
    private var paceColor: Color {
        let diff = split.paceSecondsPerKm - averagePace
        if diff < -10 { return Color(hex: "69F0AE") }       // Faster than avg
        if diff > 10 { return Color(hex: "EF5350") }        // Slower than avg
        return AppColors.textPrimary                          // Near average
    }
    
    var body: some View {
        HStack {
            Text("\(split.number)")
                .font(AppFonts.caption1)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 30, alignment: .leading)
            
            Text(split.paceFormatted)
                .font(AppFonts.caption1)
                .fontWeight(.medium)
                .foregroundColor(paceColor)
                .monospacedDigit()
                .frame(width: 50, alignment: .trailing)
            
            Text(split.elevationFormatted)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 50, alignment: .trailing)
            
            if showHR {
                if let hr = split.averageHeartRate {
                    Text("\(Int(hr))")
                        .font(AppFonts.caption1)
                        .foregroundColor(HeartRateZone.from(bpm: hr).color)
                        .frame(width: 50, alignment: .trailing)
                } else {
                    Text("--")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                        .frame(width: 50, alignment: .trailing)
                }
            }
            
            Spacer()
        }
    }
}
