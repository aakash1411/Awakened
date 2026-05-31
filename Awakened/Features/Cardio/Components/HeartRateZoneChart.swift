import SwiftUI

/// Horizontal stacked bar chart showing time distribution across HR zones
struct HeartRateZoneChart: View {
    let zoneDistribution: [HeartRateZone: TimeInterval]
    
    private var totalTime: TimeInterval {
        zoneDistribution.values.reduce(0, +)
    }
    
    private var activeZones: [(zone: HeartRateZone, time: TimeInterval)] {
        HeartRateZone.allCases
            .compactMap { zone in
                guard let time = zoneDistribution[zone], time > 0 else { return nil }
                return (zone, time)
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("HEART RATE ZONES")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            if activeZones.isEmpty {
                Text("No heart rate data available")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, AppSpacing.md)
            } else {
                // Stacked bar
                GeometryReader { geo in
                    HStack(spacing: 1) {
                        ForEach(activeZones, id: \.zone) { item in
                            let fraction = item.time / totalTime
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.zone.color)
                                .frame(width: max(4, geo.size.width * fraction))
                        }
                    }
                }
                .frame(height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                
                // Zone legend rows
                ForEach(activeZones, id: \.zone) { item in
                    ZoneRow(
                        zone: item.zone,
                        time: item.time,
                        percentage: totalTime > 0 ? item.time / totalTime * 100 : 0
                    )
                }
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

/// Single zone row in the legend
private struct ZoneRow: View {
    let zone: HeartRateZone
    let time: TimeInterval
    let percentage: Double
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(zone.color)
                .frame(width: 10, height: 10)
            
            Text("Z\(zone.zoneNumber)")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 24, alignment: .leading)
            
            Text(zone.displayName)
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Text(formatTime(time))
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textPrimary)
                .monospacedDigit()
            
            Text(String(format: "%.0f%%", percentage))
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
                .frame(width: 36, alignment: .trailing)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}
