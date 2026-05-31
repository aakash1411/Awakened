import Foundation
import HealthKit
import AVFoundation
import UIKit
import Combine

/// Manages a meditation timer with bell sounds, haptics, and HealthKit integration
@MainActor
class MeditationTimerManager: ObservableObject {
    
    // MARK: - Published State
    
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var elapsedSeconds: Int = 0
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var isComplete: Bool = false
    @Published var sessionType: MeditationType = .mindfulness
    
    // MARK: - Private
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var startDate: Date?
    private let healthStore = HealthKitManager.shared.healthStore
    
    /// Interval in seconds between bell sounds (0 = no interval bells)
    var bellIntervalSeconds: Int = 0
    
    // MARK: - Computed
    
    /// Progress from 0.0 to 1.0
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(elapsedSeconds) / Double(totalSeconds)
    }
    
    /// Formatted remaining time (e.g., "14:30")
    var remainingFormatted: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formatted elapsed time (e.g., "5:30")
    var elapsedFormatted: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Timer Control
    
    /// Start a new meditation timer
    /// - Parameters:
    ///   - duration: Duration in seconds
    ///   - type: Type of meditation
    ///   - bellInterval: Seconds between interval bells (0 = none)
    func start(duration: Int, type: MeditationType, bellInterval: Int = 0) {
        stop()
        
        totalSeconds = duration
        remainingSeconds = duration
        elapsedSeconds = 0
        sessionType = type
        bellIntervalSeconds = bellInterval
        isRunning = true
        isPaused = false
        isComplete = false
        startDate = Date()
        
        configureAudioSession()
        playBell()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    /// Pause the timer
    func pause() {
        guard isRunning, !isPaused else { return }
        isPaused = true
        timer?.invalidate()
        timer = nil
    }
    
    /// Resume the timer
    func resume() {
        guard isPaused else { return }
        isPaused = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }
    
    /// Stop and reset the timer
    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        remainingSeconds = 0
        elapsedSeconds = 0
        totalSeconds = 0
        startDate = nil
    }
    
    // MARK: - Tick
    
    private func tick() {
        guard isRunning, !isPaused else { return }
        
        elapsedSeconds += 1
        remainingSeconds = max(0, totalSeconds - elapsedSeconds)
        
        // Interval bell
        if bellIntervalSeconds > 0, elapsedSeconds > 0, elapsedSeconds % bellIntervalSeconds == 0, remainingSeconds > 0 {
            playBell()
            triggerHaptic(.light)
        }
        
        // Timer complete
        if remainingSeconds <= 0 {
            completeSession()
        }
    }
    
    // MARK: - Completion
    
    private func completeSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isComplete = true
        
        playBell()
        playBell() // Double bell for completion
        triggerHaptic(.success)
        
        // Write to HealthKit
        if let start = startDate {
            writeMindfulSession(start: start, end: Date())
        }
    }
    
    // MARK: - HealthKit Write
    
    /// Write a completed mindful session to HealthKit
    private func writeMindfulSession(start: Date, end: Date) {
        guard let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession) else { return }
        
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        
        healthStore.save(sample) { success, error in
            if let error = error {
                print("MeditationTimerManager: Failed to save to HealthKit — \(error)")
            }
        }
    }
    
    // MARK: - Audio
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("MeditationTimerManager: Audio session error — \(error)")
        }
    }
    
    /// Play a meditation bell sound
    private func playBell() {
        // Try bundled bell sound first, fall back to system sounds
        if let url = Bundle.main.url(forResource: "meditation_bell", withExtension: "mp3") ??
            Bundle.main.url(forResource: "meditation_bell", withExtension: "wav") ??
            Bundle.main.url(forResource: "meditation_bell", withExtension: "caf") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = 0.8
                audioPlayer?.play()
                return
            } catch {
                print("MeditationTimerManager: Failed to play bundled bell — \(error)")
            }
        }
        
        // Fallback: system sounds that work even on silent mode via .playback category
        AudioServicesPlayAlertSound(SystemSoundID(1016)) // Tweet sound — more audible than Tink
    }
    
    // MARK: - Haptics
    
    private func triggerHaptic(_ type: HapticFeedbackType) {
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    /// Haptic feedback types used by the timer
    private enum HapticFeedbackType {
        case light
        case medium
        case success
    }
}
