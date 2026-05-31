import SwiftUI
import SwiftData

/// Grid view for selecting workout templates
struct TemplatePicker: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    
    @State private var showingEditor = false
    @State private var editingTemplate: WorkoutTemplate?
    
    /// Callback when a template is selected to start a workout
    var onSelect: ((WorkoutTemplate) -> Void)?
    
    private var builtInTemplates: [WorkoutTemplate] {
        templates.filter { $0.isBuiltIn }
    }
    
    private var customTemplates: [WorkoutTemplate] {
        templates.filter { !$0.isBuiltIn }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Custom templates
                    if !customTemplates.isEmpty {
                        templateSection("My Templates", templates: customTemplates, allowDelete: true)
                    }
                    
                    // Built-in templates
                    if !builtInTemplates.isEmpty {
                        templateSection("Built-In Templates", templates: builtInTemplates, allowDelete: false)
                    }
                    
                    if templates.isEmpty {
                        emptyState
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                TemplateEditorView()
            }
        }
        .sheet(item: $editingTemplate) { template in
            NavigationStack {
                TemplateEditorView(template: template)
            }
        }
    }
    
    // MARK: - Template Section
    
    private func templateSection(_ title: String, templates: [WorkoutTemplate], allowDelete: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title.uppercased())
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppSpacing.md),
                GridItem(.flexible(), spacing: AppSpacing.md)
            ], spacing: AppSpacing.md) {
                ForEach(templates) { template in
                    TemplateCard(template: template) {
                        template.markUsed()
                        try? modelContext.save()
                        onSelect?(template)
                        dismiss()
                    }
                    .contextMenu {
                        if !template.isBuiltIn {
                            Button {
                                editingTemplate = template
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                modelContext.delete(template)
                                try? modelContext.save()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        
                        Button {
                            // Duplicate template
                            let copy = WorkoutTemplate(
                                name: "\(template.name) Copy",
                                templateDescription: template.templateDescription,
                                exercises: template.exercises,
                                isBuiltIn: false,
                                player: template.player
                            )
                            modelContext.insert(copy)
                            try? modelContext.save()
                        } label: {
                            Label("Duplicate", systemImage: "doc.on.doc")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer(minLength: 60)
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            Text("No templates yet")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("Create a custom workout template or check back after exercises are loaded")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
                .multilineTextAlignment(.center)
            Spacer(minLength: 60)
        }
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: WorkoutTemplate
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // Icon
                HStack {
                    Image(systemName: template.isBuiltIn ? "star.fill" : "doc.fill")
                        .font(.system(size: 14))
                        .foregroundColor(template.isBuiltIn ? .yellow : AppColors.primaryBlue)
                    
                    Spacer()
                    
                    if template.timesUsed > 0 {
                        Text("×\(template.timesUsed)")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                // Name
                Text(template.name)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                // Description
                if !template.templateDescription.isEmpty {
                    Text(template.templateDescription)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
                
                // Footer
                HStack {
                    Text("\(template.exerciseCount) exercises")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text("\(template.totalTargetSets) sets")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(AppSpacing.cardPadding)
            .frame(minHeight: 120)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(AppColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Template Picker") {
    NavigationStack {
        TemplatePicker()
    }
    .modelContainer(for: [WorkoutTemplate.self, Exercise.self])
}
