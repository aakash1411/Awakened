import SwiftUI

/// A view modifier that adds a glowing border effect
struct GlowBorderModifier: ViewModifier {
    let color: Color
    let lineWidth: CGFloat
    let radius: CGFloat
    let cornerRadius: CGFloat
    
    init(
        color: Color = AppColors.primaryBlue,
        lineWidth: CGFloat = 2,
        radius: CGFloat = 15,
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius
    ) {
        self.color = color
        self.lineWidth = lineWidth
        self.radius = radius
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: lineWidth)
                    .shadow(color: color.opacity(0.8), radius: radius)
            )
    }
}

/// A view modifier that adds an inner glow effect
struct InnerGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    init(color: Color = AppColors.primaryBlue, radius: CGFloat = 10) {
        self.color = color
        self.radius = radius
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                content
                    .blur(radius: radius)
                    .opacity(0.5)
                    .blendMode(.overlay)
            )
    }
}

/// A view modifier that adds a neon text glow effect
struct NeonTextModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    init(color: Color = AppColors.primaryBlue, radius: CGFloat = 8) {
        self.color = color
        self.radius = radius
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .shadow(color: color.opacity(0.8), radius: radius / 2)
            .shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius * 1.5)
    }
}

/// A view modifier that creates a holographic card effect
struct HolographicCardModifier: ViewModifier {
    let baseColor: Color
    @State private var gradientPosition: CGFloat = 0
    
    init(baseColor: Color = AppColors.surface) {
        self.baseColor = baseColor
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    baseColor
                    
                    LinearGradient(
                        colors: [
                            Color.clear,
                            AppColors.primaryBlue.opacity(0.1),
                            AppColors.accentPurple.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.primaryBlue.opacity(0.5),
                                AppColors.accentPurple.opacity(0.3),
                                AppColors.accentCyan.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: AppColors.glowBlue, radius: 10, x: 0, y: 5)
    }
}

// MARK: - View Extensions

extension View {
    /// Add a glowing border effect
    func glowBorder(
        color: Color = AppColors.primaryBlue,
        lineWidth: CGFloat = 2,
        radius: CGFloat = 15,
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius
    ) -> some View {
        modifier(GlowBorderModifier(
            color: color,
            lineWidth: lineWidth,
            radius: radius,
            cornerRadius: cornerRadius
        ))
    }
    
    /// Add an inner glow effect
    func innerGlow(color: Color = AppColors.primaryBlue, radius: CGFloat = 10) -> some View {
        modifier(InnerGlowModifier(color: color, radius: radius))
    }
    
    /// Add a neon text glow effect
    func neonGlow(color: Color = AppColors.primaryBlue, radius: CGFloat = 8) -> some View {
        modifier(NeonTextModifier(color: color, radius: radius))
    }
    
    /// Apply holographic card styling
    func holographicCard(baseColor: Color = AppColors.surface) -> some View {
        modifier(HolographicCardModifier(baseColor: baseColor))
    }
}
