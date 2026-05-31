import SwiftUI

/// Full-screen overlay for level up celebration
struct LevelUpOverlay: View {
    let info: LevelUpInfo
    let onDismiss: () -> Void
    
    @State private var showContent = false
    @State private var showLevel = false
    @State private var showDetails = false
    @State private var showButton = false
    @State private var particleOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    if showButton {
                        onDismiss()
                    }
                }
            
            // Particle effects
            ParticleEmitterView()
                .opacity(particleOpacity)
            
            // Content
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // Level Up text
                if showContent {
                    Text("LEVEL UP!")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(AppColors.accentCyan)
                        .shadow(color: AppColors.accentCyan.opacity(0.8), radius: 20)
                        .transition(.scale.combined(with: .opacity))
                }
                
                // Level number
                if showLevel {
                    VStack(spacing: AppSpacing.xs) {
                        Text("\(info.newLevel)")
                            .font(AppFonts.levelNumber)
                            .foregroundColor(.white)
                            .shadow(color: AppColors.primaryBlue.opacity(0.8), radius: 15)
                        
                        // Rank badge if rank changed
                        if info.isRankUp {
                            HStack(spacing: AppSpacing.sm) {
                                Text("NEW RANK:")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textSecondary)
                                
                                RankBadge(rank: info.rank, size: .medium)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Details
                if showDetails {
                    VStack(spacing: AppSpacing.md) {
                        // Motivational message
                        Text(info.rank.motivationalMessage)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.xl)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer()
                
                // Dismiss button
                if showButton {
                    Button(action: onDismiss) {
                        Text("Continue")
                            .font(AppFonts.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.primaryBlue)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.bottom, AppSpacing.xxl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    /// Animate elements in sequence
    private func startAnimationSequence() {
        // Particles
        withAnimation(.easeIn(duration: 0.3)) {
            particleOpacity = 1
        }
        
        // "Level Up!" text
        withAnimation(AppAnimations.levelUp.delay(0.2)) {
            showContent = true
        }
        
        // Level number
        withAnimation(AppAnimations.bouncySpring.delay(0.5)) {
            showLevel = true
        }
        
        // Details
        withAnimation(AppAnimations.defaultSpring.delay(1.0)) {
            showDetails = true
        }
        
        // Button
        withAnimation(AppAnimations.easeOut.delay(1.5)) {
            showButton = true
        }
    }
}

/// Simple particle emitter for celebration effect
struct ParticleEmitterView: View {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var color: Color
        var opacity: Double
        var rotation: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x, y: particle.y)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        let colors: [Color] = [
            AppColors.primaryBlue,
            AppColors.accentPurple,
            AppColors.accentCyan,
            AppColors.success,
            .white
        ]
        
        for _ in 0..<50 {
            let particle = Particle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 4...12),
                color: colors.randomElement()!,
                opacity: Double.random(in: 0.3...0.8),
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)
        }
        
        // Animate particles
        withAnimation(
            Animation.easeOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            for i in particles.indices {
                particles[i].y -= CGFloat.random(in: 20...50)
                particles[i].opacity = Double.random(in: 0.1...0.5)
            }
        }
    }
}

/// Notification toast view
struct SystemNotificationView: View {
    let notification: SystemNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // Icon
            Image(systemName: notification.type.icon)
                .font(.system(size: 20))
                .foregroundColor(notification.type.color)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                if !notification.message.isEmpty {
                    Text(notification.message)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Dismiss button
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                .stroke(notification.type.color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: notification.type.color.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

/// Stack of notifications
struct NotificationStack: View {
    let notifications: [SystemNotification]
    var onDismiss: ((SystemNotification) -> Void)?
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(notifications) { notification in
                SystemNotificationView(notification: notification) {
                    onDismiss?(notification)
                }
                .transition(.slideFromTop)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.md)
        .animation(AppAnimations.slideIn, value: notifications.count)
    }
}

#Preview("Level Up Overlay") {
    ZStack {
        AppColors.background.ignoresSafeArea()
        
        LevelUpOverlay(
            info: LevelUpInfo(
                oldLevel: 24,
                newLevel: 25,
                rank: .c
            )
        ) {
            print("Dismissed")
        }
    }
}

#Preview("Notifications") {
    ZStack(alignment: .top) {
        AppColors.background.ignoresSafeArea()
        
        NotificationStack(notifications: [
            SystemNotification(title: "Quest Complete!", message: "Daily Steps - +50 XP", type: .questComplete),
            SystemNotification(title: "STR +25 XP", message: "", type: .statIncrease),
            SystemNotification(title: "Warning", message: "You're in the Penalty Zone", type: .warning)
        ])
    }
}
