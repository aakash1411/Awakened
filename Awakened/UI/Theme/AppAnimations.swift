import SwiftUI

/// Centralized animation constants and helpers for the Awakened app
struct AppAnimations {
    
    // MARK: - Durations
    
    /// Fast animation - 0.15s
    static let fast: Double = 0.15
    
    /// Normal animation - 0.3s
    static let normal: Double = 0.3
    
    /// Slow animation - 0.5s
    static let slow: Double = 0.5
    
    /// Very slow animation - 1.0s
    static let verySlow: Double = 1.0
    
    // MARK: - Standard Animations
    
    /// Default spring animation for most transitions
    static let defaultSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    
    /// Gentle spring for subtle movements
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    
    /// Bouncy spring for playful elements
    static let bouncySpring = Animation.spring(response: 0.5, dampingFraction: 0.5)
    
    /// Standard ease out
    static let easeOut = Animation.easeOut(duration: normal)
    
    /// Standard ease in
    static let easeIn = Animation.easeIn(duration: normal)
    
    /// Standard ease in out
    static let easeInOut = Animation.easeInOut(duration: normal)
    
    // MARK: - Special Animations
    
    /// Level up celebration animation
    static let levelUp = Animation.spring(response: 0.6, dampingFraction: 0.6)
    
    /// Stat increase animation
    static let statIncrease = Animation.easeOut(duration: 0.4)
    
    /// Pulse animation (repeating)
    static let pulse = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
    
    /// Glow animation (repeating)
    static let glow = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
    
    /// Shimmer animation for loading states
    static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
    
    // MARK: - Notification Animations
    
    /// Slide in animation for notifications
    static let slideIn = Animation.spring(response: 0.4, dampingFraction: 0.8)
    
    /// Fade out animation
    static let fadeOut = Animation.easeOut(duration: 0.3)
    
    // MARK: - Interactive Animations
    
    /// Press down animation
    static let pressDown = Animation.easeOut(duration: 0.1)
    
    /// Press release animation
    static let pressRelease = Animation.spring(response: 0.3, dampingFraction: 0.6)
}

// MARK: - Animation View Modifiers

extension View {
    /// Apply pulse animation (scale 1.0 to 1.05)
    func pulseAnimation() -> some View {
        modifier(PulseAnimationModifier())
    }
    
    /// Apply glow animation with specified color
    func glowAnimation(color: Color = AppColors.primaryBlue) -> some View {
        modifier(GlowAnimationModifier(glowColor: color))
    }
    
    /// Apply shimmer loading animation
    func shimmerAnimation() -> some View {
        modifier(ShimmerAnimationModifier())
    }
}

// MARK: - Pulse Animation Modifier

struct PulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(AppAnimations.pulse, value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Glow Animation Modifier

struct GlowAnimationModifier: ViewModifier {
    let glowColor: Color
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(color: glowColor.opacity(isGlowing ? 0.8 : 0.3), radius: isGlowing ? 20 : 10)
            .animation(AppAnimations.glow, value: isGlowing)
            .onAppear { isGlowing = true }
    }
}

// MARK: - Shimmer Animation Modifier

struct ShimmerAnimationModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.2),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
            )
            .mask(content)
            .onAppear {
                withAnimation(AppAnimations.shimmer) {
                    phase = 1
                }
            }
    }
}

// MARK: - Transition Helpers

extension AnyTransition {
    /// Slide in from top with fade
    static var slideFromTop: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    /// Scale up with fade
    static var scaleUp: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
    
    /// Slide from bottom with fade
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
}
