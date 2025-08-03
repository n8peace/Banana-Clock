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
    
    // Content Generation Test States
    @State private var isTestingContentGeneration = false
    @State private var contentGenerationStatus = ""
    @State private var contentGenerationLogs: [String] = []

    
    var body: some View {
        NavigationView {
            ScrollView {
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
                
                // Content Generation Test Section
                contentGenerationTestSection
                
                Spacer()
                }
                .padding()
            }
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
    
    // MARK: - Content Generation Test Section
    
    private var contentGenerationTestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.bananaYellow)
                Text("Content Generation Test")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Status
            if !contentGenerationStatus.isEmpty {
                HStack {
                    Circle()
                        .fill(isTestingContentGeneration ? .orange : .green)
                        .frame(width: 8, height: 8)
                    Text(contentGenerationStatus)
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            
            // Test Buttons
            VStack(spacing: 12) {
                Button(action: testContentGeneration) {
                    HStack {
                        if isTestingContentGeneration {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        }
                        Image(systemName: "play.circle")
                        Text(isTestingContentGeneration ? "Testing..." : "Test Full Flow")
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.bananaYellow)
                    .cornerRadius(10)
                }
                .disabled(isTestingContentGeneration)
                
                HStack(spacing: 12) {
                    Button(action: testWeatherFetch) {
                        HStack {
                            Image(systemName: "cloud.sun")
                            Text("Test Weather")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.bananaYellow.opacity(0.8))
                        .cornerRadius(8)
                    }
                    .disabled(isTestingContentGeneration)
                    
                    Button(action: testSupabaseCall) {
                        HStack {
                            Image(systemName: "server.rack")
                            Text("Test API")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.bananaYellow.opacity(0.8))
                        .cornerRadius(8)
                    }
                    .disabled(isTestingContentGeneration)
                    
                    Button(action: clearLogs) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear")
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(8)
                    }
                }
            }
            
            // Logs Display
            if !contentGenerationLogs.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(contentGenerationLogs.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(logColor(for: log))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 150)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
    
    private func logColor(for log: String) -> Color {
        if log.contains("✅") {
            return .green
        } else if log.contains("❌") {
            return .red
        } else if log.contains("⚠️") {
            return .orange
        } else if log.contains("🔄") {
            return .blue
        } else {
            return .white
        }
    }
    
    // MARK: - Content Generation Test Methods
    
    private func addLog(_ message: String) {
        let timestamp = DateFormatter.timeFormatter.string(from: Date())
        let logEntry = "[\(timestamp)] \(message)"
        contentGenerationLogs.append(logEntry)
        
        // Keep only last 20 logs
        if contentGenerationLogs.count > 20 {
            contentGenerationLogs.removeFirst()
        }
    }
    
    private func testContentGeneration() {
        Task {
            await MainActor.run {
                isTestingContentGeneration = true
                contentGenerationStatus = "Running full content generation test..."
                contentGenerationLogs.removeAll()
                addLog("🔄 Starting end-to-end content generation test")
            }
            
            do {
                // Step 1: Check authentication
                guard let session = try await SupabaseService.shared.getCurrentSession() else {
                    await MainActor.run {
                        addLog("❌ No user session - authentication required")
                        contentGenerationStatus = "Authentication failed"
                        isTestingContentGeneration = false
                    }
                    return
                }
                
                await MainActor.run {
                    addLog("✅ User authenticated: \(session.user.email ?? "Unknown")")
                }
                
                // Step 2: Test weather fetching
                await MainActor.run {
                    addLog("🔄 Fetching fresh weather data...")
                }
                
                let weatherData = await fetchFreshWeatherData()
                
                await MainActor.run {
                    if let weather = weatherData {
                        addLog("✅ Weather data obtained: \(weather["condition"] ?? "Unknown")")
                        addLog("   Temperature: \(weather["temperature"] ?? "N/A")°F")
                        addLog("   Description: \(weather["description"] ?? "N/A")")
                    } else {
                        addLog("⚠️ No weather data available (this is normal if location not granted)")
                    }
                }
                
                // Step 3: Test content generation API call
                await MainActor.run {
                    addLog("🔄 Calling generate-banana-content API...")
                }
                
                try await callGenerateBananaContent(
                    userId: session.user.id,
                    weatherData: weatherData
                )
                
                await MainActor.run {
                    addLog("✅ API call successful - content generation completed")
                }
                
                // Step 4: Check for generated content
                await MainActor.run {
                    addLog("🔄 Checking for generated content in cache...")
                }
                
                let contentStatus = ContentCacheManager.shared.getLatestContentStatus(for: session.user.id)
                
                await MainActor.run {
                    addLog("📊 Content status - Today: \(contentStatus.hasToday), Tomorrow: \(contentStatus.hasTomorrow)")
                    addLog("📦 Cache contains \(ContentCacheManager.shared.contentReadyCount) ready content blocks")
                    
                    contentGenerationStatus = "✅ Full test completed successfully"
                    isTestingContentGeneration = false
                    addLog("🎉 End-to-end test completed successfully!")
                }
                
            } catch {
                await MainActor.run {
                    addLog("❌ Test failed: \(error.localizedDescription)")
                    contentGenerationStatus = "Test failed: \(error.localizedDescription)"
                    isTestingContentGeneration = false
                }
            }
        }
    }
    
    private func testWeatherFetch() {
        Task {
            await MainActor.run {
                addLog("🔄 Testing weather fetch only...")
            }
            
            let weatherData = await fetchFreshWeatherData()
            
            await MainActor.run {
                if let weather = weatherData {
                    addLog("✅ Weather fetch successful:")
                    addLog("   Condition: \(weather["condition"] ?? "Unknown")")
                    addLog("   Temperature: \(weather["temperature"] ?? "N/A")°F")
                    addLog("   Humidity: \(weather["humidity"] ?? "N/A")%")
                    addLog("   Wind Speed: \(weather["wind_speed"] ?? "N/A") mph")
                } else {
                    addLog("⚠️ Weather fetch returned no data")
                    addLog("   Check location permissions in Settings")
                }
            }
        }
    }
    
    private func testSupabaseCall() {
        Task {
            await MainActor.run {
                addLog("🔄 Testing Supabase API call only...")
            }
            
            do {
                guard let session = try await SupabaseService.shared.getCurrentSession() else {
                    await MainActor.run {
                        addLog("❌ No user session for API test")
                    }
                    return
                }
                
                await MainActor.run {
                    addLog("✅ Session valid, calling API...")
                }
                
                try await callGenerateBananaContent(
                    userId: session.user.id,
                    weatherData: nil
                )
                
                await MainActor.run {
                    addLog("✅ Supabase API call successful")
                    addLog("   Content generation triggered without weather")
                }
                
            } catch {
                await MainActor.run {
                    addLog("❌ Supabase API call failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func clearLogs() {
        contentGenerationLogs.removeAll()
        contentGenerationStatus = ""
    }
    
    // MARK: - Helper Methods for Content Generation
    
    private func fetchFreshWeatherData() async -> [String: Any]? {
        let authStatus = await WeatherService.shared.authorizationStatus
        guard authStatus == .authorizedWhenInUse || authStatus == .authorizedAlways else {
            print("⚠️ Weather permission not granted, generating content without weather")
            return nil
        }
        
        do {
            // Request fresh location detection
            await WeatherService.shared.requestLocationAndDetect()
            
            // Wait for location detection to complete
            var attempts = 0
            var isRequestingLocation = await WeatherService.shared.isRequestingLocation
            while isRequestingLocation && attempts < 10 {
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                attempts += 1
                isRequestingLocation = await WeatherService.shared.isRequestingLocation
            }
            
            guard let location = await WeatherService.shared.currentLocation else {
                print("⚠️ No location available, generating content without weather")
                return nil
            }
            
            // Get weather data
            let weather: WeatherKitData = try await WeatherService.shared.getCurrentWeather(for: location)
            
            // Format for Supabase Edge Function
            let weatherData: [String: Any] = [
                "temperature": weather.temperature,
                "condition": weather.condition,
                "humidity": weather.humidity,
                "wind_speed": weather.windSpeed,
                "description": weather.description,
                "timestamp": Date().timeIntervalSince1970
            ]
            
            print("✅ Fresh weather data obtained: \(weather.condition), \(weather.temperature)°F")
            return weatherData
            
        } catch {
            print("❌ Failed to fetch weather data: \(error)")
            return nil
        }
    }
    
    private func callGenerateBananaContent(userId: UUID, weatherData: [String: Any]?) async throws {
        _ = try await SupabaseService.shared.triggerContentGeneration(
            userId: userId,
            weatherData: weatherData
        )
    }

}

// MARK: - DateFormatter Extension

extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

// MARK: - Preview

#Preview {
    AlarmKitTestView()
        .environmentObject(AlarmKitService.shared)
}