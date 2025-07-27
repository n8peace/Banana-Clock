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
    
    @Published var isPlayingAIWakeUp = false
    @Published var currentAudioProgress: Double = 0
    
    private init() {
        setupAudioSession()
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
        do {
            try playAlarmSound(soundIdentifier, volume: volume)
        } catch {
            print("Failed to play sound \(soundIdentifier): \(error)")
        }
    }
    
    func playAlarmSound(_ soundIdentifier: String, volume: Float = 0.7) throws {
        guard let soundURL = Bundle.main.url(
            forResource: soundIdentifier,
            withExtension: "caf"
        ) else {
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
                forResource: "timer_complete",
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
}

// MARK: - Error Types
// Note: AudioError is defined in Core/Utilities/error-types.swift