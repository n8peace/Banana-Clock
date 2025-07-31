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
    @State private var openAIKey = ""
    @State private var showingKeyInput = false
    
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
                
                // Current Alarms
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Alarms")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if alarmKitService.alarms.isEmpty {
                        Text("No alarms scheduled")
                            .foregroundColor(.textSecondary)
                    } else {
                        ForEach(Array(alarmKitService.alarms.enumerated()), id: \.offset) { index, alarm in
                            HStack {
                                Text("Alarm: \(alarm.id.uuidString.prefix(8))...")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(alarm.state)")
                                    .foregroundColor(.bananaYellow)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
                
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
                
                // OpenAI Key Configuration
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("OpenAI API Key")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Check Status") {
                            SecureKeyManager.shared.checkAllKeyStatuses()
                        }
                        .font(.caption)
                        .foregroundColor(.bananaYellow)
                    }
                    
                    HStack {
                        Circle()
                            .fill(SecureKeyManager.shared.hasAPIKey(service: .openAI) ? .green : .red)
                            .frame(width: 12, height: 12)
                        Text(SecureKeyManager.shared.hasAPIKey(service: .openAI) ? "OpenAI Key Available ✅" : "OpenAI Key Missing ❌")
                            .foregroundColor(.white)
                            .font(.subheadline)
                    }
                    
                    if !SecureKeyManager.shared.hasAPIKey(service: .openAI) {
                        VStack(spacing: 8) {
                            HStack {
                                TextField("Enter OpenAI API Key (sk-...)", text: $openAIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                
                                Button("Store") {
                                    storeOpenAIKey()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.bananaYellow)
                                .foregroundColor(.black)
                                .cornerRadius(8)
                                .disabled(openAIKey.isEmpty || !openAIKey.hasPrefix("sk-"))
                            }
                            
                            Text("Get your API key from: platform.openai.com/api-keys")
                                .font(.caption)
                                .foregroundColor(.textSecondary)
                        }
                    } else {
                        Button("Remove OpenAI Key") {
                            try? SecureKeyManager.shared.removeAPIKey(service: .openAI)
                            statusMessage = "OpenAI key removed"
                        }
                        .font(.caption)
                        .foregroundColor(.red)
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
    
    private func storeOpenAIKey() {
        guard !openAIKey.isEmpty, openAIKey.hasPrefix("sk-") else {
            statusMessage = "❌ Invalid OpenAI key format. Key should start with 'sk-'"
            return
        }
        
        SecureKeyManager.shared.storeOpenAIKey(openAIKey)
        openAIKey = "" // Clear the input field
        statusMessage = "🎉 OpenAI API key stored successfully in keychain!"
        
        // Test the timezone converter immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            statusMessage += "\n🍌 AI timezone converter is now ready!"
        }
    }
}

// MARK: - Preview

#Preview {
    AlarmKitTestView()
        .environmentObject(AlarmKitService.shared)
}