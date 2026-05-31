import SwiftUI
import SwiftData

/// Full-screen meditation timer with circular progress
struct MeditationTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    @StateObject private var timerManager = MeditationTimerManager()
    @ObservedObject var meditationService: MeditationService
    
    private var player: Player? { players.first }
    
    @State private var selectedDuration: Int = 600 // 10 min default
    @State private var selectedType: MeditationType = .mindfulness
    @State private var bellInterval: Int = 0 // 0 = no interval bells
    @State private var hasStarted = false
    
    private let presetDurations = [
        (300, "5 min"),
        (600, "10 min"),
        (900, "15 min"),
        (1200, "20 min"),
        (1800, "30 min"),
        (2700, "45 min"),
        (3600, "60 min")
    ]
    
    private let bellIntervals = [
        (0, "None"),
        (60, "1 min"),
        (120, "2 min"),
        (300, "5 min")
    ]
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            if !hasStarted {
                setupView
            } else {
                activeTimerView
            }
        }
        .onChange(of: timerManager.isComplete) { _, isComplete in
            if isComplete {
                handleCompletion()
            }
        }
    }
    
    // MARK: - Setup View
    
    private var setupView: some View {
        VStack(spacing: AppSpacing.xl) {
            // Close button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(AppColors.surface)
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            
            Spacer()
            
            // Type selection
            VStack(spacing: AppSpacing.md) {
                Text("Meditation Type")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textSecondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(MeditationType.allCases) { type in
                            Button {
                                selectedType = type
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: type.icon)
                                        .font(.system(size: 22))
                                    Text(type.displayName)
                                        .font(AppFonts.caption2)
                                }
                                .foregroundColor(selectedType == type ? AppColors.senseColor : AppColors.textTertiary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.sm)
                                .background(selectedType == type ? AppColors.senseColor.opacity(0.2) : Color.clear)
                                .cornerRadius(AppSpacing.cardCornerRadius)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                }
            }
            
            // Duration selection
            VStack(spacing: AppSpacing.md) {
                Text("Duration")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.textSecondary)
                
                Text("\(selectedDuration / 60) min")
                    .font(.system(size: 60, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.md) {
                        ForEach(presetDurations, id: \.0) { duration, label in
                            Button {
                                selectedDuration = duration
                            } label: {
                                Text(label)
                                    .font(AppFonts.subheadline)
                                    .fontWeight(selectedDuration == duration ? .semibold : .regular)
                                    .foregroundColor(selectedDuration == duration ? .white : AppColors.textTertiary)
                                    .padding(.horizontal, AppSpacing.md)
                                    .padding(.vertical, AppSpacing.sm)
                                    .background(selectedDuration == duration ? AppColors.senseColor.opacity(0.3) : Color.clear)
                                    .cornerRadius(AppSpacing.buttonCornerRadius)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                }
            }
            
            // Bell interval
            VStack(spacing: AppSpacing.sm) {
                Text("Interval Bell")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.textTertiary)
                
                HStack(spacing: AppSpacing.md) {
                    ForEach(bellIntervals, id: \.0) { interval, label in
                        Button {
                            bellInterval = interval
                        } label: {
                            Text(label)
                                .font(AppFonts.caption1)
                                .foregroundColor(bellInterval == interval ? .white : AppColors.textTertiary)
                                .padding(.horizontal, AppSpacing.sm)
                                .padding(.vertical, 4)
                                .background(bellInterval == interval ? AppColors.senseColor.opacity(0.3) : Color.clear)
                                .cornerRadius(AppSpacing.buttonCornerRadius)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Start button
            Button {
                withAnimation {
                    hasStarted = true
                    timerManager.start(
                        duration: selectedDuration,
                        type: selectedType,
                        bellInterval: bellInterval
                    )
                }
            } label: {
                Text("Begin")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(width: 120, height: 120)
                    .background(AppColors.senseColor)
                    .clipShape(Circle())
            }
            .padding(.bottom, AppSpacing.xxl)
        }
    }
    
    // MARK: - Active Timer View
    
    private var activeTimerView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Session type
            VStack(spacing: AppSpacing.xs) {
                Image(systemName: selectedType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.senseColor.opacity(0.6))
                
                Text(selectedType.displayName)
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.textTertiary)
            }
            
            // Circular progress
            ZStack {
                // Background ring
                Circle()
                    .stroke(AppColors.surface, lineWidth: 6)
                    .frame(width: 260, height: 260)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: timerManager.progress)
                    .stroke(
                        AppColors.senseColor,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 260, height: 260)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerManager.progress)
                
                // Time display
                VStack(spacing: 4) {
                    if timerManager.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.success)
                    } else {
                        Text(timerManager.remainingFormatted)
                            .font(.system(size: 52, weight: .thin, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                        
                        Text("remaining")
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Controls
            if timerManager.isComplete {
                VStack(spacing: AppSpacing.md) {
                    let xp = XPCalculator.senseXP(
                        durationMinutes: Double(timerManager.totalSeconds) / 60.0,
                        consecutiveDays: meditationService.currentStreak
                    )
                    
                    Text("+\(xp) SEN XP")
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.senseColor)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(AppFonts.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppSpacing.md)
                            .background(AppColors.senseColor)
                            .cornerRadius(AppSpacing.buttonCornerRadius)
                    }
                    .padding(.horizontal, AppSpacing.xl)
                }
            } else {
                HStack(spacing: AppSpacing.xl) {
                    // Stop
                    Button {
                        timerManager.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 56, height: 56)
                            .background(AppColors.surface)
                            .clipShape(Circle())
                    }
                    
                    // Pause / Resume
                    Button {
                        if timerManager.isPaused {
                            timerManager.resume()
                        } else {
                            timerManager.pause()
                        }
                    } label: {
                        Image(systemName: timerManager.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 72, height: 72)
                            .background(AppColors.senseColor)
                            .clipShape(Circle())
                    }
                }
            }
            
            Spacer()
                .frame(height: AppSpacing.xxl)
        }
    }
    
    // MARK: - Completion
    
    private func handleCompletion() {
        let session = meditationService.logTimerSession(
            type: selectedType,
            duration: Double(timerManager.totalSeconds)
        )
        // Apply XP to Sense stat
        player?.addXP(session.xpEarned, to: .sense)
        // Update meditation quest progress
        let minutes = Double(timerManager.totalSeconds) / 60.0
        if let player = player {
            for quest in player.todayQuests where quest.isActive && quest.category == .meditation {
                quest.addProgress(minutes)
                if quest.progress >= 1.0 && !quest.isCompleted {
                    player.completeQuest(quest)
                }
            }
        }
    }
}
