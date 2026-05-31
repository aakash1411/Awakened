import SwiftUI
import SwiftData

/// Workouts tab — hub for starting workouts, browsing templates, viewing history, and exploring exercises
struct WorkoutsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        filter: #Predicate<WorkoutSession> { $0.isCompleted },
        sort: \WorkoutSession.date,
        order: .reverse
    ) private var allCompletedSessions: [WorkoutSession]
    
    private var recentSessions: [WorkoutSession] {
        Array(allCompletedSessions.prefix(5))
    }
    
    @Query(filter: #Predicate<WorkoutSession> { !$0.isCompleted })
    private var inProgressSessions: [WorkoutSession]
    
    @State private var showingActiveWorkout = false
    @State private var showingTemplatePicker = false
    @State private var showingExerciseBrowser = false
    @State private var activeSession: WorkoutSession?
    @State private var activeTemplateExercises: [TemplateExercise]?
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Resume in-progress workout
                    if let inProgress = inProgressSessions.first {
                        resumeCard(inProgress)
                    }
                    
                    // Muscle map (anatomy with color-coded levels)
                    MuscleMapView()
                    
                    // Quick actions
                    quickActions
                    
                    // Recent workouts
                    if !recentSessions.isEmpty {
                        recentWorkoutsSection
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.sm)
            }
        }
        .navigationTitle("Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ExerciseBrowserView()
                } label: {
                    Image(systemName: "books.vertical")
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
        }
        .navigationDestination(isPresented: $showingActiveWorkout) {
            if let session = activeSession {
                ActiveWorkoutView(
                    session: session,
                    templateExercises: activeTemplateExercises
                )
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            NavigationStack {
                TemplatePicker { template in
                    startWorkoutFromTemplate(template)
                }
            }
        }
    }
    
    // MARK: - Resume Card
    
    private func resumeCard(_ session: WorkoutSession) -> some View {
        Button {
            activeTemplateExercises = nil
            activeSession = session
            showingActiveWorkout = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                        Text("Workout In Progress")
                            .font(AppFonts.caption1)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Text(session.name)
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Started \(session.startTime, style: .relative) ago")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                Text("Resume")
                    .font(AppFonts.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AppColors.primaryBlue)
                    .cornerRadius(10)
            }
            .padding(AppSpacing.cardPadding)
            .background(Color.green.opacity(0.08))
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        VStack(spacing: AppSpacing.md) {
            // Quick Start + Templates
            HStack(spacing: AppSpacing.md) {
                // Quick Start
                Button {
                    startEmptyWorkout()
                } label: {
                    VStack(spacing: AppSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryBlue.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.primaryBlue)
                        }
                        
                        Text("Quick Start")
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Start empty workout")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                }
                .buttonStyle(.plain)
                
                // Templates
                Button {
                    showingTemplatePicker = true
                } label: {
                    VStack(spacing: AppSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(AppColors.accentPurple.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 22))
                                .foregroundColor(AppColors.accentPurple)
                        }
                        
                        Text("Templates")
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.textPrimary)
                        
                        Text("Use a routine")
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.lg)
                    .background(AppColors.surface)
                    .cornerRadius(AppSpacing.cardCornerRadius)
                }
                .buttonStyle(.plain)
            }
            
            // Cardio row
            NavigationLink {
                CardioView()
            } label: {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.vitalityColor)
                        .frame(width: 32)
                    
                    Text("Cardio Activities")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
            }
            
            // Flexibility & Yoga row
            NavigationLink {
                AgilityView()
            } label: {
                HStack {
                    Image(systemName: "figure.yoga")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.agilityColor)
                        .frame(width: 32)
                    
                    Text("Flexibility & Yoga")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
            }
            
            // Meditation row
            NavigationLink {
                SenseView()
            } label: {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.senseColor)
                        .frame(width: 32)
                    
                    Text("Meditation")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
            }
            
            // Body Tracking row
            NavigationLink {
                BodyTrackingView()
            } label: {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.agilityColor)
                        .frame(width: 32)
                    
                    Text("Body Tracking")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
            }
            
            // History row
            NavigationLink {
                WorkoutHistoryView()
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.primaryBlue)
                        .frame(width: 32)
                    
                    Text("Workout History")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textTertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
            }
        }
    }
    
    // MARK: - Recent Workouts
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("RECENT WORKOUTS")
                    .font(AppFonts.caption1)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                NavigationLink("See All") {
                    WorkoutHistoryView()
                }
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.primaryBlue)
            }
            
            ForEach(recentSessions) { session in
                RecentWorkoutRow(session: session)
            }
        }
    }
    
    // MARK: - Actions
    
    private func startEmptyWorkout() {
        let session = WorkoutSession(name: "Workout")
        
        // Associate with player
        var playerDescriptor = FetchDescriptor<Player>()
        playerDescriptor.fetchLimit = 1
        if let player = try? modelContext.fetch(playerDescriptor).first {
            session.player = player
        }
        
        modelContext.insert(session)
        try? modelContext.save()
        
        activeTemplateExercises = nil
        activeSession = session
        showingActiveWorkout = true
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        let session = WorkoutSession(name: template.name)
        
        // Associate with player
        var playerDescriptor = FetchDescriptor<Player>()
        playerDescriptor.fetchLimit = 1
        if let player = try? modelContext.fetch(playerDescriptor).first {
            session.player = player
        }
        
        modelContext.insert(session)
        try? modelContext.save()
        
        // Mark template as used
        template.markUsed()
        try? modelContext.save()
        
        activeTemplateExercises = template.exercises
        activeSession = session
        showingActiveWorkout = true
    }
}

// MARK: - Recent Workout Row

private struct RecentWorkoutRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: AppSpacing.sm) {
                    Text(session.durationFormatted)
                    Text("•")
                    Text("\(session.exerciseCount) exercises")
                }
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text("+\(session.xpEarned)")
                        .font(AppFonts.caption1)
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppColors.strengthColor)
                
                if session.prCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 9))
                        Text("\(session.prCount) PRs")
                            .font(AppFonts.caption2)
                    }
                    .foregroundColor(.yellow)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
}

#Preview("Workouts") {
    WorkoutsView()
        .environmentObject(AppState())
        .modelContainer(for: [
            Player.self, Stat.self, Quest.self, SyncRecord.self,
            Exercise.self, WorkoutSession.self, WorkoutSet.self,
            WorkoutTemplate.self, PersonalRecord.self,
            ReadingEntry.self, LearningSession.self, Achievement.self,
            FoodItem.self, MealEntry.self, BodyMeasurement.self
        ], inMemory: true)
}
