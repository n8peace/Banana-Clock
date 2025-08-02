//
//  FullScreenAlarmView.swift
//  BananaClock
//
//  Full-screen alarm experience with AI wake-up integration
//

import SwiftUI
import AVFAudio
import Combine

struct FullScreenAlarmView: View {
    let alarmID: UUID
    let alarmType: AlarmType
    let scheduledTime: Date
    let alarmTitle: String
    let musicSelection: String?
    let voicePreference: String?
    let wakeUpContent: String?
    let alarmSound: String?  // NEW: Added alarm sound identifier
    
    @StateObject private var audioService = AudioService.shared
    @StateObject private var liveActivityService = LiveActivityService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentTime = Date()
    @State private var snoozeCount = 0
    @State private var isAudioPlaying = false
    @State private var audioVisualizationLevels: [CGFloat] = Array(repeating: 0.3, count: 20)
    @State private var showingSnoozeOptions = false
    @State private var backgroundAnimationOffset: CGSize = .zero
    
    // Timer for updating current time and audio visualization
    let timer = Foundation.Timer.publish(every: 1, on: RunLoop.main, in: RunLoop.Mode.common).autoconnect()
    let audioTimer = Foundation.Timer.publish(every: 0.1, on: RunLoop.main, in: RunLoop.Mode.common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background gradient with animation
            backgroundGradient
                .ignoresSafeArea()
                .offset(backgroundAnimationOffset)
                .onAppear {
                    startBackgroundAnimation()
                }
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Current time display
                timeDisplaySection
                
                Spacer()
                
                // AI wake-up content section
                if let content = wakeUpContent, alarmType == .aiWakeUp {
                    aiWakeUpContentSection(content: content)
                    Spacer()
                }
                
                // Audio visualization
                if isAudioPlaying {
                    audioVisualizationSection
                    Spacer()
                }
                
                // Action buttons
                actionButtonsSection
                
                Spacer(minLength: 80)
            }
            .padding(.horizontal, 24)
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onReceive(audioTimer) { _ in
            updateAudioVisualization()
        }
        .onAppear {
            Task {
                await startAlarmExperience()
            }
        }
        .onDisappear {
            Task {
                await stopAlarmExperience()
            }
        }
        .sheet(isPresented: $showingSnoozeOptions) {
            SnoozeOptionsSheet(
                alarmID: alarmID,
                snoozeCount: snoozeCount,
                onSnoozeSelected: { minutes in
                    Task {
                        await handleSnooze(minutes: minutes)
                    }
                },
                onDismiss: {
                    showingSnoozeOptions = false
                }
            )
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        let colors: [Color] = alarmType == .aiWakeUp ? 
            [
                Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.8),   // Soft banana yellow
                Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.6),   // Tangerine orange
                Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.4),   // Warm coral red
                Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.3),   // Soft lavender
                Color.black
            ] : [
                Color.red.opacity(0.6),
                Color.orange.opacity(0.4),
                Color.black
            ]
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.screen)
    }
    
    private var timeDisplaySection: some View {
        VStack(spacing: 8) {
            // Current time
            Text(currentTime, style: .time)
                .font(.system(size: 72, weight: .thin, design: .default))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            // Date
            Text(currentTime, style: .date)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            // Scheduled time reference
            Text("Alarm set for \(scheduledTime, style: .time)")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
        }
    }
    
    private func aiWakeUpContentSection(content: String) -> some View {
        VStack(spacing: 16) {
            // AI indicator
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                
                Text("Your AI Wake-Up Message")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Content
            Text(content)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(BananaTheme.Colors.bananaYellow.opacity(0.15))
                        .stroke(BananaTheme.Colors.bananaYellow.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var audioVisualizationSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 16))
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                
                Text(alarmType == .aiWakeUp ? "AI Wake-Up Audio Playing" : "Alarm Playing")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            // Audio visualization bars
            HStack(spacing: 3) {
                ForEach(0..<audioVisualizationLevels.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(BananaTheme.Colors.bananaYellow)
                        .frame(width: 3)
                        .frame(height: max(4, audioVisualizationLevels[index] * 40))
                        .animation(.easeInOut(duration: 0.1), value: audioVisualizationLevels[index])
                }
            }
            .frame(height: 40)
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Primary action buttons
            HStack(spacing: 24) {
                // Snooze button
                Button(action: {
                    showingSnoozeOptions = true
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.orange)
                        
                        Text("Snooze")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .frame(width: 120, height: 120)
                    .background(
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                    )
                }
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: showingSnoozeOptions)
                
                // I'm Awake button
                Button(action: {
                    Task {
                        await handleImAwake()
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("I'm Awake!")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 140, height: 140)
                    .background(
                        Circle()
                            .fill(Color.green)
                            .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                    )
                }
                .scaleEffect(1.0)
                .hoverEffect(.lift)
            }
            
            // Snooze count indicator
            if snoozeCount > 0 {
                Text("Snoozed \(snoozeCount) time\(snoozeCount == 1 ? "" : "s")")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.3))
                    )
            }
        }
    }
    
    // MARK: - Actions
    
    private func startAlarmExperience() async {
        print("🚨 Starting full-screen alarm experience for alarm: \(alarmID)")
        
        // Start Live Activity
        do {
            try await liveActivityService.startAlarmActivity(
                alarmID: alarmID,
                alarmType: alarmType,
                scheduledTime: scheduledTime,
                title: alarmTitle,
                musicSelection: musicSelection,
                voicePreference: voicePreference,
                wakeUpContent: wakeUpContent
            )
        } catch {
            print("❌ Failed to start alarm Live Activity: \(error)")
        }
        
        // Start AI wake-up audio if available
        if alarmType == .aiWakeUp, 
           let musicSelection = musicSelection,
           let voicePreference = voicePreference {
            
            await startAIWakeUpAudio(musicSelection: musicSelection, voicePreference: voicePreference)
        } else {
            // Play regular alarm sound
            await startRegularAlarmAudio()
        }
        
        isAudioPlaying = true
    }
    
    private func startAIWakeUpAudio(musicSelection: String, voicePreference: String) async {
        do {
            // Store alarm sound preference for the enhanced mixer
            if let alarmSound = alarmSound {
                UserDefaults.standard.set(alarmSound, forKey: "selectedAlarmSound")
            }
            
            // For now, use placeholder URLs - in production these would come from Supabase
            let musicURL = Bundle.main.url(forResource: musicSelection, withExtension: "aac") ??
                          Bundle.main.url(forResource: "ai_music_upbeat", withExtension: "aac")!
            
            let voiceURL = Bundle.main.url(forResource: "ai_wakeup_generic_voice1", withExtension: "aac")!
            
            try await audioService.playAIWakeUpSequence(
                musicURL: musicURL,
                aiAudioURL: voiceURL,
                volume: 0.8
            )
            
            print("✅ Started AI wake-up audio sequence")
        } catch {
            print("❌ Failed to start AI wake-up audio: \(error)")
            await startRegularAlarmAudio()
        }
    }
    
    private func startRegularAlarmAudio() async {
        await MainActor.run {
            let soundIdentifier = alarmSound ?? "alarm_times_up"
            audioService.playSound(soundIdentifier, volume: 0.8)
        }
    }
    
    private func stopAlarmExperience() async {
        print("🛑 Stopping alarm experience")
        
        // Stop audio
        await audioService.stopAIWakeUp()
        await MainActor.run {
            audioService.stopAllSounds()
        }
        
        isAudioPlaying = false
        
        // End Live Activity
        await liveActivityService.endAlarmActivity(alarmID: alarmID)
    }
    
    private func handleImAwake() async {
        print("☀️ User is awake! Dismissing alarm")
        
        // Stop alarm experience
        await stopAlarmExperience()
        
        // Dismiss the alarm Live Activity
        await liveActivityService.dismissAlarmActivity(alarmID: alarmID)
        
        // Record successful wake-up
        UserDefaults.standard.set(Date(), forKey: "lastSuccessfulWakeUp")
        let currentWakeUps = UserDefaults.standard.integer(forKey: "totalWakeUps")
        UserDefaults.standard.set(currentWakeUps + 1, forKey: "totalWakeUps")
        
        // Dismiss the view
        dismiss()
    }
    
    private func handleSnooze(minutes: Int) async {
        print("😴 Snoozing alarm for \(minutes) minutes")
        
        // Stop current audio
        await audioService.stopAIWakeUp()
        await MainActor.run {
            audioService.stopAllSounds()
        }
        
        isAudioPlaying = false
        snoozeCount += 1
        
        // Show snooze countdown in Live Activity
        await liveActivityService.showSnoozeCountdown(
            alarmID: alarmID,
            snoozeMinutes: minutes,
            snoozeCount: snoozeCount
        )
        
        // Schedule new alarm for snooze time
        let snoozeTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        do {
            _ = try await AlarmKitService.shared.scheduleRegularAlarm(
                time: snoozeTime,
                title: "Snooze Alarm (\(snoozeCount))"
            )
        } catch {
            print("❌ Failed to schedule snooze alarm: \(error)")
        }
        
        // Dismiss this view - the snooze alarm will trigger a new one
        dismiss()
    }
    
    // MARK: - Animation Helpers
    
    private func startBackgroundAnimation() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            backgroundAnimationOffset = CGSize(width: 20, height: -30)
        }
    }
    
    private func updateAudioVisualization() {
        guard isAudioPlaying else { return }
        
        for index in 0..<audioVisualizationLevels.count {
            audioVisualizationLevels[index] = CGFloat.random(in: 0.2...1.0)
        }
    }
}

// MARK: - Snooze Options Sheet

struct SnoozeOptionsSheet: View {
    let alarmID: UUID
    let snoozeCount: Int
    let onSnoozeSelected: (Int) -> Void
    let onDismiss: () -> Void
    
    private let snoozeOptions = [5, 10, 15]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text("Snooze Alarm")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if snoozeCount > 0 {
                        Text("Already snoozed \(snoozeCount) time\(snoozeCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                VStack(spacing: 16) {
                    ForEach(snoozeOptions, id: \.self) { minutes in
                        Button(action: {
                            onSnoozeSelected(minutes)
                            onDismiss()
                        }) {
                            HStack {
                                Text("\(minutes) minutes")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.1))
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Snooze Options")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel", action: onDismiss))
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    FullScreenAlarmView(
        alarmID: UUID(),
        alarmType: .aiWakeUp,
        scheduledTime: Date(),
        alarmTitle: "AI Wake-Up",
        musicSelection: "ai_music_upbeat",
        voicePreference: "voice1",
        wakeUpContent: "Good morning! It's a beautiful day to accomplish your goals. The weather is perfect and you have exciting opportunities ahead of you today.",
        alarmSound: "alarm_times_up"
    )
}