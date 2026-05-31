import Foundation
import Combine
import UIKit
import AudioToolbox

/// Manages rest timer state with haptic and optional sound feedback
@MainActor
class RestTimerManager: ObservableObject {
    
    // MARK: - Published State
    
    /// Whether the timer is currently running
    @Published var isRunning: Bool = false
    
    /// Seconds remaining
    @Published var remainingSeconds: Int = 0
    
    /// Total duration for this timer cycle
    @Published var totalSeconds: Int = 90
    
    /// Progress from 1.0 (full) to 0.0 (done)
    @Published var progress: Double = 1.0
    
    /// Whether the timer just completed (for animation)
    @Published var didComplete: Bool = false
    
    // MARK: - Settings
    
    /// Default rest for compound exercises (seconds)
    var compoundRestSeconds: Int = 90
    
    /// Default rest for isolation exercises (seconds)
    var isolationRestSeconds: Int = 60
    
    /// Whether sound is enabled
    var isSoundEnabled: Bool = true
    
    // MARK: - Private
    
    private var timer: AnyCancellable?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private var hasPlayedWarning: Bool = false
    
    // MARK: - Timer Controls
    
    /// Start the rest timer
    /// - Parameter seconds: Duration in seconds
    func start(seconds: Int) {
        stop()
        
        totalSeconds = seconds
        remainingSeconds = seconds
        progress = 1.0
        isRunning = true
        didComplete = false
        hasPlayedWarning = false
        
        hapticGenerator.prepare()
        notificationGenerator.prepare()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    /// Start with default duration based on exercise type
    /// - Parameter isCompound: Whether the exercise is a compound movement
    func startDefault(isCompound: Bool) {
        start(seconds: isCompound ? compoundRestSeconds : isolationRestSeconds)
    }
    
    /// Pause the timer
    func pause() {
        timer?.cancel()
        timer = nil
        isRunning = false
    }
    
    /// Resume a paused timer
    func resume() {
        guard remainingSeconds > 0 else { return }
        isRunning = true
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    /// Skip the rest timer
    func skip() {
        stop()
        didComplete = true
    }
    
    /// Add time to the current timer
    /// - Parameter seconds: Seconds to add (default: 30)
    func addTime(_ seconds: Int = 30) {
        remainingSeconds += seconds
        totalSeconds += seconds
        updateProgress()
    }
    
    /// Stop and reset the timer
    func stop() {
        timer?.cancel()
        timer = nil
        isRunning = false
        remainingSeconds = 0
        progress = 1.0
    }
    
    // MARK: - Display
    
    /// Formatted time remaining (e.g., "1:23")
    var timeFormatted: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /// Formatted total time
    var totalTimeFormatted: String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Private Methods
    
    private func tick() {
        guard remainingSeconds > 0 else {
            complete()
            return
        }
        
        remainingSeconds -= 1
        updateProgress()
        
        // Warning haptic at 10 seconds
        if remainingSeconds == 10 && !hasPlayedWarning {
            hasPlayedWarning = true
            hapticGenerator.impactOccurred(intensity: 0.5)
        }
        
        // Tick haptics at 3, 2, 1
        if remainingSeconds <= 3 && remainingSeconds > 0 {
            hapticGenerator.impactOccurred(intensity: 0.7)
        }
        
        if remainingSeconds == 0 {
            complete()
        }
    }
    
    private func complete() {
        stop()
        didComplete = true
        
        // Completion haptic
        notificationGenerator.notificationOccurred(.success)
        
        // Play sound if enabled
        if isSoundEnabled {
            playCompletionSound()
        }
    }
    
    private func updateProgress() {
        guard totalSeconds > 0 else {
            progress = 0
            return
        }
        progress = Double(remainingSeconds) / Double(totalSeconds)
    }
    
    private func playCompletionSound() {
        // Use system sound for rest timer completion
        AudioServicesPlaySystemSound(1007) // Standard notification sound
    }
    
    deinit {
        timer?.cancel()
    }
}

