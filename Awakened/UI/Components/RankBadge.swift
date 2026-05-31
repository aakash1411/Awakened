import SwiftUI

/// Displays the player's rank as a badge
struct RankBadge: View {
    let rank: PlayerRank
    let size: BadgeSize
    let showGlow: Bool
    
    enum BadgeSize {
        case small
        case medium
        case large
        
        var diameter: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 60
            case .large: return 80
            }
        }
        
        var fontSize: Font {
            switch self {
            case .small: return .system(size: 16, weight: .black, design: .rounded)
            case .medium: return AppFonts.rankLetter
            case .large: return .system(size: 32, weight: .black, design: .rounded)
            }
        }
        
        var strokeWidth: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }
    
    init(rank: PlayerRank, size: BadgeSize = .medium, showGlow: Bool = true) {
        self.rank = rank
        self.size = size
        self.showGlow = showGlow
    }
    
    var body: some View {
        ZStack {
            // Outer glow
            if showGlow {
                Circle()
                    .fill(rank.color.opacity(0.3))
                    .frame(width: size.diameter + 10, height: size.diameter + 10)
                    .blur(radius: 10)
            }
            
            // Background circle
            Circle()
                .fill(rank.color.opacity(0.2))
                .frame(width: size.diameter, height: size.diameter)
            
            // Border
            Circle()
                .stroke(rank.color, lineWidth: size.strokeWidth)
                .frame(width: size.diameter, height: size.diameter)
            
            // Rank letter
            Text(rank.rawValue)
                .font(size.fontSize)
                .foregroundColor(rank.color)
        }
        .modifier(ConditionalGlowModifier(color: rank.color, isEnabled: showGlow))
    }
}

/// Conditional glow modifier
struct ConditionalGlowModifier: ViewModifier {
    let color: Color
    let isEnabled: Bool
    
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        if isEnabled {
            content
                .shadow(color: color.opacity(isGlowing ? 0.8 : 0.4), radius: isGlowing ? 15 : 8)
                .animation(AppAnimations.glow, value: isGlowing)
                .onAppear { isGlowing = true }
        } else {
            content
        }
    }
}

/// Rank badge with level progress ring
struct RankBadgeWithProgress: View {
    let rank: PlayerRank
    let level: Int
    let progress: Double
    let size: RankBadge.BadgeSize
    
    init(rank: PlayerRank, level: Int, progress: Double, size: RankBadge.BadgeSize = .large) {
        self.rank = rank
        self.level = level
        self.progress = progress
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Progress ring
            Circle()
                .stroke(AppColors.surface, lineWidth: 4)
                .frame(width: size.diameter + 20, height: size.diameter + 20)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    rank.color,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: size.diameter + 20, height: size.diameter + 20)
                .rotationEffect(.degrees(-90))
            
            // Rank badge
            RankBadge(rank: rank, size: size, showGlow: true)
        }
    }
}

/// Horizontal rank display with name and description
struct RankDisplay: View {
    let rank: PlayerRank
    let level: Int
    let showProgress: Bool
    
    init(rank: PlayerRank, level: Int, showProgress: Bool = true) {
        self.rank = rank
        self.level = level
        self.showProgress = showProgress
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            RankBadge(rank: rank, size: .medium)
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(rank.displayName)
                    .font(AppFonts.headline)
                    .foregroundColor(rank.color)
                
                Text(rank.description)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textSecondary)
                
                if showProgress, let nextRank = rank.nextRank {
                    HStack(spacing: AppSpacing.xs) {
                        XPProgressBar(
                            progress: rank.progress(forLevel: level),
                            color: rank.color,
                            height: 4,
                            showShine: false
                        )
                        
                        Text("→ \(nextRank.rawValue)")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
    }
}

#Preview("Rank Badges") {
    ScrollView {
        VStack(spacing: 30) {
            // All ranks
            ForEach(PlayerRank.allCases, id: \.self) { rank in
                HStack(spacing: 20) {
                    RankBadge(rank: rank, size: .small)
                    RankBadge(rank: rank, size: .medium)
                    RankBadge(rank: rank, size: .large, showGlow: false)
                }
            }
            
            Divider()
            
            // With progress
            RankBadgeWithProgress(rank: .b, level: 65, progress: 0.6)
            
            // Full display
            RankDisplay(rank: .a, level: 85)
                .padding()
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
        }
        .padding()
    }
    .background(AppColors.background)
}
