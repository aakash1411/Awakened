import SwiftUI

/// Lets the user pick from preset themes or build a fully custom one.
/// Live previews each theme using a small mock card.
struct ThemePickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showingCustom = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header explainer
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Choose your look")
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.textPrimary)
                    Text("Themes change app colors instantly. You can also build your own.")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                
                // Preset grid
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: AppSpacing.md),
                              GridItem(.flexible(), spacing: AppSpacing.md)],
                    spacing: AppSpacing.md
                ) {
                    ForEach(AppTheme.presets) { theme in
                        ThemeCard(
                            theme: theme,
                            isSelected: themeManager.current.id == theme.id
                        ) {
                            themeManager.setPreset(theme)
                        }
                    }
                    
                    // Custom card
                    Button {
                        showingCustom = true
                    } label: {
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 32))
                                .foregroundColor(AppColors.primaryBlue)
                            Text("Custom")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Text(themeManager.current.id == "custom" ? "Active" : "Build your own")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 170)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                                .stroke(themeManager.current.id == "custom" ? AppColors.primaryBlue : AppColors.border,
                                        lineWidth: themeManager.current.id == "custom" ? 2 : 1)
                        )
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                
                Spacer(minLength: AppSpacing.xxl)
            }
            .padding(.top, AppSpacing.md)
        }
        .background(AppColors.backgroundGradient.ignoresSafeArea())
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCustom) {
            CustomThemeEditorView()
                .environmentObject(themeManager)
        }
    }
}

// MARK: - Theme Card

struct ThemeCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: AppSpacing.sm) {
                // Mock preview
                ZStack {
                    LinearGradient(
                        colors: [theme.backgroundGradientTop, theme.backgroundGradientBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    VStack(spacing: 6) {
                        // Surface mini-card
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.surface)
                            .frame(height: 24)
                            .overlay(
                                HStack(spacing: 4) {
                                    Circle().fill(theme.primary).frame(width: 8, height: 8)
                                    Capsule().fill(theme.textSecondary.opacity(0.5)).frame(width: 28, height: 4)
                                    Spacer()
                                }
                                .padding(.horizontal, 6)
                            )
                        
                        // Color swatches
                        HStack(spacing: 4) {
                            Circle().fill(theme.primary).frame(width: 12, height: 12)
                            Circle().fill(theme.accent).frame(width: 12, height: 12)
                            Circle().fill(theme.success).frame(width: 12, height: 12)
                            Circle().fill(theme.warning).frame(width: 12, height: 12)
                            Circle().fill(theme.error).frame(width: 12, height: 12)
                        }
                    }
                    .padding(8)
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Name + selection state
                VStack(spacing: 2) {
                    Text(theme.displayName)
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.textPrimary)
                    Text(isSelected ? "Active" : (theme.isDark ? "Dark" : "Light"))
                        .font(AppFonts.caption2)
                        .foregroundColor(isSelected ? AppColors.success : AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.sm)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(isSelected ? AppColors.primaryBlue : AppColors.border,
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom Theme Editor

struct CustomThemeEditorView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var draft: AppTheme
    
    init() {
        let base = ThemeManager.shared.current
        var copy = base
        copy.id = "custom"
        copy.displayName = base.id == "custom" ? base.displayName : "My Theme"
        _draft = State(initialValue: copy)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Live preview
                    ThemeCard(theme: draft, isSelected: false, onTap: {})
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                    
                    // Name + dark toggle
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Theme Name")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textSecondary)
                        TextField("My Theme", text: $draft.displayName)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        Toggle("Dark mode", isOn: $draft.isDark)
                            .padding(AppSpacing.md)
                            .background(AppColors.surface)
                            .cornerRadius(AppSpacing.cardCornerRadius)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    
                    // Color groups
                    colorGroup(title: "Backgrounds", items: [
                        ("Background", $draft.backgroundHex),
                        ("Gradient Top", $draft.backgroundGradientTopHex),
                        ("Gradient Bottom", $draft.backgroundGradientBottomHex),
                        ("Surface", $draft.surfaceHex),
                        ("Surface Elevated", $draft.surfaceElevatedHex),
                        ("Border", $draft.borderHex)
                    ])
                    
                    colorGroup(title: "Primary Palette", items: [
                        ("Primary", $draft.primaryHex),
                        ("Primary Dark", $draft.primaryDarkHex),
                        ("Primary Light", $draft.primaryLightHex),
                        ("Accent", $draft.accentHex)
                    ])
                    
                    colorGroup(title: "Text", items: [
                        ("Primary Text", $draft.textPrimaryHex),
                        ("Secondary Text", $draft.textSecondaryHex),
                        ("Tertiary Text", $draft.textTertiaryHex),
                        ("Disabled Text", $draft.textDisabledHex)
                    ])
                    
                    colorGroup(title: "Semantic", items: [
                        ("Success", $draft.successHex),
                        ("Warning", $draft.warningHex),
                        ("Error", $draft.errorHex)
                    ])
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.top, AppSpacing.md)
            }
            .background(AppColors.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Custom Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        themeManager.setCustom(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func colorGroup(title: String, items: [(String, Binding<String>)]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.screenHorizontal)
            
            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    ColorPickerRow(label: items[i].0, hex: items[i].1)
                    if i < items.count - 1 {
                        Divider().background(AppColors.border)
                    }
                }
            }
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .padding(.horizontal, AppSpacing.screenHorizontal)
        }
    }
}

// MARK: - Color Picker Row

struct ColorPickerRow: View {
    let label: String
    @Binding var hex: String
    
    private var color: Binding<Color> {
        Binding(
            get: { Color(hex: hex) },
            set: { newValue in hex = newValue.hexString }
        )
    }
    
    var body: some View {
        HStack {
            ColorPicker(selection: color, supportsOpacity: false) {
                Text(label)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Text("#\(hex)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
    }
}
