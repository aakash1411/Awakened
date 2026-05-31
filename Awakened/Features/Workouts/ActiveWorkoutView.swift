import SwiftUI
import SwiftData

/// Hevy/Strong-inspired active workout logging view
struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    @StateObject private var restTimer = RestTimerManager()
    
    /// The active workout session
    @State var session: WorkoutSession
    
    /// Template exercises to pre-load (nil for empty workouts)
    var templateExercises: [TemplateExercise]?
    
    /// Current exercise groups (exercise name → sets)
    @State private var exerciseGroups: [ExerciseGroup] = []
    
    /// Elapsed time
    @State private var elapsedSeconds: Int = 0
    @State private var sessionTimer: Timer?
    
    /// Sheet states
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirm = false
    @State private var showingSummary = false
    @State private var showingDiscardConfirm = false
    
    /// New PR alerts
    @State private var newPRExercise: String?
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Session header
                sessionHeader
                
                // Exercises
                ScrollView {
                    LazyVStack(spacing: AppSpacing.lg) {
                        ForEach(Array(exerciseGroups.enumerated()), id: \.element.id) { index, group in
                            ExerciseCard(
                                group: $exerciseGroups[index],
                                restTimer: restTimer,
                                onPR: { exerciseName in
                                    withAnimation(.spring(response: 0.4)) {
                                        newPRExercise = exerciseName
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { newPRExercise = nil }
                                    }
                                }
                            )
                        }
                        
                        // Add exercise button
                        addExerciseButton
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                        
                        // Bottom spacing for rest timer
                        Spacer(minLength: restTimer.isRunning ? 80 : 20)
                    }
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, 100)
                }
                
                Spacer(minLength: 0)
            }
            
            // Bottom bar: rest timer or action buttons
            bottomBar
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showingDiscardConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .onAppear {
            startSessionTimer()
            if exerciseGroups.isEmpty, let templateExercises {
                populateFromTemplate(templateExercises)
            }
        }
        .onDisappear { sessionTimer?.invalidate() }
        .sheet(isPresented: $showingExercisePicker) {
            NavigationStack {
                ExerciseBrowserView(isPickerMode: true) { exercise in
                    addExercise(exercise)
                }
            }
        }
        .sheet(isPresented: $showingSummary, onDismiss: {
            // After summary is dismissed, go back to WorkoutsView
            dismiss()
        }) {
            NavigationStack {
                WorkoutSummaryView(session: session)
            }
        }
        .alert("Discard Workout?", isPresented: $showingDiscardConfirm) {
            Button("Discard", role: .destructive) {
                modelContext.delete(session)
                try? modelContext.save()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all logged sets from this workout.")
        }
        .alert("Finish Workout?", isPresented: $showingFinishConfirm) {
            Button("Finish") { finishWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Complete this workout and earn XP.")
        }
    }
    
    // MARK: - Session Header
    
    private var sessionHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text(session.name)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                // Elapsed timer
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                    Text(formatElapsed(elapsedSeconds))
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                }
                .foregroundColor(AppColors.primaryBlue)
            }
            
            // PR notification
            if let prExercise = newPRExercise {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 12))
                    Text("New PR on \(prExercise)!")
                        .font(AppFonts.caption1)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.background.opacity(0.95))
    }
    
    // MARK: - Bottom Bar
    
    private var bottomBar: some View {
        VStack(spacing: 0) {
            if restTimer.isRunning {
                RestTimerView(timerManager: restTimer)
            } else {
                // Action buttons
                HStack(spacing: AppSpacing.md) {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                            Text("Add Exercise")
                        }
                        .font(AppFonts.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.primaryBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryBlue.opacity(0.15))
                        .cornerRadius(12)
                    }
                    
                    Button {
                        let hasCompletedSets = exerciseGroups.contains { group in
                            group.sets.contains { $0.isCompleted }
                        }
                        if !hasCompletedSets {
                            showingDiscardConfirm = true
                        } else {
                            showingFinishConfirm = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                            Text("Finish")
                        }
                        .font(AppFonts.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColors.primaryBlue)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.sm)
                .background(AppColors.background.opacity(0.95))
            }
        }
    }
    
    // MARK: - Add Exercise Button (inline)
    
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
            .background(AppColors.primaryBlue.opacity(0.08))
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(AppColors.primaryBlue.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
    }
    
    // MARK: - Actions
    
    private func addExercise(_ exercise: Exercise) {
        let previousBest = fetchPreviousBest(exerciseName: exercise.name)
        let group = ExerciseGroup(
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            isCompound: exercise.mechanic == .compound,
            defaultRestSeconds: exercise.defaultRestSeconds,
            sets: [
                SetEntry(setNumber: 1)
            ],
            previousBestWeight: previousBest
        )
        exerciseGroups.append(group)
    }
    
    private func finishWorkout() {
        sessionTimer?.invalidate()
        
        // Convert exercise groups to WorkoutSets
        for group in exerciseGroups {
            for setEntry in group.sets where setEntry.isCompleted {
                let workoutSet = WorkoutSet(
                    exerciseName: group.exerciseName,
                    exerciseId: group.exerciseId,
                    setNumber: setEntry.setNumber,
                    reps: setEntry.reps,
                    weight: setEntry.weight,
                    isWarmup: setEntry.isWarmup,
                    isDropSet: setEntry.isDropSet,
                    isFailure: setEntry.isFailure,
                    restSeconds: setEntry.restSeconds
                )
                session.addSet(workoutSet)
            }
        }
        
        // Finish session
        session.finish()
        
        // Calculate XP
        let xp = WorkoutXPService.calculateSessionXP(session: session, context: modelContext)
        session.xpEarned = xp
        
        // Check for PRs
        if let player = session.player {
            let prs = WorkoutXPService.checkForPRs(session: session, context: modelContext, player: player)
            session.prCount = prs.count
            
            // Credit XP to player
            player.addXP(xp, to: .strength)
            
            // Update workout quest progress (minutes)
            let workoutMinutes = Double(session.durationSeconds) / 60.0
            for quest in player.todayQuests where quest.isActive && quest.category == .workout {
                quest.addProgress(workoutMinutes)
                if quest.progress >= 1.0 && !quest.isCompleted {
                    player.completeQuest(quest)
                }
            }
            
            // Update strength quest progress (composite Strength Points from bodyweight reps)
            for quest in player.todayQuests where quest.isActive && quest.category == .strength {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: Date())
                let todaySets = player.workoutSessions
                    .filter { $0.date >= startOfDay }
                    .flatMap { $0.sets }
                // Steps not available here; recomputed accurately on next HK sync.
                let sp = StrengthPointsCalculator.points(fromSets: todaySets, steps: 0)
                quest.updateProgress(sp)
                if quest.progress >= 1.0 && !quest.isCompleted {
                    player.completeQuest(quest)
                }
            }
        }
        
        try? modelContext.save()
        showingSummary = true
    }
    
    private func populateFromTemplate(_ exercises: [TemplateExercise]) {
        for te in exercises {
            let previousBest = fetchPreviousBest(exerciseName: te.exerciseName)
            let sets = (0..<te.targetSets).map { i in
                SetEntry(
                    setNumber: i + 1,
                    weight: te.targetWeight ?? 0,
                    restSeconds: te.restSeconds
                )
            }
            let group = ExerciseGroup(
                exerciseId: te.exerciseId,
                exerciseName: te.exerciseName,
                isCompound: te.restSeconds >= 90,
                defaultRestSeconds: te.restSeconds,
                sets: sets,
                previousBestWeight: previousBest
            )
            exerciseGroups.append(group)
        }
    }
    
    private func fetchPreviousBest(exerciseName: String) -> Double? {
        let descriptor = FetchDescriptor<PersonalRecord>(
            predicate: #Predicate<PersonalRecord> { record in
                record.exerciseName == exerciseName && record.recordTypeRaw == "maxWeight"
            }
        )
        return (try? modelContext.fetch(descriptor))?.first?.value
    }
    
    private func startSessionTimer() {
        elapsedSeconds = Int(Date().timeIntervalSince(session.startTime))
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds = Int(Date().timeIntervalSince(session.startTime))
        }
    }
    
    private func formatElapsed(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Exercise Group Model

struct ExerciseGroup: Identifiable {
    let id = UUID()
    let exerciseId: UUID
    let exerciseName: String
    let isCompound: Bool
    let defaultRestSeconds: Int
    var sets: [SetEntry]
    var previousBestWeight: Double?
}

struct SetEntry: Identifiable {
    let id = UUID()
    var setNumber: Int
    var weight: Double = 0
    var reps: Int = 0
    var isWarmup: Bool = false
    var isDropSet: Bool = false
    var isFailure: Bool = false
    var isCompleted: Bool = false
    var restSeconds: Int = 0
}

// MARK: - Exercise Card

private struct ExerciseCard: View {
    @Binding var group: ExerciseGroup
    @ObservedObject var restTimer: RestTimerManager
    var onPR: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            // Exercise header
            HStack {
                Text(group.exerciseName)
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primaryBlue)
                    .lineLimit(1)
                
                Spacer()
                
                if let best = group.previousBestWeight, best > 0 {
                    Text("Best: \(String(format: "%.0f", best)) kg")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            
            // Column headers
            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: 40, alignment: .leading)
                Text("KG")
                    .frame(width: 70, alignment: .center)
                Text("REPS")
                    .frame(width: 70, alignment: .center)
                Spacer()
                Text("")
                    .frame(width: 40)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(AppColors.textTertiary)
            
            // Sets
            ForEach(Array(group.sets.enumerated()), id: \.element.id) { index, setEntry in
                SetRow(
                    setEntry: $group.sets[index],
                    onComplete: {
                        completeSet(at: index)
                    }
                )
            }
            
            // Add set button
            Button {
                let newSet = SetEntry(setNumber: group.sets.count + 1)
                group.sets.append(newSet)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                    Text("Add Set")
                        .font(AppFonts.caption1)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppColors.primaryBlue)
                .padding(.vertical, 6)
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
        .padding(.horizontal, AppSpacing.screenHorizontal)
    }
    
    private func completeSet(at index: Int) {
        group.sets[index].isCompleted = true
        
        // Check for PR
        if let best = group.previousBestWeight,
           group.sets[index].weight > best {
            onPR(group.exerciseName)
        }
        
        // Start rest timer
        restTimer.start(seconds: group.defaultRestSeconds)
    }
}

// MARK: - Set Row (Hevy-style inline entry)

private struct SetRow: View {
    @Binding var setEntry: SetEntry
    var onComplete: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            // Set number + type badge
            HStack(spacing: 2) {
                Text("\(setEntry.setNumber)")
                    .font(AppFonts.body)
                    .fontWeight(.medium)
                    .foregroundColor(setEntry.isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                
                if let badge = typeBadge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(badgeColor)
                }
            }
            .frame(width: 40, alignment: .leading)
            
            // Weight input
            TextField("—", text: $weightText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(setEntry.isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                .frame(width: 70)
                .padding(.vertical, 6)
                .background(setEntry.isCompleted ? Color.clear : AppColors.background)
                .cornerRadius(6)
                .onChange(of: weightText) { _, newValue in
                    setEntry.weight = Double(newValue) ?? 0
                }
            
            // Reps input
            TextField("—", text: $repsText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(setEntry.isCompleted ? AppColors.textTertiary : AppColors.textPrimary)
                .frame(width: 70)
                .padding(.vertical, 6)
                .background(setEntry.isCompleted ? Color.clear : AppColors.background)
                .cornerRadius(6)
                .onChange(of: repsText) { _, newValue in
                    setEntry.reps = Int(newValue) ?? 0
                }
            
            Spacer()
            
            // Type toggles
            HStack(spacing: 4) {
                TypeToggle(label: "W", isActive: $setEntry.isWarmup)
                TypeToggle(label: "F", isActive: $setEntry.isFailure)
            }
            
            // Complete checkmark
            Button {
                if !setEntry.isCompleted && setEntry.reps > 0 {
                    onComplete()
                }
            } label: {
                Image(systemName: setEntry.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(setEntry.isCompleted ? .green : AppColors.textTertiary)
            }
            .frame(width: 40)
            .disabled(setEntry.isCompleted)
        }
        .padding(.vertical, 2)
        .opacity(setEntry.isCompleted ? 0.6 : 1)
        .onAppear {
            if setEntry.weight > 0 { weightText = formatWeight(setEntry.weight) }
            if setEntry.reps > 0 { repsText = "\(setEntry.reps)" }
        }
    }
    
    private var typeBadge: String? {
        if setEntry.isWarmup { return "W" }
        if setEntry.isDropSet { return "D" }
        if setEntry.isFailure { return "F" }
        return nil
    }
    
    private var badgeColor: Color {
        if setEntry.isWarmup { return .orange }
        if setEntry.isFailure { return .red }
        if setEntry.isDropSet { return .purple }
        return .clear
    }
    
    private func formatWeight(_ weight: Double) -> String {
        weight == floor(weight) ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
    }
}

// MARK: - Type Toggle

private struct TypeToggle: View {
    let label: String
    @Binding var isActive: Bool
    
    var body: some View {
        Button {
            isActive.toggle()
        } label: {
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isActive ? .white : AppColors.textTertiary)
                .frame(width: 22, height: 22)
                .background(isActive ? badgeBackground : AppColors.surface)
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isActive ? Color.clear : AppColors.border, lineWidth: 0.5)
                )
        }
    }
    
    private var badgeBackground: Color {
        switch label {
        case "W": return .orange
        case "F": return .red
        case "D": return .purple
        default: return AppColors.textTertiary
        }
    }
}

#Preview("Active Workout") {
    NavigationStack {
        ActiveWorkoutView(session: WorkoutSession(name: "Push Day"))
    }
    .environmentObject(AppState())
    .modelContainer(for: [WorkoutSession.self, WorkoutSet.self, Exercise.self, PersonalRecord.self, Player.self, Stat.self, Quest.self])
}
