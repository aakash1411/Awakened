import SwiftUI

/// Pentagon radar chart for displaying all 5 stats
struct RadarChartView: View {
    let stats: [Stat]
    let maxValue: Double
    let showLabels: Bool
    let showValues: Bool
    let animated: Bool
    /// Called when a stat vertex label is tapped
    var onStatTap: ((StatType) -> Void)?
    
    @State private var animationProgress: Double = 0
    
    init(
        stats: [Stat],
        maxValue: Double = 100,
        showLabels: Bool = true,
        showValues: Bool = true,
        animated: Bool = true,
        onStatTap: ((StatType) -> Void)? = nil
    ) {
        self.stats = stats.sorted()
        self.maxValue = maxValue
        self.showLabels = showLabels
        self.showValues = showValues
        self.animated = animated
        self.onStatTap = onStatTap
    }
    
    /// Normalized values (0-1) for each stat
    private var normalizedValues: [Double] {
        StatType.orderedCases.map { type in
            guard let stat = stats.first(where: { $0.type == type }) else { return 0 }
            let value = min(Double(stat.effectiveLevel) / maxValue, 1.0)
            return animated ? value * animationProgress : value
        }
    }
    
    /// Colors for each stat
    private var statColors: [Color] {
        StatType.orderedCases.map { $0.color }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - (showLabels ? 50 : 20)
            
            ZStack {
                // Background grid (5 levels)
                ForEach(1...5, id: \.self) { level in
                    RadarGridShape(sides: 5, scale: CGFloat(level) / 5.0)
                        .stroke(AppColors.textTertiary.opacity(0.2), lineWidth: 1)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                }
                
                // Axis lines from center to vertices
                ForEach(0..<5, id: \.self) { index in
                    let angle = angleForIndex(index, total: 5)
                    let endPoint = pointOnCircle(center: center, radius: radius, angle: angle)
                    
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: endPoint)
                    }
                    .stroke(AppColors.textTertiary.opacity(0.2), lineWidth: 1)
                }
                
                // Filled stat area
                RadarDataShape(values: normalizedValues)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.primaryBlue.opacity(0.4),
                                AppColors.accentPurple.opacity(0.3)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                
                // Stat area outline with glow
                RadarDataShape(values: normalizedValues)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .shadow(color: AppColors.glowBlue, radius: 8)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)
                
                // Stat points (dots at each vertex)
                ForEach(0..<5, id: \.self) { index in
                    let value = normalizedValues[index]
                    let angle = angleForIndex(index, total: 5)
                    let point = pointOnCircle(center: center, radius: radius * CGFloat(value), angle: angle)
                    
                    Circle()
                        .fill(statColors[index])
                        .frame(width: 10, height: 10)
                        .shadow(color: statColors[index].opacity(0.8), radius: 6)
                        .position(point)
                }
                
                // Labels
                if showLabels {
                    ForEach(0..<5, id: \.self) { index in
                        let angle = angleForIndex(index, total: 5)
                        let labelRadius = radius + 35
                        let labelPoint = pointOnCircle(center: center, radius: labelRadius, angle: angle)
                        let statType = StatType.orderedCases[index]
                        let stat = stats.first { $0.type == statType }
                        
                        VStack(spacing: 2) {
                            Text(statType.shortName)
                                .font(AppFonts.statLabel)
                                .foregroundColor(statColors[index])
                            
                            if showValues {
                                Text("\(stat?.effectiveLevel ?? 0)")
                                    .font(AppFonts.caption1)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onStatTap?(statType)
                        }
                        .position(labelPoint)
                    }
                }
            }
        }
        .onAppear {
            if animated {
                withAnimation(.easeOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 1.0
            }
        }
    }
    
    /// Calculate angle for a vertex index
    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let startAngle = -Double.pi / 2  // Start from top
        return startAngle + (2 * Double.pi / Double(total)) * Double(index)
    }
    
    /// Calculate point on circle at given angle
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        CGPoint(
            x: center.x + radius * CGFloat(cos(angle)),
            y: center.y + radius * CGFloat(sin(angle))
        )
    }
}

// MARK: - Radar Grid Shape

/// Pentagon grid shape for background
struct RadarGridShape: Shape {
    let sides: Int
    let scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale
        
        for i in 0..<sides {
            let angle = angleForIndex(i)
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        
        return path
    }
    
    private func angleForIndex(_ index: Int) -> Double {
        let startAngle = -Double.pi / 2
        return startAngle + (2 * Double.pi / Double(sides)) * Double(index)
    }
}

// MARK: - Radar Data Shape

/// Shape for the filled stat area
struct RadarDataShape: Shape {
    var values: [Double]
    
    var animatableData: [Double] {
        get { values }
        set { values = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        guard values.count >= 5 else { return path }
        
        for i in 0..<5 {
            let angle = angleForIndex(i)
            let radius = maxRadius * CGFloat(values[i])
            let point = CGPoint(
                x: center.x + radius * CGFloat(cos(angle)),
                y: center.y + radius * CGFloat(sin(angle))
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        
        return path
    }
    
    private func angleForIndex(_ index: Int) -> Double {
        let startAngle = -Double.pi / 2
        return startAngle + (2 * Double.pi / 5.0) * Double(index)
    }
}

// MARK: - Preview

#Preview("Radar Chart") {
    let sampleStats: [Stat] = {
        var stats: [Stat] = []
        for (index, type) in StatType.allCases.enumerated() {
            let stat = Stat(type: type, currentXP: 0, level: [15, 22, 18, 10, 25][index], allocatedPoints: [3, 5, 2, 1, 4][index])
            stats.append(stat)
        }
        return stats
    }()
    
    VStack {
        RadarChartView(stats: sampleStats)
            .frame(height: 300)
            .padding()
        
        RadarChartView(stats: sampleStats, showLabels: false, showValues: false)
            .frame(height: 200)
            .padding()
    }
    .background(AppColors.background)
}
