import SwiftUI
import SwiftData

/// Browse and search the exercise database
struct ExerciseBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    
    @State private var searchText = ""
    @State private var selectedMuscleGroup: MuscleGroup?
    @State private var selectedEquipment: EquipmentType?
    @State private var selectedExercise: Exercise?
    
    /// If true, the view is in picker mode (selecting exercises for a workout)
    var isPickerMode: Bool = false
    
    /// Callback when an exercise is selected in picker mode
    var onSelect: ((Exercise) -> Void)?
    
    private var filteredExercises: [Exercise] {
        allExercises.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText)
            let matchesMuscle = selectedMuscleGroup == nil ||
                exercise.muscleGroup == selectedMuscleGroup
            let matchesEquipment = selectedEquipment == nil ||
                exercise.equipment == selectedEquipment
            return matchesSearch && matchesMuscle && matchesEquipment
        }
    }
    
    private var groupedExercises: [(MuscleGroup, [Exercise])] {
        let grouped = Dictionary(grouping: filteredExercises) { $0.muscleGroup }
        return grouped.sorted { $0.key.displayName < $1.key.displayName }
    }
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Filter chips
                filterChips
                
                // Exercise list
                if filteredExercises.isEmpty {
                    emptyState
                } else {
                    exerciseList
                }
            }
        }
        .navigationTitle(isPickerMode ? "Add Exercise" : "Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search exercises...")
        .sheet(item: $selectedExercise) { exercise in
            ExerciseDetailSheet(exercise: exercise)
        }
    }
    
    // MARK: - Filter Chips
    
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // Muscle group filter
                Menu {
                    Button("All Muscles") { selectedMuscleGroup = nil }
                    Divider()
                    ForEach(MuscleGroup.allCases) { group in
                        Button(group.displayName) { selectedMuscleGroup = group }
                    }
                } label: {
                    ExerciseFilterChip(
                        title: selectedMuscleGroup?.displayName ?? "Muscle",
                        isActive: selectedMuscleGroup != nil,
                        icon: "figure.strengthtraining.traditional"
                    )
                }
                
                // Equipment filter
                Menu {
                    Button("All Equipment") { selectedEquipment = nil }
                    Divider()
                    ForEach(EquipmentType.allCases) { equip in
                        Button(equip.displayName) { selectedEquipment = equip }
                    }
                } label: {
                    ExerciseFilterChip(
                        title: selectedEquipment?.displayName ?? "Equipment",
                        isActive: selectedEquipment != nil,
                        icon: "dumbbell.fill"
                    )
                }
                
                // Clear all
                if selectedMuscleGroup != nil || selectedEquipment != nil {
                    Button {
                        selectedMuscleGroup = nil
                        selectedEquipment = nil
                    } label: {
                        Text("Clear")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.primaryBlue)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.sm)
        }
    }
    
    // MARK: - Exercise List
    
    private var exerciseList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                ForEach(groupedExercises, id: \.0) { group, exercises in
                    Section {
                        ForEach(exercises) { exercise in
                            ExerciseRow(exercise: exercise, isPickerMode: isPickerMode) {
                                if isPickerMode {
                                    onSelect?(exercise)
                                    dismiss()
                                } else {
                                    selectedExercise = exercise
                                }
                            }
                        }
                    } header: {
                        sectionHeader(group)
                    }
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
    }
    
    private func sectionHeader(_ group: MuscleGroup) -> some View {
        HStack {
            Image(systemName: group.icon)
                .font(.system(size: 14))
                .foregroundColor(group.color)
            
            Text(group.displayName.uppercased())
                .font(AppFonts.caption1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.textSecondary)
            
            Spacer()
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.background.opacity(0.95))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppColors.textTertiary)
            Text("No exercises found")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textSecondary)
            Text("Try adjusting your search or filters")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textTertiary)
            Spacer()
        }
    }
}

// MARK: - Exercise Row

private struct ExerciseRow: View {
    let exercise: Exercise
    let isPickerMode: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                // Muscle icon
                Circle()
                    .fill(exercise.muscleGroup.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: exercise.muscleGroup.icon)
                            .font(.system(size: 16))
                            .foregroundColor(exercise.muscleGroup.color)
                    }
                
                // Exercise info
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: AppSpacing.xs) {
                        Text(exercise.equipment.displayName)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text("•")
                            .foregroundColor(AppColors.textTertiary)
                        
                        Text(exercise.mechanic.displayName)
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                
                Spacer()
                
                if isPickerMode {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColors.primaryBlue)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.sm + 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip

private struct ExerciseFilterChip: View {
    let title: String
    let isActive: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(title)
                .font(AppFonts.caption1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? AppColors.primaryBlue.opacity(0.2) : AppColors.surface)
        .foregroundColor(isActive ? AppColors.primaryBlue : AppColors.textSecondary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? AppColors.primaryBlue.opacity(0.5) : AppColors.border, lineWidth: 1)
        )
    }
}

// MARK: - Exercise Detail Sheet

private struct ExerciseDetailSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack {
                                Circle()
                                    .fill(exercise.muscleGroup.color.opacity(0.15))
                                    .frame(width: 50, height: 50)
                                    .overlay {
                                        Image(systemName: exercise.muscleGroup.icon)
                                            .font(.system(size: 22))
                                            .foregroundColor(exercise.muscleGroup.color)
                                    }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(exercise.name)
                                        .font(AppFonts.title3)
                                        .foregroundColor(AppColors.textPrimary)
                                    
                                    Text(exercise.muscleGroup.displayName)
                                        .font(AppFonts.subheadline)
                                        .foregroundColor(exercise.muscleGroup.color)
                                }
                            }
                        }
                        
                        // Info pills
                        HStack(spacing: AppSpacing.sm) {
                            InfoPill(label: "Equipment", value: exercise.equipment.displayName)
                            InfoPill(label: "Type", value: exercise.mechanic.displayName)
                            InfoPill(label: "Level", value: exercise.level.displayName)
                        }
                        
                        // Secondary muscles
                        if !exercise.secondaryMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text("Secondary Muscles")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                FlowLayout(spacing: AppSpacing.xs) {
                                    ForEach(exercise.secondaryMuscles) { muscle in
                                        Text(muscle.displayName)
                                            .font(AppFonts.caption1)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(muscle.color.opacity(0.15))
                                            .foregroundColor(muscle.color)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        // Instructions
                        if !exercise.instructions.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Instructions")
                                    .font(AppFonts.headline)
                                    .foregroundColor(AppColors.textPrimary)
                                
                                let steps = exercise.instructions.components(separatedBy: "\n\n")
                                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                                        Text("\(index + 1)")
                                            .font(AppFonts.caption1)
                                            .fontWeight(.bold)
                                            .foregroundColor(AppColors.primaryBlue)
                                            .frame(width: 24, height: 24)
                                            .background(AppColors.primaryBlue.opacity(0.15))
                                            .cornerRadius(12)
                                        
                                        Text(step)
                                            .font(AppFonts.body)
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.screenHorizontal)
                    .padding(.bottom, AppSpacing.xl)
                }
            }
            .navigationTitle("Exercise Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Info Pill

private struct InfoPill: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
            Text(value)
                .font(AppFonts.caption1)
                .fontWeight(.medium)
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}


#Preview("Exercise Browser") {
    NavigationStack {
        ExerciseBrowserView()
    }
    .modelContainer(for: [Exercise.self])
}
