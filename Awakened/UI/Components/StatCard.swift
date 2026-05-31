import SwiftUI

/// Card displaying a single stat with level and XP progress
struct StatCard: View {
    let stat: Stat
    let showDetails: Bool
    let onTap: (() -> Void)?
    
    init(stat: Stat, showDetails: Bool = true, onTap: (() -> Void)? = nil) {
        self.stat = stat
        self.showDetails = showDetails
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 0) {
                // Colored accent bar
                Rectangle()
                    .fill(stat.color)
                    .frame(width: 4)
                
                // Content
                HStack(spacing: AppSpacing.md) {
                    // Icon
                    Image(systemName: stat.icon)
                        .font(.system(size: 24))
                        .foregroundColor(stat.color)
                        .frame(width: 40)
                    
                    // Info
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        HStack {
                            Text(stat.displayName)
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            Spacer()
                            
                            if onTap != nil {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                        }
                        
                        Text("Level \(stat.effectiveLevel)")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textSecondary)
                        
                        if showDetails {
                            // XP Progress bar
                            XPProgressBar(
                                progress: stat.levelProgress,
                                color: stat.color,
                                height: 6,
                                showShine: false
                            )
                            
                            // XP text
                            Text("\(formatNumber(stat.xpProgressInCurrentLevel)) / \(formatNumber(stat.xpNeededForNextLevel)) XP")
                                .font(AppFonts.xpNumberSmall)
                                .foregroundColor(AppColors.textTertiary)
                        }
                    }
                }
                .padding(AppSpacing.cardPadding)
            }
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .shadow(color: stat.color.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        }
        return "\(number)"
    }
}

/// Compact stat card for grid layouts
struct StatCardCompact: View {
    let stat: Stat
    let onTap: (() -> Void)?
    
    init(stat: Stat, onTap: (() -> Void)? = nil) {
        self.stat = stat
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: AppSpacing.sm) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(stat.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: stat.icon)
                        .font(.system(size: 24))
                        .foregroundColor(stat.color)
                }
                .shadow(color: stat.color.opacity(0.5), radius: 8)
                
                // Name
                Text(stat.shortName)
                    .font(AppFonts.statLabel)
                    .foregroundColor(AppColors.textSecondary)
                
                // Level
                Text("\(stat.effectiveLevel)")
                    .font(AppFonts.statValueSmall)
                    .foregroundColor(stat.color)
                
                // Progress
                XPProgressBar(
                    progress: stat.levelProgress,
                    color: stat.color,
                    height: 4,
                    showShine: false
                )
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

/// Large stat display for detail view
struct StatCardLarge: View {
    let stat: Stat
    
    init(stat: Stat) {
        self.stat = stat
    }
    
    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header
            HStack {
                Image(systemName: stat.icon)
                    .font(.system(size: 32))
                    .foregroundColor(stat.color)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(stat.displayName)
                        .font(AppFonts.title2)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text(stat.type.description)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Level display
            HStack(alignment: .bottom, spacing: AppSpacing.xs) {
                Text("\(stat.effectiveLevel)")
                    .font(AppFonts.levelNumberMedium)
                    .foregroundColor(stat.color)
                
                Spacer()
            }
            
            // XP Progress
            VStack(spacing: AppSpacing.xs) {
                XPProgressBar(
                    progress: stat.levelProgress,
                    color: stat.color,
                    height: 12
                )
                
                HStack {
                    Text("\(stat.xpProgressInCurrentLevel) XP")
                        .font(AppFonts.xpNumber)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(stat.xpNeededForNextLevel) XP to next level")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Activities
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Activities")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                
                FlowLayout(spacing: AppSpacing.xs) {
                    ForEach(stat.type.activities, id: \.self) { activity in
                        Text(activity)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, AppSpacing.xxs)
                            .background(AppColors.surfaceElevated)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .glowBorder(color: stat.color, lineWidth: 1, radius: 10)
    }
}

/// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview("Stat Cards") {
    let sampleStat = Stat(type: .strength, currentXP: 1250, level: 12, allocatedPoints: 3)
    
    ScrollView {
        VStack(spacing: 20) {
            StatCard(stat: sampleStat) {
                print("Tapped!")
            }
            
            StatCard(stat: Stat(type: .agility, currentXP: 500, level: 8, allocatedPoints: 0), showDetails: false)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(StatType.allCases) { type in
                    StatCardCompact(stat: Stat(type: type, currentXP: Int.random(in: 0...1000), level: Int.random(in: 1...30), allocatedPoints: Int.random(in: 0...5)))
                }
            }
            
            StatCardLarge(stat: sampleStat)
        }
        .padding()
    }
    .background(AppColors.background)
}
