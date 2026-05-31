import SwiftUI
import SwiftData

/// Create or edit a workout template
struct TemplateEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    /// Existing template to edit (nil for new template)
    var template: WorkoutTemplate?
    
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var exercises: [TemplateExercise] = []
    @State private var showingExercisePicker = false
    @State private var editingExercise: TemplateExercise?
    
    private var isEditing: Bool { template != nil }
    private var isValid: Bool { !name.isEmpty && !exercises.isEmpty }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    // Name & Description
                    nameSection
                    
                    // Exercises
                    exercisesSection
                    
                    // Add exercise button
                    addExerciseButton
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.xl)
            }
        }
        .navigationTitle(isEditing ? "Edit Template" : "New Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
            }
        }
        .onAppear { loadTemplate() }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExerciseBrowserView(isPickerMode: true) { exercise in
                    addExercise(exercise)
                }
            }
        }
    }
    
    // MARK: - Name Section
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("TEMPLATE INFO")
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            VStack(spacing: AppSpacing.sm) {
                TextField("Template Name", text: $name)
                    .textFieldStyle(.plain)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                
                TextField("Description (optional)", text: $description)
                    .textFieldStyle(.plain)
                    .font(AppFonts.body)
                    .foregroundColor(AppColors.textPrimary)
                    .padding(AppSpacing.md)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
            }
        }
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("EXERCISES")
                    .font(AppFonts.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text("\(exercises.count) exercises")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            if exercises.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: AppSpacing.sm) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppColors.textTertiary)
                        Text("No exercises added")
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .padding(.vertical, AppSpacing.xl)
                    Spacer()
                }
            } else {
                ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                    TemplateExerciseRow(
                        exercise: exercise,
                        index: index + 1,
                        onUpdate: { updated in
                            exercises[index] = updated
                        },
                        onDelete: {
                            exercises.remove(at: index)
                        }
                    )
                }
                .onMove { from, to in
                    exercises.move(fromOffsets: from, toOffset: to)
                }
            }
        }
    }
    
    // MARK: - Add Exercise Button
    
    private var addExerciseButton: some View {
        Button {
            showingExercisePicker = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Exercise")
                    .fontWeight(.medium)
            }
            .font(AppFonts.body)
            .foregroundColor(AppColors.primaryBlue)
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .background(AppColors.primaryBlue.opacity(0.1))
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(AppColors.primaryBlue.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
    }
    
    // MARK: - Actions
    
    private func loadTemplate() {
        guard let template = template else { return }
        name = template.name
        description = template.templateDescription
        exercises = template.exercises
    }
    
    private func addExercise(_ exercise: Exercise) {
        let templateExercise = TemplateExercise(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            targetSets: exercise.mechanic == .compound ? 4 : 3,
            targetReps: exercise.mechanic == .compound ? "6-8" : "10-12",
            restSeconds: exercise.defaultRestSeconds
        )
        exercises.append(templateExercise)
    }
    
    private func save() {
        if let template = template {
            template.name = name
            template.templateDescription = description
            template.exercises = exercises
        } else {
            let newTemplate = WorkoutTemplate(
                name: name,
                templateDescription: description,
                exercises: exercises
            )
            modelContext.insert(newTemplate)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Template Exercise Row

private struct TemplateExerciseRow: View {
    let exercise: TemplateExercise
    let index: Int
    let onUpdate: (TemplateExercise) -> Void
    let onDelete: () -> Void
    
    @State private var sets: String = ""
    @State private var reps: String = ""
    @State private var rest: String = ""
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack {
                Text("\(index)")
                    .font(AppFonts.caption1)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.primaryBlue)
                    .frame(width: 24, height: 24)
                    .background(AppColors.primaryBlue.opacity(0.15))
                    .cornerRadius(12)
                
                Text(exercise.exerciseName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            HStack(spacing: AppSpacing.md) {
                VStack(spacing: 2) {
                    Text("Sets")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    TextField("\(exercise.targetSets)", text: $sets)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 50)
                        .padding(.vertical, 4)
                        .background(AppColors.background)
                        .cornerRadius(6)
                        .onChange(of: sets) { _, newValue in
                            var updated = exercise
                            updated.targetSets = Int(newValue) ?? exercise.targetSets
                            onUpdate(updated)
                        }
                }
                
                VStack(spacing: 2) {
                    Text("Reps")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    TextField(exercise.targetReps, text: $reps)
                        .multilineTextAlignment(.center)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 60)
                        .padding(.vertical, 4)
                        .background(AppColors.background)
                        .cornerRadius(6)
                        .onChange(of: reps) { _, newValue in
                            var updated = exercise
                            updated.targetReps = newValue.isEmpty ? exercise.targetReps : newValue
                            onUpdate(updated)
                        }
                }
                
                VStack(spacing: 2) {
                    Text("Rest")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(AppColors.textTertiary)
                    TextField("\(exercise.restSeconds)s", text: $rest)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(AppFonts.body)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(width: 60)
                        .padding(.vertical, 4)
                        .background(AppColors.background)
                        .cornerRadius(6)
                        .onChange(of: rest) { _, newValue in
                            var updated = exercise
                            updated.restSeconds = Int(newValue) ?? exercise.restSeconds
                            onUpdate(updated)
                        }
                }
                
                Spacer()
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .onAppear {
            sets = "\(exercise.targetSets)"
            reps = exercise.targetReps
            rest = "\(exercise.restSeconds)"
        }
    }
}

#Preview("Template Editor") {
    NavigationStack {
        TemplateEditorView()
    }
    .modelContainer(for: [WorkoutTemplate.self, Exercise.self])
}
