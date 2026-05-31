import SwiftUI

/// A view modifier that creates a pulsing scale effect
struct PulseScaleModifier: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    let duration: Double
    
    @State private var isPulsing = false
    
    init(minScale: CGFloat = 1.0, maxScale: CGFloat = 1.05, duration: Double = 1.5) {
        self.minScale = minScale
        self.maxScale = maxScale
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? maxScale : minScale)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

/// A view modifier that creates a pulsing opacity effect
struct PulseOpacityModifier: ViewModifier {
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double
    
    @State private var isPulsing = false
    
    init(minOpacity: Double = 0.6, maxOpacity: Double = 1.0, duration: Double = 1.5) {
        self.minOpacity = minOpacity
        self.maxOpacity = maxOpacity
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? maxOpacity : minOpacity)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

/// A view modifier that creates a breathing glow effect
struct BreathingGlowModifier: ViewModifier {
    let color: Color
    let minRadius: CGFloat
    let maxRadius: CGFloat
    let duration: Double
    
    @State private var isBreathing = false
    
    init(
        color: Color = AppColors.primaryBlue,
        minRadius: CGFloat = 5,
        maxRadius: CGFloat = 15,
        duration: Double = 2.0
    ) {
        self.color = color
        self.minRadius = minRadius
        self.maxRadius = maxRadius
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isBreathing ? 0.8 : 0.4),
                radius: isBreathing ? maxRadius : minRadius
            )
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear { isBreathing = true }
    }
}

/// A view modifier that creates a shake effect (for errors/warnings)
struct ShakeModifier: ViewModifier {
    let amount: CGFloat
    let shakesPerUnit: Int
    var animatableData: CGFloat
    
    init(amount: CGFloat = 10, shakesPerUnit: Int = 3, animatableData: CGFloat) {
        self.amount = amount
        self.shakesPerUnit = shakesPerUnit
        self.animatableData = animatableData
    }
    
    func body(content: Content) -> some View {
        content
            .offset(x: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)))
    }
}

/// A view modifier for attention-grabbing bounce effect
struct BounceModifier: ViewModifier {
    @State private var isBouncing = false
    let height: CGFloat
    let duration: Double
    
    init(height: CGFloat = 5, duration: Double = 0.5) {
        self.height = height
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isBouncing ? -height : 0)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isBouncing
            )
            .onAppear { isBouncing = true }
    }
}

// MARK: - View Extensions

extension View {
    /// Add a pulsing scale effect
    func pulseScale(
        minScale: CGFloat = 1.0,
        maxScale: CGFloat = 1.05,
        duration: Double = 1.5
    ) -> some View {
        modifier(PulseScaleModifier(minScale: minScale, maxScale: maxScale, duration: duration))
    }
    
    /// Add a pulsing opacity effect
    func pulseOpacity(
        minOpacity: Double = 0.6,
        maxOpacity: Double = 1.0,
        duration: Double = 1.5
    ) -> some View {
        modifier(PulseOpacityModifier(minOpacity: minOpacity, maxOpacity: maxOpacity, duration: duration))
    }
    
    /// Add a breathing glow effect
    func breathingGlow(
        color: Color = AppColors.primaryBlue,
        minRadius: CGFloat = 5,
        maxRadius: CGFloat = 15,
        duration: Double = 2.0
    ) -> some View {
        modifier(BreathingGlowModifier(
            color: color,
            minRadius: minRadius,
            maxRadius: maxRadius,
            duration: duration
        ))
    }
    
    /// Add a shake effect
    func shake(amount: CGFloat = 10, shakesPerUnit: Int = 3, trigger: CGFloat) -> some View {
        modifier(ShakeModifier(amount: amount, shakesPerUnit: shakesPerUnit, animatableData: trigger))
    }
    
    /// Add a bounce effect
    func bounce(height: CGFloat = 5, duration: Double = 0.5) -> some View {
        modifier(BounceModifier(height: height, duration: duration))
    }
}
