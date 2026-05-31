import SwiftUI

/// A card component with glowing border effect
struct GlowingCard<Content: View>: View {
    let glowColor: Color
    let backgroundColor: Color
    let cornerRadius: CGFloat
    let glowRadius: CGFloat
    let borderWidth: CGFloat
    let content: () -> Content
    
    @State private var isGlowing = false
    
    init(
        glowColor: Color = AppColors.primaryBlue,
        backgroundColor: Color = AppColors.surface,
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius,
        glowRadius: CGFloat = 15,
        borderWidth: CGFloat = 1,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.glowColor = glowColor
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.glowRadius = glowRadius
        self.borderWidth = borderWidth
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(AppSpacing.cardPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(0.5), lineWidth: borderWidth)
            )
            .shadow(
                color: glowColor.opacity(isGlowing ? 0.6 : 0.3),
                radius: isGlowing ? glowRadius : glowRadius / 2
            )
            .animation(AppAnimations.glow, value: isGlowing)
            .onAppear { isGlowing = true }
    }
}

/// A card with a colored left border accent
struct AccentCard<Content: View>: View {
    let accentColor: Color
    let backgroundColor: Color
    let accentWidth: CGFloat
    let content: () -> Content
    
    init(
        accentColor: Color = AppColors.primaryBlue,
        backgroundColor: Color = AppColors.surface,
        accentWidth: CGFloat = 4,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.accentWidth = accentWidth
        self.content = content
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Accent bar
            Rectangle()
                .fill(accentColor)
                .frame(width: accentWidth)
            
            // Content
            content()
                .padding(AppSpacing.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(backgroundColor)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .shadow(color: accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

/// A holographic-style card with gradient border
struct HolographicCard<Content: View>: View {
    let content: () -> Content
    
    @State private var gradientRotation: Double = 0
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(AppSpacing.cardPadding)
            .background(
                ZStack {
                    AppColors.surface
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [
                            AppColors.primaryBlue.opacity(0.05),
                            AppColors.accentPurple.opacity(0.05),
                            AppColors.accentCyan.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(
                        AngularGradient(
                            colors: [
                                AppColors.primaryBlue.opacity(0.5),
                                AppColors.accentPurple.opacity(0.3),
                                AppColors.accentCyan.opacity(0.5),
                                AppColors.primaryBlue.opacity(0.5)
                            ],
                            center: .center,
                            angle: .degrees(gradientRotation)
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: AppColors.glowBlue, radius: 10, x: 0, y: 5)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 8)
                        .repeatForever(autoreverses: false)
                ) {
                    gradientRotation = 360
                }
            }
    }
}

/// A pressable card with scale animation
struct PressableCard<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    
    @State private var isPressed = false
    
    init(
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
                .padding(AppSpacing.cardPadding)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Button style for pressable cards
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(AppAnimations.pressDown, value: configuration.isPressed)
    }
}

#Preview("Glowing Cards") {
    ScrollView {
        VStack(spacing: 20) {
            GlowingCard(glowColor: AppColors.strengthColor) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppColors.strengthColor)
                    Text("Strength Card")
                        .foregroundColor(.white)
                    Spacer()
                }
            }
            
            AccentCard(accentColor: AppColors.agilityColor) {
                VStack(alignment: .leading) {
                    Text("Agility")
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                    Text("Level 15")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            HolographicCard {
                VStack {
                    Text("Holographic")
                        .font(AppFonts.title2)
                        .foregroundColor(.white)
                    Text("Premium card style")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            PressableCard(action: { print("Tapped!") }) {
                HStack {
                    Text("Tap Me")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .padding()
    }
    .background(AppColors.background)
}
