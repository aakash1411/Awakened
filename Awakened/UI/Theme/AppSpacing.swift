import SwiftUI

/// Centralized spacing and layout constants for the Awakened app
/// Based on an 8pt grid system for consistent spacing
struct AppSpacing {
    
    // MARK: - Base Unit
    
    /// Base spacing unit (8pt grid)
    static let unit: CGFloat = 8
    
    // MARK: - Spacing Scale
    
    /// Extra extra small - 4pt (0.5x)
    static let xxs: CGFloat = 4
    
    /// Extra small - 8pt (1x)
    static let xs: CGFloat = 8
    
    /// Small - 12pt (1.5x)
    static let sm: CGFloat = 12
    
    /// Medium - 16pt (2x)
    static let md: CGFloat = 16
    
    /// Large - 24pt (3x)
    static let lg: CGFloat = 24
    
    /// Extra large - 32pt (4x)
    static let xl: CGFloat = 32
    
    /// Extra extra large - 48pt (6x)
    static let xxl: CGFloat = 48
    
    /// Extra extra extra large - 64pt (8x)
    static let xxxl: CGFloat = 64
    
    // MARK: - Component Specific
    
    /// Standard card padding
    static let cardPadding: CGFloat = 16
    
    /// Standard card corner radius
    static let cardCornerRadius: CGFloat = 16
    
    /// Small card corner radius
    static let cardCornerRadiusSmall: CGFloat = 12
    
    /// Large card corner radius
    static let cardCornerRadiusLarge: CGFloat = 20
    
    /// Button corner radius
    static let buttonCornerRadius: CGFloat = 12
    
    /// Standard icon size
    static let iconSize: CGFloat = 24
    
    /// Large icon size
    static let iconSizeLarge: CGFloat = 32
    
    /// Small icon size
    static let iconSizeSmall: CGFloat = 20
    
    /// Tab bar height (standard iOS)
    static let tabBarHeight: CGFloat = 83
    
    /// Navigation bar height
    static let navBarHeight: CGFloat = 44
    
    // MARK: - Screen Margins
    
    /// Horizontal screen margin
    static let screenHorizontal: CGFloat = 20
    
    /// Vertical screen margin
    static let screenVertical: CGFloat = 16
    
    // MARK: - Progress Bar
    
    /// Standard progress bar height
    static let progressBarHeight: CGFloat = 8
    
    /// Large progress bar height
    static let progressBarHeightLarge: CGFloat = 12
    
    /// Small progress bar height
    static let progressBarHeightSmall: CGFloat = 4
}

// MARK: - Layout Helpers

struct AppLayout {
    /// Maximum content width (iPhone 14 Pro Max)
    static let maxContentWidth: CGFloat = 428
    
    /// Minimum touch target size (Apple HIG)
    static let minTouchTarget: CGFloat = 44
    
    /// Creates adaptive grid columns based on available width
    /// - Parameters:
    ///   - width: Available width
    ///   - minWidth: Minimum column width
    /// - Returns: Array of GridItems
    static func adaptiveColumns(for width: CGFloat, minWidth: CGFloat = 160) -> [GridItem] {
        let count = max(1, Int(width / minWidth))
        return Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: count)
    }
    
    /// Creates fixed grid columns
    /// - Parameters:
    ///   - count: Number of columns
    ///   - spacing: Spacing between columns
    /// - Returns: Array of GridItems
    static func fixedColumns(count: Int, spacing: CGFloat = AppSpacing.md) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: spacing), count: count)
    }
}

// MARK: - Spacing View Modifiers

extension View {
    /// Apply standard card styling (padding + corner radius)
    func cardStyle() -> some View {
        self
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    /// Apply elevated card styling
    func elevatedCardStyle() -> some View {
        self
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surfaceElevated)
            .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    /// Apply screen horizontal padding
    func screenPadding() -> some View {
        self.padding(.horizontal, AppSpacing.screenHorizontal)
    }
}
