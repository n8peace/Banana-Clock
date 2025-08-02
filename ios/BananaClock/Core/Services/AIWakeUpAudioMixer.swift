//
//  AIWakeUpAudioMixer.swift
//  BananaClock
//
//  Advanced audio mixer for AI wake-up experience with precise phase control
//

import Foundation
import AVFoundation
import SwiftUI
import Combine
@preconcurrency import MediaPlayer

@MainActor
class AIWakeUpAudioMixer: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isPlaying = false
    @Published var currentPhase: WakeUpPhase = .idle
    @Published var errorMessage: String?
    
    // MARK: - Audio Components
    
    private let audioEngine = AVAudioEngine()
    private var musicPlayerNode: AVAudioPlayerNode?
    private var voicePlayerNode: AVAudioPlayerNode?
    private var alarmPlayerNode: AVAudioPlayerNode?
    
    private var musicMixerNode: AVAudioMixerNode?
    private var voiceMixerNode: AVAudioMixerNode?
    private var alarmMixerNode: AVAudioMixerNode?
    
    // MARK: - Audio Files
    
    private var musicFile: AVAudioFile?
    private var voiceFile: AVAudioFile?
    private var alarmFile: AVAudioFile?
    
    // MARK: - Phase Management
    
    private let phaseManager = AIWakeUpPhaseManager()
    private var phaseSubscription: AnyCancellable?
    
    // MARK: - Volume Control
    
    private var userVolume: Float = 0.7
    private var volumeUpdateTimer: Foundation.Timer?
    
    // MARK: - State
    
    private var isVoicePlaying = false
    private var voiceDuration: TimeInterval = 0
    
    // MARK: - Initialization
    
    init() {
        setupPhaseManager()
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupPhaseManager() {
        // Subscribe to phase changes
        phaseSubscription = phaseManager.$currentPhase
            .receive(on: RunLoop.main)
            .sink { [weak self] phase in
                self?.currentPhase = phase
                self?.handlePhaseChange(phase)
            }
        
        // Handle auto-stop
        phaseManager.onAutoStop = { [weak self] in
            Task { @MainActor in
                await self?.stopAllAudio()
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Configure for alarm playback with background support
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay]
            )
            
            try session.setActive(true)
            
            print("✅ AIWakeUpAudioMixer: Audio session configured")
        } catch {
            print("❌ AIWakeUpAudioMixer: Failed to setup audio session: \(error)")
            errorMessage = "Audio setup failed"
        }
    }
    
    // MARK: - Public API
    
    func startWakeUpSequence(
        musicURL: URL,
        voiceURL: URL,
        alarmSoundIdentifier: String = "alarm_times_up",
        userVolume: Float = 0.7
    ) async throws {
        print("🎵 AIWakeUpAudioMixer: Starting wake-up sequence")
        print("  - Music: \(musicURL.lastPathComponent)")
        print("  - Voice: \(voiceURL.lastPathComponent)")
        print("  - Alarm: \(alarmSoundIdentifier)")
        print("  - Volume: \(userVolume)")
        
        self.userVolume = min(1.0, max(0.0, userVolume))
        
        do {
            // Load audio files
            try await loadAudioFiles(
                musicURL: musicURL,
                voiceURL: voiceURL,
                alarmSoundIdentifier: alarmSoundIdentifier
            )
            
            // Setup audio engine
            try setupAudioEngine()
            
            // Start the phase manager
            phaseManager.startSequence()
            
            // Start music playback
            try startMusicPlayback()
            
            isPlaying = true
            errorMessage = nil
            
            // Schedule voice start
            scheduleVoiceStart()
            
            // Start volume updates
            startVolumeUpdates()
            
        } catch {
            print("❌ AIWakeUpAudioMixer: Failed to start sequence: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func stopAllAudio() async {
        print("🛑 AIWakeUpAudioMixer: Stopping all audio")
        
        // Stop phase manager
        phaseManager.stopSequence()
        
        // Stop volume updates
        volumeUpdateTimer?.invalidate()
        volumeUpdateTimer = nil
        
        // Stop all player nodes
        musicPlayerNode?.stop()
        voicePlayerNode?.stop()
        alarmPlayerNode?.stop()
        
        // Stop and reset audio engine
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.reset()
        }
        
        // Clear state
        isPlaying = false
        isVoicePlaying = false
        currentPhase = .idle
        
        // Clear audio files
        musicFile = nil
        voiceFile = nil
        alarmFile = nil
    }
    
    // MARK: - Audio File Loading
    
    private func loadAudioFiles(
        musicURL: URL,
        voiceURL: URL,
        alarmSoundIdentifier: String
    ) async throws {
        // Load music file
        do {
            musicFile = try AVAudioFile(forReading: musicURL)
            print("✅ Loaded music file: \(musicURL.lastPathComponent)")
        } catch {
            print("❌ Failed to load music file: \(error)")
            throw AudioError.fileNotFound
        }
        
        // Load voice file
        do {
            voiceFile = try AVAudioFile(forReading: voiceURL)
            
            // Calculate voice duration
            if let format = voiceFile?.processingFormat {
                voiceDuration = Double(voiceFile?.length ?? 0) / format.sampleRate
                print("✅ Loaded voice file: \(voiceURL.lastPathComponent), duration: \(voiceDuration)s")
            }
        } catch {
            print("❌ Failed to load voice file: \(error)")
            throw AudioError.fileNotFound
        }
        
        // Load alarm sound
        let alarmURL = findAlarmSoundURL(identifier: alarmSoundIdentifier)
        if let alarmURL = alarmURL {
            do {
                alarmFile = try AVAudioFile(forReading: alarmURL)
                print("✅ Loaded alarm file: \(alarmURL.lastPathComponent)")
            } catch {
                print("⚠️ Failed to load alarm file, will use fallback: \(error)")
            }
        }
    }
    
    private func findAlarmSoundURL(identifier: String) -> URL? {
        // Try multiple extensions
        let extensions = ["caf", "mp3", "aac"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: identifier, withExtension: ext) {
                return url
            }
        }
        
        // Fallback to default alarm sound
        return Bundle.main.url(forResource: "alarm_times_up", withExtension: "caf")
    }
    
    // MARK: - Audio Engine Setup
    
    private func setupAudioEngine() throws {
        // Reset engine
        audioEngine.stop()
        audioEngine.reset()
        
        // Create player nodes
        musicPlayerNode = AVAudioPlayerNode()
        voicePlayerNode = AVAudioPlayerNode()
        alarmPlayerNode = AVAudioPlayerNode()
        
        // Create mixer nodes
        musicMixerNode = AVAudioMixerNode()
        voiceMixerNode = AVAudioMixerNode()
        alarmMixerNode = AVAudioMixerNode()
        
        guard let musicPlayer = musicPlayerNode,
              let voicePlayer = voicePlayerNode,
              let alarmPlayer = alarmPlayerNode,
              let musicMixer = musicMixerNode,
              let voiceMixer = voiceMixerNode,
              let alarmMixer = alarmMixerNode else {
            throw AudioError.playerCreationFailed
        }
        
        // Attach nodes to engine
        audioEngine.attach(musicPlayer)
        audioEngine.attach(voicePlayer)
        audioEngine.attach(alarmPlayer)
        audioEngine.attach(musicMixer)
        audioEngine.attach(voiceMixer)
        audioEngine.attach(alarmMixer)
        
        // Connect nodes
        if let musicFormat = musicFile?.processingFormat {
            audioEngine.connect(musicPlayer, to: musicMixer, format: musicFormat)
        }
        
        if let voiceFormat = voiceFile?.processingFormat {
            audioEngine.connect(voicePlayer, to: voiceMixer, format: voiceFormat)
        }
        
        if let alarmFormat = alarmFile?.processingFormat {
            audioEngine.connect(alarmPlayer, to: alarmMixer, format: alarmFormat)
        }
        
        // Connect mixers to main mixer
        audioEngine.connect(musicMixer, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.connect(voiceMixer, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.connect(alarmMixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Start engine
        try audioEngine.start()
        
        print("✅ AIWakeUpAudioMixer: Audio engine configured and started")
    }
    
    // MARK: - Playback Control
    
    private func startMusicPlayback() throws {
        guard let musicPlayer = musicPlayerNode,
              let musicFile = musicFile,
              let musicMixer = musicMixerNode else {
            throw AudioError.playerCreationFailed
        }
        
        // Set initial volume (0 for fade-in)
        musicMixer.volume = 0
        
        // Schedule music file (looped)
        scheduleMusicLoop()
        
        // Start playback
        musicPlayer.play()
        
        print("▶️ AIWakeUpAudioMixer: Music playback started")
    }
    
    private func scheduleMusicLoop() {
        guard let musicPlayer = musicPlayerNode,
              let musicFile = musicFile else { return }
        
        musicPlayer.scheduleFile(musicFile, at: nil) { [weak self] in
            // Schedule next loop
            DispatchQueue.main.async {
                if self?.isPlaying == true && 
                   (self?.currentPhase == .musicFadeIn || 
                    self?.currentPhase == .voiceOverlay || 
                    self?.currentPhase == .musicCrescendo) {
                    self?.scheduleMusicLoop()
                }
            }
        }
    }
    
    private func scheduleVoiceStart() {
        Task {
            // Wait for voice start time (15 seconds)
            try await Task.sleep(nanoseconds: 15_000_000_000)
            
            guard isPlaying, currentPhase == .voiceOverlay else { return }
            
            await startVoicePlayback()
        }
    }
    
    private func startVoicePlayback() async {
        guard let voicePlayer = voicePlayerNode,
              let voiceFile = voiceFile,
              let voiceMixer = voiceMixerNode else { return }
        
        print("🎙️ AIWakeUpAudioMixer: Starting voice playback")
        
        // Set voice volume
        voiceMixer.volume = phaseManager.voiceVolume(userVolume: userVolume)
        
        // Schedule voice file
        voicePlayer.scheduleFile(voiceFile, at: nil) { [weak self] in
            // Voice completed
            DispatchQueue.main.async {
                self?.handleVoiceCompletion()
            }
        }
        
        // Start playback
        voicePlayer.play()
        isVoicePlaying = true
    }
    
    private func handleVoiceCompletion() {
        print("✅ AIWakeUpAudioMixer: Voice playback completed")
        
        isVoicePlaying = false
        phaseManager.markVoiceCompleted()
        
        // Schedule alarm sound after crescendo
        Task {
            try await Task.sleep(nanoseconds: 20_000_000_000) // 20 seconds
            
            guard isPlaying, currentPhase == .alarmSound else { return }
            
            await startAlarmPlayback()
        }
    }
    
    private func startAlarmPlayback() async {
        // Stop music
        musicPlayerNode?.stop()
        
        guard let alarmPlayer = alarmPlayerNode,
              let alarmFile = alarmFile,
              let alarmMixer = alarmMixerNode else {
            print("⚠️ AIWakeUpAudioMixer: No alarm file available")
            return
        }
        
        print("⏰ AIWakeUpAudioMixer: Starting alarm playback")
        
        // Set alarm volume
        alarmMixer.volume = phaseManager.alarmVolume(userVolume: userVolume)
        
        // Schedule alarm file (looped)
        func scheduleAlarmLoop() {
            alarmPlayer.scheduleFile(alarmFile, at: nil) { [weak self] in
                DispatchQueue.main.async {
                    if self?.isPlaying == true && self?.currentPhase == .alarmSound {
                        scheduleAlarmLoop()
                    }
                }
            }
        }
        
        scheduleAlarmLoop()
        alarmPlayer.play()
    }
    
    // MARK: - Volume Updates
    
    private func startVolumeUpdates() {
        volumeUpdateTimer = Foundation.Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            self?.updateVolumes()
        }
    }
    
    private func updateVolumes() {
        // Update music volume based on phase
        if let musicMixer = musicMixerNode {
            let targetVolume = phaseManager.musicVolume(userVolume: userVolume)
            
            // Smooth volume changes
            let currentVolume = musicMixer.volume
            let volumeDelta = (targetVolume - currentVolume) * 0.3
            musicMixer.volume = currentVolume + volumeDelta
        }
        
        // Update voice volume if playing
        if isVoicePlaying, let voiceMixer = voiceMixerNode {
            voiceMixer.volume = phaseManager.voiceVolume(userVolume: userVolume)
        }
    }
    
    // MARK: - Phase Handling
    
    private func handlePhaseChange(_ phase: WakeUpPhase) {
        print("🔄 AIWakeUpAudioMixer: Phase changed to \(phase.displayName)")
        
        switch phase {
        case .voiceOverlay:
            // Voice start is scheduled separately
            break
            
        case .musicCrescendo:
            // Volume changes handled by updateVolumes
            break
            
        case .alarmSound:
            // Alarm start is scheduled after crescendo
            break
            
        default:
            break
        }
    }
}