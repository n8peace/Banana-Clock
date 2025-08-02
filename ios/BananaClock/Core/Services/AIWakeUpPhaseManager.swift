//
//  AIWakeUpPhaseManager.swift
//  BananaClock
//
//  Manages the phases and timing of the AI wake-up audio experience
//

import Foundation

// MARK: - Wake-Up Phase Enum

enum WakeUpPhase: String, CaseIterable {
    case idle = "idle"
    case musicFadeIn = "music_fade_in"
    case voiceOverlay = "voice_overlay"
    case musicCrescendo = "music_crescendo"
    case alarmSound = "alarm_sound"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .musicFadeIn: return "Music Fade In"
        case .voiceOverlay: return "AI Voice"
        case .musicCrescendo: return "Music Crescendo"
        case .alarmSound: return "Alarm"
        case .completed: return "Completed"
        }
    }
}

// MARK: - Phase Manager

@MainActor
class AIWakeUpPhaseManager: ObservableObject {
    // Published properties for UI updates
    @Published var currentPhase: WakeUpPhase = .idle
    @Published var phaseProgress: Double = 0.0
    @Published var elapsedTime: TimeInterval = 0.0
    
    // Timing configuration
    private let musicFadeInDuration: TimeInterval = 10.0
    private let voiceStartDelay: TimeInterval = 15.0
    private let musicCrescendoDuration: TimeInterval = 20.0
    private let maxAlarmDuration: TimeInterval = 300.0 // 5 minutes
    
    // State tracking
    private var startTime: Date?
    private var voiceEndTime: Date?
    private var phaseTimer: Foundation.Timer?
    private var autoStopTimer: Foundation.Timer?
    
    // Callbacks for phase transitions
    var onPhaseChange: ((WakeUpPhase) -> Void)?
    var onAutoStop: (() -> Void)?
    
    // MARK: - Lifecycle
    
    func startSequence() {
        print("🎵 AIWakeUpPhaseManager: Starting wake-up sequence")
        
        startTime = Date()
        currentPhase = .musicFadeIn
        elapsedTime = 0
        
        // Start phase timer for progress updates
        phaseTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        
        // Schedule auto-stop
        scheduleAutoStop()
        
        // Notify phase change
        onPhaseChange?(.musicFadeIn)
    }
    
    func stopSequence() {
        print("🛑 AIWakeUpPhaseManager: Stopping wake-up sequence")
        
        phaseTimer?.invalidate()
        phaseTimer = nil
        
        autoStopTimer?.invalidate()
        autoStopTimer = nil
        
        currentPhase = .idle
        phaseProgress = 0.0
        elapsedTime = 0.0
        startTime = nil
        voiceEndTime = nil
    }
    
    // MARK: - Phase Management
    
    func transitionToVoicePhase() {
        guard currentPhase == .musicFadeIn else { return }
        
        print("🎙️ AIWakeUpPhaseManager: Transitioning to voice overlay phase")
        currentPhase = .voiceOverlay
        phaseProgress = 0.0
        onPhaseChange?(.voiceOverlay)
    }
    
    func markVoiceCompleted() {
        guard currentPhase == .voiceOverlay else { return }
        
        print("🎵 AIWakeUpPhaseManager: Voice completed, transitioning to crescendo")
        voiceEndTime = Date()
        currentPhase = .musicCrescendo
        phaseProgress = 0.0
        onPhaseChange?(.musicCrescendo)
    }
    
    func transitionToAlarmPhase() {
        guard currentPhase == .musicCrescendo else { return }
        
        print("⏰ AIWakeUpPhaseManager: Transitioning to alarm sound")
        currentPhase = .alarmSound
        phaseProgress = 0.0
        onPhaseChange?(.alarmSound)
    }
    
    // MARK: - Volume Calculations
    
    func volumeMultiplier(for phase: WakeUpPhase, userVolume: Float) -> Float {
        let baseVolume = min(1.0, max(0.0, userVolume))
        
        switch phase {
        case .musicFadeIn, .voiceOverlay:
            return baseVolume * 0.6  // 60% during voice phases
        case .musicCrescendo:
            // Gradually increase from 60% to 120%
            let crescendoProgress = phaseProgress
            let startMultiplier: Float = 0.6
            let endMultiplier: Float = 1.2
            let currentMultiplier = startMultiplier + (endMultiplier - startMultiplier) * Float(crescendoProgress)
            return min(1.0, baseVolume * currentMultiplier)  // Cap at 100%
        case .alarmSound:
            return min(1.0, baseVolume * 1.2)  // 120% but capped at 100%
        default:
            return baseVolume
        }
    }
    
    func musicVolume(userVolume: Float) -> Float {
        switch currentPhase {
        case .musicFadeIn:
            // Fade from 0% to 60% over 10 seconds
            let fadeProgress = Float(phaseProgress)
            return userVolume * 0.6 * fadeProgress
        case .voiceOverlay:
            // Steady at 60%
            return userVolume * 0.6
        case .musicCrescendo:
            // Increase from 60% to 120% over 20 seconds
            let startVolume = userVolume * 0.6
            let endVolume = min(1.0, userVolume * 1.2)
            let crescendoProgress = Float(phaseProgress)
            return startVolume + (endVolume - startVolume) * crescendoProgress
        default:
            return 0
        }
    }
    
    func voiceVolume(userVolume: Float) -> Float {
        guard currentPhase == .voiceOverlay else { return 0 }
        return userVolume  // 100% of user volume
    }
    
    func alarmVolume(userVolume: Float) -> Float {
        guard currentPhase == .alarmSound else { return 0 }
        return min(1.0, userVolume * 1.2)  // 120% but capped
    }
    
    // MARK: - Timing Helpers
    
    func shouldStartVoice(at time: TimeInterval) -> Bool {
        return time >= voiceStartDelay && currentPhase == .musicFadeIn
    }
    
    func shouldTransitionToCrescendo() -> Bool {
        return currentPhase == .voiceOverlay && voiceEndTime != nil
    }
    
    func shouldTransitionToAlarm() -> Bool {
        guard currentPhase == .musicCrescendo,
              let voiceEnd = voiceEndTime else { return false }
        
        let timeSinceVoiceEnd = Date().timeIntervalSince(voiceEnd)
        return timeSinceVoiceEnd >= musicCrescendoDuration
    }
    
    // MARK: - Private Methods
    
    private func updateProgress() {
        guard let startTime = startTime else { return }
        
        elapsedTime = Date().timeIntervalSince(startTime)
        
        // Update phase progress
        switch currentPhase {
        case .musicFadeIn:
            phaseProgress = min(1.0, elapsedTime / musicFadeInDuration)
            
            // Check for voice start
            if shouldStartVoice(at: elapsedTime) {
                transitionToVoicePhase()
            }
            
        case .voiceOverlay:
            // Progress is managed externally based on voice duration
            break
            
        case .musicCrescendo:
            if let voiceEnd = voiceEndTime {
                let timeSinceCrescendoStart = Date().timeIntervalSince(voiceEnd)
                phaseProgress = min(1.0, timeSinceCrescendoStart / musicCrescendoDuration)
                
                // Check for alarm transition
                if shouldTransitionToAlarm() {
                    transitionToAlarmPhase()
                }
            }
            
        case .alarmSound:
            // Alarm continues until stopped
            break
            
        default:
            break
        }
    }
    
    private func scheduleAutoStop() {
        autoStopTimer = Foundation.Timer.scheduledTimer(
            withTimeInterval: maxAlarmDuration,
            repeats: false
        ) { [weak self] _ in
            print("⏱️ AIWakeUpPhaseManager: Auto-stop triggered after 5 minutes")
            self?.onAutoStop?()
            self?.stopSequence()
        }
    }
}

// MARK: - Extensions

extension AIWakeUpPhaseManager {
    // Convenience method to get current state as a dictionary
    var currentState: [String: Any] {
        return [
            "phase": currentPhase.rawValue,
            "progress": phaseProgress,
            "elapsedTime": elapsedTime,
            "musicVolume": musicVolume(userVolume: 1.0),
            "voiceVolume": voiceVolume(userVolume: 1.0),
            "alarmVolume": alarmVolume(userVolume: 1.0)
        ]
    }
}