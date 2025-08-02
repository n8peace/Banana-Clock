//
//  AudioService.swift
//  BananaClock
//
//  Audio playback and AI wake-up management
//

import Foundation
@preconcurrency import AVFoundation
import MediaPlayer
import SwiftUI

@MainActor
class AudioService: ObservableObject {
    static let shared = AudioService()
    
    private var audioEngine = AVAudioEngine()
    private var backgroundMusicPlayer: AVAudioPlayerNode?
    private var aiVoicePlayer: AVAudioPlayerNode?
    private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    
    // NEW: AI Wake-Up Audio Mixer for enhanced experience
    private var aiWakeUpMixer: AIWakeUpAudioMixer?
    private var useEnhancedMixer = true  // Feature flag for gradual rollout
    
    @Published var isPlayingAIWakeUp = false
    @Published var currentAudioProgress: Double = 0
    
    private init() {
        setupAudioSession()
        
        // Initialize the enhanced mixer if enabled
        if useEnhancedMixer {
            aiWakeUpMixer = AIWakeUpAudioMixer()
        }
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // Configure for alarm playback
            try session.setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .allowAirPlay]
            )
            
            // Set as active
            try session.setActive(true)
            
            // Enable remote control
            setupRemoteControls()
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - AI Wake-Up Playback
    
    func playAIWakeUpSequence(
        musicURL: URL,
        aiAudioURL: URL,
        volume: Float = 0.7
    ) async throws {
        // NEW: Use enhanced mixer if available
        if useEnhancedMixer, let mixer = aiWakeUpMixer {
            print("🎵 Using enhanced AI wake-up mixer")
            
            isPlayingAIWakeUp = true
            
            do {
                // Get alarm sound identifier from user preferences (default to times_up)
                let alarmSound = UserDefaults.standard.string(forKey: "selectedAlarmSound") ?? "alarm_times_up"
                
                try await mixer.startWakeUpSequence(
                    musicURL: musicURL,
                    voiceURL: aiAudioURL,
                    alarmSoundIdentifier: alarmSound,
                    userVolume: volume
                )
                
                // Monitor mixer state
                Task { @MainActor in
                    for await phase in mixer.$currentPhase.values {
                        if phase == .completed || phase == .idle {
                            self.isPlayingAIWakeUp = false
                        }
                    }
                }
                
                return
            } catch {
                print("❌ Enhanced mixer failed, falling back to legacy: \(error)")
                // Fall through to legacy implementation
            }
        }
        
        // LEGACY: Original implementation for fallback
        isPlayingAIWakeUp = true
        
        do {
            // Reset audio engine
            audioEngine.stop()
            audioEngine.reset()
            
            // Create players
            backgroundMusicPlayer = AVAudioPlayerNode()
            aiVoicePlayer = AVAudioPlayerNode()
            
            guard let musicPlayer = backgroundMusicPlayer,
                  let voicePlayer = aiVoicePlayer else {
                throw AudioError.playerCreationFailed
            }
            
            // Attach to engine
            audioEngine.attach(musicPlayer)
            audioEngine.attach(voicePlayer)
            
            // Load audio files
            let musicFile = try AVAudioFile(forReading: musicURL)
            let voiceFile = try AVAudioFile(forReading: aiAudioURL)
            
            // Create mixers for volume control
            let musicMixer = AVAudioMixerNode()
            let voiceMixer = AVAudioMixerNode()
            audioEngine.attach(musicMixer)
            audioEngine.attach(voiceMixer)
            
            // Connect nodes
            audioEngine.connect(musicPlayer, to: musicMixer, format: musicFile.processingFormat)
            audioEngine.connect(voicePlayer, to: voiceMixer, format: voiceFile.processingFormat)
            audioEngine.connect(musicMixer, to: audioEngine.mainMixerNode, format: nil)
            audioEngine.connect(voiceMixer, to: audioEngine.mainMixerNode, format: nil)
            
            // Start engine
            try audioEngine.start()
            
            // Schedule music (looped)
            musicPlayer.scheduleFile(musicFile, at: nil) { [weak self] in
                Task { @MainActor in
                    self?.scheduleNextMusicLoop(file: musicFile, player: musicPlayer)
                }
            }
            
            // Start music at low volume
            musicMixer.volume = volume * 0.1
            await musicPlayer.play()
            
            // Fade in music over 30 seconds
            await fadeVolume(
                mixer: musicMixer,
                from: volume * 0.1,
                to: volume,
                duration: 30.0
            )
            
            // After 10 seconds, start AI voice
            try await Task.sleep(nanoseconds: 10_000_000_000)
            
            // Play AI voice at 80% of target volume
            voiceMixer.volume = volume * 0.8
            voicePlayer.scheduleFile(voiceFile, at: nil) { [weak self] in
                Task { @MainActor in
                    self?.handleAIVoiceCompletion()
                }
            }
            await voicePlayer.play()
            
            // Update now playing info
            updateNowPlayingInfo(title: "AI Wake-Up", artist: "BANANA")
            
        } catch {
            isPlayingAIWakeUp = false
            throw error
        }
    }
    
    private func scheduleNextMusicLoop(file: AVAudioFile, player: AVAudioPlayerNode) {
        guard isPlayingAIWakeUp else { return }
        
        player.scheduleFile(file, at: nil) { [weak self] in
            Task { @MainActor in
                self?.scheduleNextMusicLoop(file: file, player: player)
            }
        }
    }
    
    private func handleAIVoiceCompletion() {
        // AI voice finished, continue music for a bit then fade out
        Task {
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            await stopAIWakeUp()
        }
    }
    
    func stopAIWakeUp() async {
        guard isPlayingAIWakeUp else { return }
        
        // NEW: Stop enhanced mixer if in use
        if let mixer = aiWakeUpMixer, mixer.isPlaying {
            await mixer.stopAllAudio()
            isPlayingAIWakeUp = false
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        // LEGACY: Original stop implementation
        // Fade out music
        // if let musicMixer = audioEngine.mainMixerNode.upstream?.upstream as? AVAudioMixerNode {
        //     await fadeVolume(mixer: musicMixer, from: musicMixer.volume, to: 0, duration: 2.0)
        // }
        
        // Stop everything
        backgroundMusicPlayer?.stop()
        aiVoicePlayer?.stop()
        audioEngine.stop()
        
        isPlayingAIWakeUp = false
        
        // Clear now playing
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }
    
    // MARK: - Standard Alarm Sounds
    
    func playSound(_ soundIdentifier: String, volume: Float = 0.7) {
        print("🔊 AudioService.playSound called with identifier: '\(soundIdentifier)'")
        do {
            try playAlarmSound(soundIdentifier, volume: volume)
            print("✅ Successfully playing sound: \(soundIdentifier)")
        } catch {
            print("❌ Failed to play sound \(soundIdentifier): \(error)")
            
            // Fallback: try timer_complete as default for any failed sound
            if soundIdentifier != "timer_complete" {
                print("🔄 Attempting fallback to timer_complete...")
                do {
                    try playAlarmSound("timer_complete", volume: volume)
                    print("✅ Fallback successful: timer_complete")
                } catch {
                    print("❌ Fallback also failed: \(error)")
                    print("🔍 Available audio files in bundle:")
                    if let bundlePath = Bundle.main.resourcePath {
                        let extensions = ["mp3", "aac", "caf"]
                        for ext in extensions {
                            if let files = try? FileManager.default.contentsOfDirectory(atPath: bundlePath).filter({ $0.hasSuffix(".\(ext)") }) {
                                print("   \(ext.uppercased()): \(files)")
                            }
                        }
                    }
                }
            } else {
                print("🔍 Available audio files in bundle:")
                if let bundlePath = Bundle.main.resourcePath {
                    let extensions = ["mp3", "aac", "caf"]
                    for ext in extensions {
                        if let files = try? FileManager.default.contentsOfDirectory(atPath: bundlePath).filter({ $0.hasSuffix(".\(ext)") }) {
                            print("   \(ext.uppercased()): \(files)")
                        }
                    }
                }
            }
        }
    }
    
    func playAlarmSound(_ soundIdentifier: String, volume: Float = 0.7) throws {
        // Try multiple file extensions for sound resolution
        var soundURL: URL?
        let extensions = ["caf", "mp3", "aac"]
        
        for ext in extensions {
            if let url = Bundle.main.url(forResource: soundIdentifier, withExtension: ext) {
                soundURL = url
                break
            }
        }
        
        guard let soundURL = soundURL else {
            throw AudioError.soundNotFound
        }
        
        let player = try AVAudioPlayer(contentsOf: soundURL)
        player.volume = volume
        player.numberOfLoops = -1 // Loop indefinitely
        player.prepareToPlay()
        player.play()
        
        let playerId = UUID()
        audioPlayers[playerId] = player
    }
    
    func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
        audioPlayers.removeAll()
    }
    
    // MARK: - Timer Sounds
    
    func playTimerComplete() {
        do {
            guard let soundURL = Bundle.main.url(
                forResource: "alarm_times_up",
                withExtension: "caf"
            ) else { return }
            
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.volume = 0.7
            player.play()
        } catch {
            print("Failed to play timer sound: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func fadeVolume(
        mixer: AVAudioMixerNode,
        from startVolume: Float,
        to endVolume: Float,
        duration: TimeInterval
    ) async {
        let steps = Int(duration * 10) // 10 updates per second
        let increment = (endVolume - startVolume) / Float(steps)
        
        for _ in 0..<steps {
            mixer.volume = min(1.0, max(0, mixer.volume + increment))
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        mixer.volume = endVolume
    }
    
    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { _ in
            // Handle play
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in
                await self?.stopAIWakeUp()
            }
            return .success
        }
    }
    
    private func updateNowPlayingInfo(title: String, artist: String) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
    
    // MARK: - Fallback Audio
    
    func downloadAndCacheAIAudio(from url: URL) async throws -> URL {
        let session = URLSession.shared
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AudioError.playbackError("Download failed")
        }
        
        // Cache to documents directory
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let fileName = url.lastPathComponent
        let localURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: localURL)
        return localURL
    }
    
    func getFallbackAIAudioURL(for voice: String) -> URL? {
        let fileName: String
        switch voice {
        case "voice_1":
            fileName = "ai_wakeup_generic_voice1"
        case "voice_2":
            fileName = "ai_wakeup_generic_voice2"
        case "voice_3":
            fileName = "ai_wakeup_generic_voice3"
        default:
            fileName = "ai_wakeup_generic_voice1" // Default to voice 1
        }
        
        return Bundle.main.url(forResource: fileName, withExtension: "aac")
    }
    
    func getAIAudioURL(for date: Date, voice: String) async -> URL? {
        // First try to get cached audio
        if let cachedURL = getCachedAudioURL(for: date, voice: voice) {
            print("✅ Using cached AI audio for \(voice)")
            return cachedURL
        }
        
        // If no cached audio, try to get fallback audio
        if let fallbackURL = getFallbackAIAudioURL(for: voice) {
            print("🔄 Using fallback AI audio for \(voice)")
            return fallbackURL
        }
        
        print("❌ No AI audio available for \(voice)")
        return nil
    }
    
    func playAIWakeUpWithFallback(
        musicURL: URL,
        date: Date,
        voice: String,
        volume: Float = 0.7
    ) async throws {
        // Try to get AI audio with fallback
        guard let aiAudioURL = await getAIAudioURL(for: date, voice: voice) else {
            throw AudioError.playbackError("No AI audio available")
        }
        
        // Play the AI wake-up sequence
        try await playAIWakeUpSequence(musicURL: musicURL, aiAudioURL: aiAudioURL, volume: volume)
    }
    
    func getCachedAudioURL(for date: Date, voice: String) -> URL? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let dateString = formatter.string(from: date)
        
        let fileName = "ai_wakeup_\(dateString)_\(voice).aac"
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let localURL = documentsPath.appendingPathComponent(fileName)
        
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }
    
    // MARK: - Background Music Preview
    
    private var previewPlayer: AVAudioPlayer?
    @Published var isPlayingPreview = false
    @Published var currentPreviewMusic: MusicOption?
    
    func playMusicPreview(_ music: MusicOption, volume: Float = 0.7) {
        // Stop any existing preview
        stopMusicPreview()
        
        // Load AAC music files
        print("🎵 Attempting to play music preview: \(music.displayName)")
        print("📁 Looking for file: \(music.fileName).aac")
        
        guard let audioURL = Bundle.main.url(forResource: music.fileName, withExtension: "aac") else {
            print("❌ Failed to find audio file for \(music.fileName).aac")
            print("📂 Bundle path: \(Bundle.main.bundlePath)")
            print("🔍 Available resources in bundle:")
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    files.filter { $0.contains("ai_music") }.forEach { print("   - \($0)") }
                } catch {
                    print("   Error listing bundle contents: \(error)")
                }
            }
            return
        }
        
        print("✅ Found audio file: \(audioURL.path)")
        
        do {
            let player = try AVAudioPlayer(contentsOf: audioURL)
            print("🎵 Audio player created successfully")
            print("⏱️ Duration: \(player.duration) seconds")
            
            player.volume = 0 // Start at 0 for fade-in
            player.prepareToPlay()
            let playResult = player.play()
            print("▶️ Play result: \(playResult)")
            
            previewPlayer = player
            currentPreviewMusic = music
            isPlayingPreview = true
            
            // Fade in over 3 seconds
            Task {
                await fadePreviewVolume(from: 0, to: volume, duration: 3.0)
                
                // Play for 14 seconds at full volume
                try await Task.sleep(nanoseconds: 14_000_000_000)
                
                // Fade out over 3 seconds
                await fadePreviewVolume(from: volume, to: 0, duration: 3.0)
                
                // Stop preview
                await MainActor.run {
                    stopMusicPreview()
                }
            }
            
        } catch {
            print("❌ Failed to play music preview: \(error)")
            print("📁 Audio file path: \(audioURL.path)")
            print("🔍 Error details: \(error.localizedDescription)")
        }
    }
    
    func stopMusicPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPlayingPreview = false
        currentPreviewMusic = nil
    }
    
    private func fadePreviewVolume(
        from startVolume: Float,
        to endVolume: Float,
        duration: TimeInterval
    ) async {
        guard let player = previewPlayer else { return }
        
        let steps = Int(duration * 10) // 10 updates per second
        let increment = (endVolume - startVolume) / Float(steps)
        
        for _ in 0..<steps {
            await MainActor.run {
                player.volume = min(1.0, max(0, player.volume + increment))
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        await MainActor.run {
            player.volume = endVolume
        }
    }
}

// MARK: - Error Types
// Note: AudioError is defined in Core/Utilities/error-types.swift