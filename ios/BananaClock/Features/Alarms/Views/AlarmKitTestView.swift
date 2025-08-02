//
//  AlarmKitTestView.swift
//  BananaClock
//
//  Test view for AlarmKit integration (development only)
//

import SwiftUI
import AlarmKit

// Type alias to use AlarmKit.Alarm in this view
typealias AlarmKitAlarm = AlarmKit.Alarm

struct AlarmKitTestView: View {
    @EnvironmentObject private var alarmKitService: AlarmKitService
    @Environment(\.dismiss) private var dismiss
    @State private var testDate = Date()
    @State private var isLoading = false
    @State private var statusMessage = ""
    
    // AI Wake-Up Test States
    @State private var selectedMusic = MusicOption.upbeat
    @State private var selectedVoice = AIVoiceOption.voice1
    @State private var selectedAlarmSound = AlarmSound.timesUp
    @State private var testVolume: Float = 0.7
    @State private var isPlayingAIWakeUp = false
    @State private var currentPhase = "Idle"
    @State private var elapsedTime: TimeInterval = 0
    @State private var phaseTimer: Foundation.Timer?
    @StateObject private var audioService = AudioService.shared

    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Authorization Status
                VStack(alignment: .leading, spacing: 8) {
                    Text("AlarmKit Status")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack {
                        Circle()
                            .fill(authorizationColor)
                            .frame(width: 12, height: 12)
                        Text(authorizationText)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
                
                // Current Alarms - Simplified
                HStack {
                    Text("Active Alarms:")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text("\(alarmKitService.alarms.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.bananaYellow)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.backgroundSecondary)
                .cornerRadius(8)
                
                // Test Controls
                VStack(spacing: 16) {
                    DatePicker("Test Alarm Time", selection: $testDate, displayedComponents: [.hourAndMinute])
                        .foregroundColor(.white)
                        .colorScheme(.dark)
                    
                    Button(action: scheduleTestAlarm) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            }
                            Text(isLoading ? "Scheduling..." : "Schedule Test Alarm")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.bananaYellow)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading || !alarmKitService.isAuthorized)
                    
                    Button(action: scheduleTestTimer) {
                        Text("Schedule 10s Timer")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.bananaYellow.opacity(0.8))
                            .cornerRadius(12)
                    }
                    .disabled(isLoading || !alarmKitService.isAuthorized)
                    
                    if !alarmKitService.alarms.isEmpty {
                        Button(action: cancelAllAlarms) {
                            Text("Cancel All Alarms")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
                
                // Status Messages
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundColor(.bananaYellow)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                
                // AI Wake-Up Test Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.bananaYellow)
                        Text("AI Wake-Up Test")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    // Music Selection
                    HStack {
                        Text("Music:")
                            .foregroundColor(.textSecondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Picker("Music", selection: $selectedMusic) {
                            ForEach(MusicOption.allCases, id: \.self) { option in
                                Text(option.displayName)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(.white)
                        .accentColor(.bananaYellow)
                    }
                    
                    // Voice Selection
                    HStack {
                        Text("Voice:")
                            .foregroundColor(.textSecondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Picker("Voice", selection: $selectedVoice) {
                            ForEach(AIVoiceOption.allCases, id: \.self) { option in
                                Text(option.displayName)
                                    .tag(option)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(.white)
                        .accentColor(.bananaYellow)
                    }
                    
                    // Alarm Sound Selection
                    HStack {
                        Text("Alarm:")
                            .foregroundColor(.textSecondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Picker("Alarm", selection: $selectedAlarmSound) {
                            ForEach(AlarmSound.allCases, id: \.self) { sound in
                                Text(sound.displayName)
                                    .tag(sound)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(.white)
                        .accentColor(.bananaYellow)
                    }
                    
                    // Volume Slider
                    HStack {
                        Text("Volume:")
                            .foregroundColor(.textSecondary)
                            .frame(width: 80, alignment: .leading)
                        
                        Slider(value: $testVolume, in: 0...1, step: 0.1)
                            .accentColor(.bananaYellow)
                        
                        Text("\(Int(testVolume * 100))%")
                            .foregroundColor(.white)
                            .frame(width: 50)
                    }
                    
                    // Phase Status
                    if isPlayingAIWakeUp {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Phase:")
                                    .foregroundColor(.textSecondary)
                                Text(currentPhase)
                                    .foregroundColor(.bananaYellow)
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Elapsed:")
                                    .foregroundColor(.textSecondary)
                                Text(formatElapsedTime(elapsedTime))
                                    .foregroundColor(.white)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Control Buttons
                    HStack(spacing: 16) {
                        Button(action: toggleAIWakeUpTest) {
                            HStack {
                                if isPlayingAIWakeUp {
                                    Image(systemName: "stop.fill")
                                    Text("Stop Test")
                                } else {
                                    Image(systemName: "play.fill")
                                    Text("Start AI Wake-Up")
                                }
                            }
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isPlayingAIWakeUp ? Color.red.opacity(0.8) : Color.bananaYellow)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading)
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .background(Color.backgroundPrimary)
            .navigationTitle("AlarmKit Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var authorizationColor: Color {
        switch alarmKitService.authorizationState {
        case .authorized: return .green
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
    
    private var authorizationText: String {
        switch alarmKitService.authorizationState {
        case .authorized: return "Authorized ✅"
        case .denied: return "Denied ❌"
        case .notDetermined: return "Not Determined ⚠️"
        @unknown default: return "Unknown"
        }
    }
    
    // MARK: - Actions
    
    private func scheduleTestAlarm() {
        Task {
            await MainActor.run {
                isLoading = true
                statusMessage = "Scheduling test alarm..."
            }
            
            do {
                let alarm = try await alarmKitService.scheduleRegularAlarm(
                    time: testDate,
                    title: "Test Alarm from Banana Clock"
                )
                
                await MainActor.run {
                    statusMessage = "✅ Scheduled alarm: \(alarm.id.uuidString.prefix(8))..."
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "❌ Failed to schedule alarm: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func scheduleTestTimer() {
        Task {
            await MainActor.run {
                isLoading = true
                statusMessage = "Scheduling 10 second timer..."
            }
            
            do {
                let alarm = try await alarmKitService.scheduleTimer(
                    duration: 10,
                    title: "Test Timer"
                )
                
                await MainActor.run {
                    statusMessage = "✅ Scheduled timer: \(alarm.id.uuidString.prefix(8))..."
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "❌ Failed to schedule timer: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func cancelAllAlarms() {
        Task {
            await MainActor.run {
                isLoading = true
                statusMessage = "Cancelling all alarms..."
            }
            
            for alarm in alarmKitService.alarms {
                do {
                    try alarmKitService.cancelAlarm(id: alarm.id)
                } catch {
                    print("Failed to cancel alarm \(alarm.id): \(error)")
                }
            }
            
            await MainActor.run {
                statusMessage = "✅ Cancelled all alarms"
                isLoading = false
            }
        }
    }
    
    // MARK: - AI Wake-Up Test Methods
    
    private func toggleAIWakeUpTest() {
        if isPlayingAIWakeUp {
            stopAIWakeUpTest()
        } else {
            startAIWakeUpTest()
        }
    }
    
    private func startAIWakeUpTest() {
        Task {
            await MainActor.run {
                isLoading = true
                statusMessage = "Starting AI Wake-Up test..."
                isPlayingAIWakeUp = true
                elapsedTime = 0
                currentPhase = "Initializing"
            }
            
            // Store alarm sound preference for the enhanced mixer
            UserDefaults.standard.set(selectedAlarmSound.fileName, forKey: "selectedAlarmSound")
            
            // Get URLs for music and voice
            guard let musicURL = selectedMusic.url else {
                await MainActor.run {
                    statusMessage = "❌ Failed to load music file"
                    isLoading = false
                    isPlayingAIWakeUp = false
                }
                return
            }
            
            // Use generic voice files for testing
            let voiceFileName = "ai_wakeup_generic_\(selectedVoice.rawValue.replacingOccurrences(of: "_", with: ""))"
            guard let voiceURL = Bundle.main.url(forResource: voiceFileName, withExtension: "aac") else {
                await MainActor.run {
                    statusMessage = "❌ Failed to load voice file"
                    isLoading = false
                    isPlayingAIWakeUp = false
                }
                return
            }
            
            do {
                // Start the AI wake-up sequence
                try await audioService.playAIWakeUpSequence(
                    musicURL: musicURL,
                    aiAudioURL: voiceURL,
                    volume: testVolume
                )
                
                await MainActor.run {
                    statusMessage = "✅ AI Wake-Up test started"
                    isLoading = false
                    startPhaseTracking()
                }
                
            } catch {
                await MainActor.run {
                    statusMessage = "❌ Failed to start AI Wake-Up: \(error.localizedDescription)"
                    isLoading = false
                    isPlayingAIWakeUp = false
                }
            }
        }
    }
    
    private func stopAIWakeUpTest() {
        Task {
            await audioService.stopAIWakeUp()
            
            await MainActor.run {
                isPlayingAIWakeUp = false
                currentPhase = "Idle"
                elapsedTime = 0
                statusMessage = "✅ AI Wake-Up test stopped"
                stopPhaseTracking()
            }
        }
    }
    
    private func startPhaseTracking() {
        // Start timer to update elapsed time and phase
        phaseTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.elapsedTime += 0.1
            
            // Update phase based on elapsed time
            if self.elapsedTime < 10 {
                self.currentPhase = "Music Fade-In (\(Int(self.elapsedTime * 10))%)"
            } else if self.elapsedTime < 15 {
                self.currentPhase = "Music Playing (60%)"
            } else if self.elapsedTime < 45 { // Assuming ~30s voice duration
                self.currentPhase = "Voice + Music"
            } else if self.elapsedTime < 65 { // 20s crescendo
                self.currentPhase = "Music Crescendo"
            } else {
                self.currentPhase = "Alarm Sound"
            }
        }
    }
    
    private func stopPhaseTracking() {
        phaseTimer?.invalidate()
        phaseTimer = nil
    }
    
    private func formatElapsedTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%d", minutes, seconds, tenths)
    }

}

// MARK: - Preview

#Preview {
    AlarmKitTestView()
        .environmentObject(AlarmKitService.shared)
}