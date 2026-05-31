import SwiftUI

/// A progress bar styled for XP display with gradient fill and optional shine animation
struct XPProgressBar: View {
    
    /// Progress value (0.0 to 1.0)
    let progress: Double
    
    /// Optional color override (uses gradient if nil)
    let color: Color?
    
    /// Height of the progress bar
    let height: CGFloat
    
    /// Whether to show the shine animation
    let showShine: Bool
    
    /// Whether to show the percentage label
    let showLabel: Bool
    
    @State private var shineOffset: CGFloat = -1
    
    init(
        progress: Double,
        color: Color? = nil,
        height: CGFloat = AppSpacing.progressBarHeight,
        showShine: Bool = true,
        showLabel: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.height = height
        self.showShine = showShine
        self.showLabel = showLabel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(AppColors.surface)
                
                // Progress fill
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(progressFill)
                    .frame(width: max(0, geometry.size.width * progress))
                    .overlay {
                        // Shine effect
                        if showShine && progress > 0 {
                            shineOverlay(width: geometry.size.width * progress)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: height / 2))
                
                // Label
                if showLabel {
                    Text("\(Int(progress * 100))%")
                        .font(AppFonts.xpNumberSmall)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .frame(height: height)
        .onAppear {
            if showShine {
                startShineAnimation()
            }
        }
    }
    
    /// Progress fill (gradient or solid color)
    private var progressFill: some ShapeStyle {
        if let color = color {
            return AnyShapeStyle(color)
        } else {
            return AnyShapeStyle(AppColors.xpBarGradient)
        }
    }
    
    /// Shine overlay animation
    @ViewBuilder
    private func shineOverlay(width: CGFloat) -> some View {
        LinearGradient(
            colors: [
                .clear,
                Color.white.opacity(0.3),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 40)
        .offset(x: shineOffset * width)
        .mask(
            RoundedRectangle(cornerRadius: height / 2)
        )
    }
    
    /// Start the shine animation
    private func startShineAnimation() {
        withAnimation(
            Animation.linear(duration: 2.0)
                .repeatForever(autoreverses: false)
                .delay(1.0)
        ) {
            shineOffset = 1.5
        }
    }
}

/// XP progress bar with current/max labels
struct XPProgressBarLabeled: View {
    let currentXP: Int
    let maxXP: Int
    let color: Color?
    let height: CGFloat
    
    init(
        currentXP: Int,
        maxXP: Int,
        color: Color? = nil,
        height: CGFloat = AppSpacing.progressBarHeight
    ) {
        self.currentXP = currentXP
        self.maxXP = maxXP
        self.color = color
        self.height = height
    }
    
    private var progress: Double {
        guard maxXP > 0 else { return 0 }
        return Double(currentXP) / Double(maxXP)
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.xxs) {
            XPProgressBar(progress: progress, color: color, height: height)
            
            HStack {
                Text(formatXP(currentXP))
                    .font(AppFonts.xpNumberSmall)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text(formatXP(maxXP))
                    .font(AppFonts.xpNumberSmall)
                    .foregroundColor(AppColors.textSecondary)
            }
        }
    }
    
    private func formatXP(_ xp: Int) -> String {
        if xp >= 1_000_000 {
            return String(format: "%.1fM", Double(xp) / 1_000_000)
        } else if xp >= 1000 {
            return String(format: "%.1fK", Double(xp) / 1000)
        } else {
            return "\(xp)"
        }
    }
}

/// Circular progress indicator for stats
struct CircularProgressBar: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let showLabel: Bool
    
    init(
        progress: Double,
        color: Color = AppColors.primaryBlue,
        lineWidth: CGFloat = 8,
        showLabel: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
        self.showLabel = showLabel
    }
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(AppColors.surface, lineWidth: lineWidth)
            
            // Progress arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 5)
            
            // Label
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
    }
}

#Preview("XP Progress Bar") {
    VStack(spacing: 20) {
        XPProgressBar(progress: 0.75)
        
        XPProgressBar(progress: 0.5, color: AppColors.strengthColor, height: 12)
        
        XPProgressBarLabeled(currentXP: 1250, maxXP: 1667)
        
        XPProgressBar(progress: 0.3, height: 20, showLabel: true)
        
        CircularProgressBar(progress: 0.65, color: AppColors.agilityColor)
            .frame(width: 100, height: 100)
    }
    .padding()
    .background(AppColors.background)
}
