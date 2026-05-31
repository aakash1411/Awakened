import SwiftUI
import SwiftData

/// Onboarding flow for new users
struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentPage = 0
    @State private var playerName = ""
    @State private var selectedGoal: FitnessGoal = .balance
    @State private var isCreatingPlayer = false
    
    @State private var healthPermissionGranted = false
    
    private let totalPages = 6
    
    var body: some View {
        ZStack {
            // Background
            AppColors.backgroundGradient
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            VStack {
                // Progress indicator
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index <= currentPage ? AppColors.primaryBlue : AppColors.surface)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.lg)
                
                // Page content
                TabView(selection: $currentPage) {
                    WelcomePage()
                        .tag(0)
                    
                    ThemeSelectionPage()
                        .tag(1)
                    
                    NameEntryPage(name: $playerName)
                        .tag(2)
                    
                    GoalSelectionPage(selectedGoal: $selectedGoal)
                        .tag(3)
                    
                    HealthPermissionPage(isGranted: $healthPermissionGranted)
                        .tag(4)
                    
                    ReadyPage()
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                .onChange(of: currentPage) { _, _ in
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                
                // Navigation buttons
                HStack(spacing: AppSpacing.md) {
                    // Back button
                    if currentPage > 0 {
                        Button(action: previousPage) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(AppFonts.headline)
                            .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Next/Start button
                    Button(action: nextPage) {
                        HStack {
                            Text(currentPage == totalPages - 1 ? "Begin Journey" : "Continue")
                            if currentPage < totalPages - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(AppFonts.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.xl)
                        .padding(.vertical, AppSpacing.md)
                        .background(canProceed ? AppColors.primaryBlue : AppColors.textDisabled)
                        .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .disabled(!canProceed || isCreatingPlayer)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, AppSpacing.xxl)
            }
        }
    }
    
    /// Check if user can proceed to next page
    private var canProceed: Bool {
        switch currentPage {
        case 2: return !playerName.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }
    
    /// Go to previous page
    private func previousPage() {
        withAnimation {
            currentPage = max(0, currentPage - 1)
        }
    }
    
    /// Go to next page or complete onboarding
    private func nextPage() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        if currentPage == totalPages - 1 {
            completeOnboarding()
        } else {
            withAnimation {
                currentPage = min(totalPages - 1, currentPage + 1)
            }
        }
    }
    
    /// Complete onboarding and create player
    private func completeOnboarding() {
        isCreatingPlayer = true
        
        // Create player
        let trimmedName = playerName.trimmingCharacters(in: .whitespaces)
        appState.createPlayer(name: trimmedName.isEmpty ? "Hunter" : trimmedName, in: modelContext)
        
        // Persist selected fitness goal
        FitnessGoal.currentGoal = selectedGoal
        
        // Complete onboarding
        appState.completeOnboarding()
        
        isCreatingPlayer = false
    }
}

// MARK: - Fitness Goal

enum FitnessGoal: String, CaseIterable, Identifiable, Codable {
    case strength
    case weightLoss
    case cardio
    case flexibility
    case balance
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .strength: return "Build Strength"
        case .weightLoss: return "Weight Loss"
        case .cardio: return "Improve Cardio"
        case .flexibility: return "Mind & Body"
        case .balance: return "Balanced Training"
        }
    }
    
    var description: String {
        switch self {
        case .strength: return "Focus on weight training and muscle building"
        case .weightLoss: return "Track weight and burn calories to shed fat"
        case .cardio: return "Focus on endurance and cardiovascular health"
        case .flexibility: return "Meditation, mobility, and body awareness"
        case .balance: return "Equal focus on all aspects of fitness"
        }
    }
    
    var icon: String {
        switch self {
        case .strength: return "figure.strengthtraining.traditional"
        case .weightLoss: return "scalemass.fill"
        case .cardio: return "figure.run"
        case .flexibility: return "figure.mind.and.body"
        case .balance: return "figure.mixed.cardio"
        }
    }
    
    /// UserDefaults key for persisting the goal
    static var currentGoal: FitnessGoal {
        get {
            guard let raw = UserDefaults.standard.string(forKey: "playerFitnessGoal"),
                  let goal = FitnessGoal(rawValue: raw) else { return .balance }
            return goal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "playerFitnessGoal")
        }
    }
}

// MARK: - Welcome Page

struct WelcomePage: View {
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Logo/Icon
            ZStack {
                Circle()
                    .fill(AppColors.primaryBlue.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Circle()
                    .stroke(AppColors.primaryBlue, lineWidth: 3)
                    .frame(width: 150, height: 150)
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primaryBlue)
            }
            .shadow(color: AppColors.glowBlue, radius: 20)
            .scaleEffect(showContent ? 1 : 0.5)
            .opacity(showContent ? 1 : 0)
            
            // Title
            VStack(spacing: AppSpacing.sm) {
                Text("AWAKENED")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Level Up Your Life")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)
            
            // Description
            Text("Transform your fitness journey into an epic adventure. Track workouts, complete quests, and watch your stats grow.")
                .font(AppFonts.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
                .opacity(showContent ? 1 : 0)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - Name Entry Page

struct NameEntryPage: View {
    @Binding var name: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Icon
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(AppColors.primaryBlue)
            
            // Title
            VStack(spacing: AppSpacing.sm) {
                Text("What's Your Name?")
                    .font(AppFonts.title1)
                    .foregroundColor(.white)
                
                Text("This is how we'll address you, Hunter")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Text field
            TextField("Enter your name", text: $name)
                .font(AppFonts.title2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                .background(AppColors.surface)
                .cornerRadius(AppSpacing.cardCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                        .stroke(isFocused ? AppColors.primaryBlue : AppColors.textTertiary, lineWidth: 1)
                )
                .focused($isFocused)
                .submitLabel(.continue)
                .onSubmit { isFocused = false }
                .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
        .onDisappear {
            isFocused = false
        }
    }
}

// MARK: - Goal Selection Page

struct GoalSelectionPage: View {
    @Binding var selectedGoal: FitnessGoal
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Title
            VStack(spacing: AppSpacing.sm) {
                Text("Choose Your Path")
                    .font(AppFonts.title1)
                    .foregroundColor(.white)
                
                Text("What's your primary fitness focus?")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Goal options
            VStack(spacing: AppSpacing.md) {
                ForEach(FitnessGoal.allCases) { goal in
                    GoalOptionCard(
                        goal: goal,
                        isSelected: selectedGoal == goal
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedGoal = goal
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            
            Spacer()
            Spacer()
        }
    }
}

struct GoalOptionCard: View {
    let goal: FitnessGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: goal.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? AppColors.primaryBlue : AppColors.textSecondary)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(goal.title)
                        .font(AppFonts.headline)
                        .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                    
                    Text(goal.description)
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primaryBlue)
                }
            }
            .padding(AppSpacing.md)
            .background(isSelected ? AppColors.surfaceElevated : AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(isSelected ? AppColors.primaryBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Ready Page

struct ReadyPage: View {
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Animated rank badge
            ZStack {
                // Outer glow rings
                ForEach(0..<3) { i in
                    Circle()
                        .stroke(AppColors.primaryBlue.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: CGFloat(120 + i * 30), height: CGFloat(120 + i * 30))
                        .scaleEffect(showContent ? 1 : 0.5)
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeOut(duration: 0.8).delay(Double(i) * 0.1), value: showContent)
                }
                
                RankBadge(rank: .e, size: .large)
                    .scaleEffect(showContent ? 1 : 0)
                    .opacity(showContent ? 1 : 0)
            }
            
            // Title
            VStack(spacing: AppSpacing.sm) {
                Text("You Are Ready")
                    .font(AppFonts.title1)
                    .foregroundColor(.white)
                
                Text("Your journey as an E-Rank Hunter begins now")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)
            
            // Stats preview
            VStack(spacing: AppSpacing.sm) {
                Text("Starting Stats")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                
                HStack(spacing: AppSpacing.lg) {
                    ForEach(StatType.allCases) { stat in
                        VStack(spacing: AppSpacing.xxs) {
                            Text(stat.shortName)
                                .font(AppFonts.statLabel)
                                .foregroundColor(stat.color)
                            
                            Text("1")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(AppSpacing.md)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

// MARK: - Health Permission Page

struct HealthPermissionPage: View {
    @Binding var isGranted: Bool
    @State private var isRequesting = false
    @State private var showSkipInfo = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let healthDataTypes = [
        ("figure.walk", "Steps & Distance"),
        ("flame.fill", "Workouts"),
        ("bed.double.fill", "Sleep Analysis"),
        ("brain.head.profile", "Mindful Minutes"),
        ("heart.fill", "Heart Rate"),
        ("scalemass.fill", "Body Measurements")
    ]
    
    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.strengthColor.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 50))
                    .foregroundColor(AppColors.strengthColor)
            }
            
            // Title
            VStack(spacing: AppSpacing.sm) {
                Text("Connect Apple Health")
                    .font(AppFonts.title1)
                    .foregroundColor(.white)
                
                Text("Automatically track your progress")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Data types list
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(healthDataTypes, id: \.1) { icon, label in
                    HStack(spacing: AppSpacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppColors.primaryBlue)
                            .font(.system(size: 16))
                        
                        Image(systemName: icon)
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 24)
                        
                        Text(label)
                            .font(AppFonts.body)
                            .foregroundColor(AppColors.textPrimary)
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .padding(.horizontal, AppSpacing.xl)
            
            // Connect button
            VStack(spacing: AppSpacing.sm) {
                Button {
                    requestHealthPermission()
                } label: {
                    HStack {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "heart.fill")
                            Text(isGranted ? "Connected" : "Connect Health")
                        }
                    }
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(isGranted ? AppColors.success : AppColors.strengthColor)
                    .cornerRadius(AppSpacing.buttonCornerRadius)
                }
                .disabled(isRequesting || isGranted)
                .padding(.horizontal, AppSpacing.xl)
                
                if !isGranted {
                    Button {
                        showSkipInfo = true
                    } label: {
                        Text("Skip for now")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            Spacer()
        }
        .alert("Skip Health Connection?", isPresented: $showSkipInfo) {
            Button("Skip", role: .destructive) { }
            Button("Connect", role: .cancel) {
                requestHealthPermission()
            }
        } message: {
            Text("You can always connect Apple Health later from Settings. Without it, you'll need to log activities manually.")
        }
        .alert("Health Connection Failed", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func requestHealthPermission() {
        isRequesting = true
        Task {
            do {
                let granted = try await HealthKitManager.shared.requestAuthorization()
                isGranted = granted
            } catch {
                print("Health auth error: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
            isRequesting = false
        }
    }
}

#Preview("Onboarding") {
    OnboardingView()
        .environmentObject(AppState())
        .modelContainer(for: [Player.self, Stat.self, Quest.self, SyncRecord.self, Exercise.self, WorkoutSession.self, WorkoutSet.self, WorkoutTemplate.self, PersonalRecord.self, ReadingEntry.self, LearningSession.self, Achievement.self, FoodItem.self, MealEntry.self, BodyMeasurement.self], inMemory: true)
}
