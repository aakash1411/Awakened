import SwiftUI
import SwiftData

/// Main hub for Sense stat — meditation & mindfulness
struct SenseView: View {
    @StateObject private var service = MeditationService()
    @State private var dailyMinutes: [Double] = Array(repeating: 0, count: 7)
    @State private var showTimer = false
    @State private var showLogSession = false
    
    var body: some View {
        ZStack {
            AppColors.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Meditation Stats Card
                    MeditationStatsCard(
                        weeklyMinutes: service.weeklyMinutes,
                        weeklySessions: service.weeklySessions,
                        streak: service.currentStreak
                    )
                    
                    // Built-in Timer Card
                    timerCard
                    
                    // Weekly Chart
                    weeklyChart
                    
                    // Quick Actions
                    HStack(spacing: AppSpacing.md) {
                        Button {
                            showTimer = true
                        } label: {
                            HStack {
                                Image(systemName: "timer")
                                Text("Start Timer")
                            }
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.senseColor)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        
                        Button {
                            showLogSession = true
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Log Session")
                            }
                            .font(AppFonts.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppColors.senseColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.senseColor.opacity(0.15))
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                    }
                    
                    // Recent Sessions
                    recentSessionsSection
                    
                    Spacer(minLength: AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.md)
            }
        }
        .navigationTitle("Spirit")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MeditationHistoryView()
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppColors.senseColor)
                }
            }
        }
        .fullScreenCover(isPresented: $showTimer) {
            MeditationTimerView(meditationService: service)
        }
        .sheet(isPresented: $showLogSession) {
            LogMeditationView { _ in
                Task {
                    await service.fetchWeeklyStats()
                    dailyMinutes = await service.fetchDailyBreakdown()
                }
            }
        }
        .task {
            await service.calculateStreak()
            await service.fetchRecentSessions()
            await service.fetchWeeklyStats()
            dailyMinutes = await service.fetchDailyBreakdown()
        }
    }
    
    // MARK: - Timer Card
    
    private var timerCard: some View {
        Button {
            showTimer = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.senseColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.senseColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Meditation Timer")
                        .font(AppFonts.headline)
                        .foregroundColor(AppColors.textPrimary)
                    
                    Text("Start a guided or unguided session")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(AppColors.senseColor)
            }
            .padding(AppSpacing.cardPadding)
            .background(AppColors.surface)
            .cornerRadius(AppSpacing.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(AppColors.senseColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Weekly Chart
    
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("This Week")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.textPrimary)
            
            HStack(alignment: .bottom, spacing: AppSpacing.sm) {
                let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]
                let maxMinutes = max(dailyMinutes.max() ?? 1, 1)
                
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dailyMinutes[index] > 0 ? AppColors.senseColor : AppColors.surface)
                            .frame(height: max(4, CGFloat(dailyMinutes[index] / maxMinutes) * 80))
                        
                        Text(dayLabels[index])
                            .font(AppFonts.caption2)
                            .foregroundColor(AppColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 100)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Recent Sessions")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textPrimary)
                
                Spacer()
                
                NavigationLink {
                    MeditationHistoryView()
                } label: {
                    Text("See All")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.senseColor)
                }
            }
            
            if service.recentSessions.isEmpty && !service.isLoading {
                VStack(spacing: AppSpacing.md) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(AppColors.textTertiary)
                    
                    Text("No sessions yet")
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Text("Start a meditation or log a mindfulness session.")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.textTertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.xl)
            } else {
                ForEach(service.recentSessions.prefix(5)) { session in
                    sessionRow(session)
                }
            }
            
            if service.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surface)
        .cornerRadius(AppSpacing.cardCornerRadius)
    }
    
    private func sessionRow(_ session: MeditationSession) -> some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: session.typeIcon)
                .font(.system(size: 18))
                .foregroundColor(AppColors.senseColor)
                .frame(width: 36, height: 36)
                .background(AppColors.senseColor.opacity(0.15))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.displayName)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)
                
                HStack(spacing: 4) {
                    Image(systemName: session.source.icon)
                        .font(.system(size: 10))
                    Text(session.source.displayName)
                        .font(AppFonts.caption2)
                }
                .foregroundColor(AppColors.textTertiary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationFormatted)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textPrimary)
                
                Text("+\(session.xpEarned) XP")
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.senseColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Log Meditation View

/// Simple sheet for manually logging a meditation session
struct LogMeditationView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    @StateObject private var service = MeditationService()
    
    private var player: Player? { players.first }
    
    @State private var selectedType: MeditationType = .mindfulness
    @State private var durationMinutes: Int = 10
    @State private var notes: String = ""
    
    var onComplete: ((MeditationSession) -> Void)?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Type
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Type")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: AppSpacing.sm) {
                                ForEach(MeditationType.allCases) { type in
                                    Button {
                                        selectedType = type
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 20))
                                            Text(type.displayName)
                                                .font(AppFonts.caption2)
                                        }
                                        .foregroundColor(selectedType == type ? .white : AppColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, AppSpacing.sm)
                                        .background(selectedType == type ? AppColors.senseColor : AppColors.surface.opacity(0.5))
                                        .cornerRadius(AppSpacing.cardCornerRadius)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Duration
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            Text("Duration")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            HStack {
                                Text("\(durationMinutes) min")
                                    .font(AppFonts.title2)
                                    .foregroundColor(AppColors.senseColor)
                                    .frame(width: 80)
                                
                                Slider(
                                    value: Binding(
                                        get: { Double(durationMinutes) },
                                        set: { durationMinutes = Int($0) }
                                    ),
                                    in: 1...60,
                                    step: 1
                                )
                                .tint(AppColors.senseColor)
                            }
                            
                            HStack(spacing: AppSpacing.sm) {
                                ForEach(selectedType.suggestedDurations, id: \.self) { mins in
                                    Button {
                                        durationMinutes = mins
                                    } label: {
                                        Text("\(mins)m")
                                            .font(AppFonts.caption1)
                                            .foregroundColor(durationMinutes == mins ? .white : AppColors.textSecondary)
                                            .padding(.horizontal, AppSpacing.sm)
                                            .padding(.vertical, 4)
                                            .background(durationMinutes == mins ? AppColors.senseColor : AppColors.surface.opacity(0.5))
                                            .cornerRadius(AppSpacing.buttonCornerRadius)
                                    }
                                }
                            }
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Notes
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Notes (optional)")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            TextField("How was the session?", text: $notes, axis: .vertical)
                                .font(AppFonts.body)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(AppSpacing.md)
                                .background(AppColors.surface.opacity(0.5))
                                .cornerRadius(AppSpacing.cardCornerRadius)
                                .lineLimit(3...5)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.surface)
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // XP Preview
                        let xp = XPCalculator.senseXP(durationMinutes: Double(durationMinutes))
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(AppColors.senseColor)
                            Text("Estimated XP:")
                                .font(AppFonts.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                            Spacer()
                            Text("+\(xp) SEN XP")
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.senseColor)
                        }
                        .padding(AppSpacing.cardPadding)
                        .background(AppColors.senseColor.opacity(0.1))
                        .cornerRadius(AppSpacing.cardCornerRadius)
                        
                        // Save
                        Button {
                            let session = service.logManualSession(
                                type: selectedType,
                                duration: Double(durationMinutes * 60),
                                notes: notes.isEmpty ? nil : notes
                            )
                            // Apply XP to Sense stat
                            player?.addXP(session.xpEarned, to: .sense)
                            // Update meditation quest progress
                            if let player = player {
                                for quest in player.todayQuests where quest.isActive && quest.category == .meditation {
                                    quest.addProgress(Double(durationMinutes))
                                    if quest.progress >= 1.0 && !quest.isCompleted {
                                        player.completeQuest(quest)
                                    }
                                }
                            }
                            onComplete?(session)
                            dismiss()
                        } label: {
                            Text("Log Session")
                                .font(AppFonts.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.md)
                                .background(AppColors.senseColor)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                        
                        Spacer(minLength: AppSpacing.xxl)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.top, AppSpacing.md)
                }
            }
            .navigationTitle("Log Meditation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }
}
