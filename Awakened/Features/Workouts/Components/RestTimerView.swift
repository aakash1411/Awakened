import SwiftUI

/// Hevy-style sticky rest timer bar that appears at the bottom of the active workout
struct RestTimerView: View {
    @ObservedObject var timerManager: RestTimerManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(AppColors.surface)
                    
                    Rectangle()
                        .fill(timerColor)
                        .frame(width: geo.size.width * timerManager.progress)
                        .animation(.linear(duration: 1), value: timerManager.progress)
                }
            }
            .frame(height: 3)
            
            // Timer content
            HStack(spacing: AppSpacing.md) {
                // Timer icon
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(timerColor)
                
                // Time display
                HStack(spacing: 4) {
                    Text(timerManager.timeFormatted)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("/ \(timerManager.totalTimeFormatted)")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                // +30s button
                Button {
                    timerManager.addTime(30)
                } label: {
                    Text("+30s")
                        .font(AppFonts.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primaryBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.primaryBlue.opacity(0.15))
                        .cornerRadius(14)
                }
                
                // Skip button
                Button {
                    timerManager.skip()
                } label: {
                    Text("Skip")
                        .font(AppFonts.caption1)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppColors.surface)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.border, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.sm + 2)
        }
        .background(AppColors.background.opacity(0.95))
    }
    
    private var timerColor: Color {
        if timerManager.remainingSeconds <= 5 {
            return .red
        } else if timerManager.remainingSeconds <= 10 {
            return .orange
        }
        return AppColors.primaryBlue
    }
}

/// Compact rest timer shown inline when timer completes
struct RestTimerCompleteBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
            Text("Rest Complete")
                .font(AppFonts.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.green)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.15))
        .cornerRadius(10)
    }
}

#Preview("Rest Timer") {
    VStack {
        Spacer()
        RestTimerView(timerManager: {
            let m = RestTimerManager()
            m.isRunning = true
            m.remainingSeconds = 83
            m.totalSeconds = 90
            m.progress = 83.0 / 90.0
            return m
        }())
    }
    .background(AppColors.backgroundGradient)
}
