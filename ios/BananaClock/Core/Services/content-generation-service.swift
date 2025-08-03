//
//  ContentGenerationService.swift
//  BananaClock
//
//  Mobile-initiated AI content generation for alarms
//  Handles scheduling, staggered calls, and background processing
//

import Foundation
import BackgroundTasks
import SwiftUI

@MainActor
class ContentGenerationService: ObservableObject {
    static let shared = ContentGenerationService()
    
    @Published var isGenerating = false
    @Published var lastGenerationError: Error?
    @Published var generationHistory: [GenerationRecord] = []
    
    private let backgroundTaskIdentifier = "bananaclock.content-generation"
    private var scheduledGenerations: [String: Date] = [:]
    
    private init() {
        setupBackgroundTaskHandling()
    }
    
    // MARK: - Background Task Setup
    
    private func setupBackgroundTaskHandling() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: backgroundTaskIdentifier,
            using: nil
        ) { task in
            Task {
                await self.handleBackgroundContentGeneration(task: task as! BGProcessingTask)
            }
        }
    }
    
    // MARK: - Content Generation Scheduling
    
    /// Schedule content generation for an alarm with staggered timing
    func scheduleContentGeneration(for alarmId: UUID, alarmTime: Date, userId: UUID) async {
        let generationTime = calculateStaggeredGenerationTime(
            alarmTime: alarmTime,
            userId: userId
        )
        
        print("🔄 Scheduling content generation for alarm \(alarmId)")
        print("  - Alarm time: \(alarmTime)")
        print("  - Generation time: \(generationTime)")
        
        // Store the scheduled generation
        scheduledGenerations[alarmId.uuidString] = generationTime
        
        // Schedule background task
        await scheduleBackgroundTask(for: generationTime, alarmId: alarmId, userId: userId)
        
        // Log the scheduling
        let record = GenerationRecord(
            alarmId: alarmId,
            scheduledTime: generationTime,
            status: .scheduled,
            userId: userId
        )
        generationHistory.append(record)
    }
    
    /// Calculate staggered generation time to prevent API overload
    private func calculateStaggeredGenerationTime(alarmTime: Date, userId: UUID) -> Date {
        // Base generation time: 1 hour before alarm
        let baseGenerationTime = alarmTime.addingTimeInterval(-3600) // -1 hour
        
        // Create staggered offset using user ID hash (0-30 minutes)
        let userIdString = userId.uuidString
        let hashValue = abs(userIdString.hashValue)
        let offsetMinutes = hashValue % 31 // 0-30 minutes
        let offsetSeconds = offsetMinutes * 60
        
        let staggeredTime = baseGenerationTime.addingTimeInterval(TimeInterval(offsetSeconds))
        
        print("🔄 Staggered generation calculation:")
        print("  - User ID: \(userId)")
        print("  - Hash value: \(hashValue)")
        print("  - Offset minutes: \(offsetMinutes)")
        print("  - Base time: \(baseGenerationTime)")
        print("  - Staggered time: \(staggeredTime)")
        
        return staggeredTime
    }
    
    // MARK: - Background Task Management
    
    private func scheduleBackgroundTask(for executionTime: Date, alarmId: UUID, userId: UUID) async {
        let request = BGProcessingTaskRequest(identifier: backgroundTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = executionTime
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background task scheduled for \(executionTime)")
        } catch {
            print("❌ Failed to schedule background task: \(error)")
            lastGenerationError = error
        }
    }
    
    private func handleBackgroundContentGeneration(task: BGProcessingTask) async {
        print("🔄 Background content generation task started")
        
        task.expirationHandler = {
            print("⚠️ Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        do {
            // Find which alarm this generation is for
            guard let activeAlarm = findActiveAlarmForGeneration() else {
                print("❌ No active alarm found for content generation")
                task.setTaskCompleted(success: false)
                return
            }
            
            // Generate content for the alarm
            await generateContentForAlarm(
                alarmId: activeAlarm.alarmId,
                userId: activeAlarm.userId
            )
            
            print("✅ Background content generation completed")
            task.setTaskCompleted(success: true)
            
        } catch {
            print("❌ Background content generation failed: \(error)")
            lastGenerationError = error
            task.setTaskCompleted(success: false)
        }
    }
    
    private func findActiveAlarmForGeneration() -> (alarmId: UUID, userId: UUID)? {
        // Find scheduled generation that should be happening now
        let now = Date()
        let tolerance: TimeInterval = 300 // 5 minutes tolerance
        
        for (alarmIdString, scheduledTime) in scheduledGenerations {
            let timeDiff = abs(now.timeIntervalSince(scheduledTime))
            if timeDiff <= tolerance {
                guard let alarmId = UUID(uuidString: alarmIdString) else { continue }
                
                // Get user ID from generation history
                if let record = generationHistory.first(where: { $0.alarmId == alarmId }) {
                    return (alarmId: alarmId, userId: record.userId)
                }
            }
        }
        
        return nil
    }
    
    // MARK: - Content Generation
    
    /// Generate content for a specific alarm
    func generateContentForAlarm(alarmId: UUID, userId: UUID) async {
        print("🔄 Starting content generation for alarm \(alarmId)")
        
        await MainActor.run {
            isGenerating = true
            lastGenerationError = nil
        }
        
        do {
            // Step 1: Get fresh weather data
            let weatherData = await fetchFreshWeatherData()
            
            // Step 2: Call Supabase function with weather data
            try await callGenerateBananaContent(
                userId: userId,
                weatherData: weatherData
            )
            
            // Step 3: Update generation record
            await updateGenerationRecord(
                alarmId: alarmId,
                status: .completed
            )
            
            print("✅ Content generation completed for alarm \(alarmId)")
            
        } catch {
            print("❌ Content generation failed for alarm \(alarmId): \(error)")
            
            await MainActor.run {
                lastGenerationError = error
            }
            
            await updateGenerationRecord(
                alarmId: alarmId,
                status: .failed,
                error: error
            )
        }
        
        await MainActor.run {
            isGenerating = false
        }
    }
    
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
        guard let session = try await SupabaseService.shared.getCurrentSession() else {
            throw MobileContentGenerationError.notAuthenticated
        }
        
        let url = URL(string: AppEnvironment.generateContentEndpoint)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        
        var requestBody: [String: Any] = [
            "user_id": userId.uuidString
        ]
        
        if let weatherData = weatherData {
            requestBody["weather_data"] = weatherData
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("🔄 Calling generate-banana-content API")
        print("  - User ID: \(userId)")
        print("  - Weather included: \(weatherData != nil)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MobileContentGenerationError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ API call failed with status \(httpResponse.statusCode): \(errorMessage)")
            throw MobileContentGenerationError.apiError(httpResponse.statusCode, errorMessage)
        }
        
        let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        print("✅ API call successful: \(responseData?["message"] ?? "No message")")
    }
    
    // MARK: - Generation Record Management
    
    private func updateGenerationRecord(
        alarmId: UUID,
        status: GenerationStatus,
        error: Error? = nil
    ) async {
        await MainActor.run {
            if let index = generationHistory.firstIndex(where: { $0.alarmId == alarmId }) {
                generationHistory[index].status = status
                generationHistory[index].completedAt = Date()
                generationHistory[index].error = error
            }
        }
        
        // Clean up scheduled generation
        scheduledGenerations.removeValue(forKey: alarmId.uuidString)
    }
    
    // MARK: - Public Interface
    
    /// Cancel scheduled content generation for an alarm
    func cancelContentGeneration(for alarmId: UUID) {
        print("🔄 Canceling content generation for alarm \(alarmId)")
        
        scheduledGenerations.removeValue(forKey: alarmId.uuidString)
        
        if let index = generationHistory.firstIndex(where: { $0.alarmId == alarmId && $0.status == .scheduled }) {
            generationHistory[index].status = .cancelled
            generationHistory[index].completedAt = Date()
        }
    }
    
    /// Get generation status for an alarm
    func getGenerationStatus(for alarmId: UUID) -> GenerationStatus? {
        return generationHistory.first(where: { $0.alarmId == alarmId })?.status
    }
    
    /// Clear old generation history (keep last 50 records)
    func cleanupGenerationHistory() {
        if generationHistory.count > 50 {
            generationHistory = Array(generationHistory.suffix(50))
        }
    }
}

// MARK: - Models

struct GenerationRecord: Identifiable {
    let id = UUID()
    let alarmId: UUID
    let scheduledTime: Date
    var status: GenerationStatus
    let userId: UUID
    var completedAt: Date?
    var error: Error?
}

enum GenerationStatus {
    case scheduled
    case inProgress
    case completed
    case failed
    case cancelled
}

enum MobileContentGenerationError: LocalizedError {
    case notAuthenticated
    case invalidResponse
    case apiError(Int, String)
    case weatherUnavailable
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let code, let message):
            return "API error \(code): \(message)"
        case .weatherUnavailable:
            return "Weather data unavailable"
        }
    }
}