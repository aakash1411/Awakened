import Foundation
import AVFoundation
import UIKit

/// Sound effect types
enum SoundEffect: String, CaseIterable {
    case levelUp = "level_up"
    case questComplete = "quest_complete"
    case achievementUnlocked = "achievement_unlocked"
    case penaltyEnter = "penalty_enter"
    case xpGain = "xp_gain"
    case timerBell = "timer_bell"
    
    /// System sound ID fallback when custom audio file is not available
    var systemSoundId: SystemSoundID {
        switch self {
        case .levelUp: return 1025           // Fanfare
        case .questComplete: return 1057     // Tink
        case .achievementUnlocked: return 1054 // Tweet
        case .penaltyEnter: return 1073      // Low beep
        case .xpGain: return 1104            // Pop
        case .timerBell: return 1013         // Bell
        }
    }
}

/// Haptic feedback types
enum HapticType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}

/// Singleton managing sound effects and haptic feedback
class SoundManager {
    
    // MARK: - Singleton
    
    static let shared = SoundManager()
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var volume: Float = 1.0
    
    /// Whether sounds are muted
    var isMuted: Bool {
        get { UserDefaults.standard.bool(forKey: "soundMuted") }
        set { UserDefaults.standard.set(newValue, forKey: "soundMuted") }
    }
    
    /// Whether haptics are enabled
    var hapticsEnabled: Bool {
        get { !UserDefaults.standard.bool(forKey: "hapticsDisabled") }
        set { UserDefaults.standard.set(!newValue, forKey: "hapticsDisabled") }
    }
    
    // MARK: - Initialization
    
    private init() {
        configureAudioSession()
    }
    
    // MARK: - Audio Session
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("SoundManager: Audio session error — \(error)")
        }
    }
    
    // MARK: - Play Sound
    
    /// Play a sound effect
    /// - Parameter sound: The sound to play
    func play(_ sound: SoundEffect) {
        guard !isMuted else { return }
        
        // Try custom audio file first
        if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") ??
            Bundle.main.url(forResource: sound.rawValue, withExtension: "m4a") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.volume = volume
                audioPlayer?.play()
                return
            } catch {
                print("SoundManager: Failed to play \(sound.rawValue) — \(error)")
            }
        }
        
        // Fallback to system sound
        AudioServicesPlaySystemSound(sound.systemSoundId)
    }
    
    // MARK: - Volume
    
    /// Set the volume for sound effects (0.0 - 1.0)
    func setVolume(_ newVolume: Float) {
        volume = max(0, min(1, newVolume))
    }
    
    /// Toggle mute state
    func toggleMute() {
        isMuted.toggle()
    }
    
    // MARK: - Haptics
    
    /// Trigger haptic feedback
    /// - Parameter type: The type of haptic to trigger
    func haptic(_ type: HapticType) {
        guard hapticsEnabled else { return }
        
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
    
    // MARK: - Convenience
    
    /// Play XP gain sound + light haptic
    func playXPGain() {
        play(.xpGain)
        haptic(.light)
    }
    
    /// Play quest complete sound + success haptic
    func playQuestComplete() {
        play(.questComplete)
        haptic(.success)
    }
    
    /// Play level up sound + heavy haptics
    func playLevelUp() {
        play(.levelUp)
        haptic(.heavy)
        // Second heavy haptic slightly delayed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [self] in
            haptic(.heavy)
        }
    }
    
    /// Play achievement unlock sound + medium haptic
    func playAchievementUnlocked() {
        play(.achievementUnlocked)
        haptic(.medium)
    }
    
    /// Play penalty zone entry sound + error haptic
    func playPenaltyEnter() {
        play(.penaltyEnter)
        haptic(.error)
    }
}
