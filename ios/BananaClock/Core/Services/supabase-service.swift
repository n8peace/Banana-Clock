//
//  SupabaseService.swift
//  BananaClock
//
//  Enhanced Supabase integration for iOS app
//

import Foundation
import Supabase
import SwiftUI

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private var client: SupabaseClient?
    @Published var isConfigured = false
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {}
    
    // MARK: - Configuration
    
    func configure() {
        guard !AppEnvironment.supabaseURL.isEmpty,
              !AppEnvironment.supabaseAnonKey.isEmpty else {
            print("⚠️ Supabase credentials not configured")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: URL(string: AppEnvironment.supabaseURL)!,
            supabaseKey: AppEnvironment.supabaseAnonKey
        )
        
        isConfigured = true
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        guard let user = response.user else {
            throw SupabaseError.authenticationFailed
        }
        
        currentUser = User(
            id: user.id,
            email: user.email ?? "",
            hasActiveSubscription: false,
            createdAt: user.createdAt ?? Date()
        )
        isAuthenticated = true
        
        return currentUser!
    }
    
    func signUp(email: String, password: String) async throws -> User {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        guard let user = response.user else {
            throw SupabaseError.registrationFailed
        }
        
        currentUser = User(
            id: user.id,
            email: user.email ?? "",
            hasActiveSubscription: false,
            createdAt: user.createdAt ?? Date()
        )
        isAuthenticated = true
        
        // Create initial user preferences
        try await createUserPreferences(userId: user.id)
        
        return currentUser!
    }
    
    func signOut() async throws {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        try await client.auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func checkAuthenticationStatus() {
        guard let client = client else { return }
        
        Task {
            do {
                let session = try await client.auth.session
                if let user = session.user {
                    currentUser = User(
                        id: user.id,
                        email: user.email ?? "",
                        hasActiveSubscription: false,
                        createdAt: user.createdAt ?? Date()
                    )
                    isAuthenticated = true
                }
            } catch {
                print("Authentication check failed: \(error)")
            }
        }
    }
    
    // MARK: - User Preferences Sync
    
    func syncUserPreferences() async throws -> UserPreferences? {
        guard let client = client,
              let currentUser = currentUser else {
            throw SupabaseError.notAuthenticated
        }
        
        let response: [UserPreferencesResponse] = try await client
            .from("user_preferences")
            .select()
            .eq("user_id", value: currentUser.id.uuidString)
            .single()
            .execute()
            .value
        
        guard let preferences = response.first else {
            return nil
        }
        
        return UserPreferences(
            id: preferences.id,
            timezone: preferences.timezone,
            locationZip: preferences.locationZip,
            name: preferences.name,
            city: preferences.city,
            state: preferences.state,
            voice: AIVoiceOption(rawValue: preferences.voice ?? "") ?? .voice1,
            weatherEnabled: preferences.weatherEnabled,
            headlinesCategories: preferences.headlinesCategories,
            sportsCategories: preferences.sportsCategories,
            lastSyncAt: preferences.lastSyncAt.flatMap { ISO8601DateFormatter().date(from: $0) }
        )
    }
    
    func updateUserPreferences(_ preferences: UserPreferences) async throws {
        guard let client = client,
              let currentUser = currentUser else {
            throw SupabaseError.notAuthenticated
        }
        
        let updateData: [String: Any] = [
            "timezone": preferences.timezone,
            "location_zip": preferences.locationZip ?? "",
            "name": preferences.name ?? "",
            "city": preferences.city ?? "",
            "state": preferences.state ?? "",
            "voice": preferences.voice.rawValue,
            "weather_enabled": preferences.weatherEnabled,
            "headlines_categories": preferences.headlinesCategories,
            "sports_categories": preferences.sportsCategories,
            "last_sync_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        try await client
            .from("user_preferences")
            .update(updateData)
            .eq("user_id", value: currentUser.id.uuidString)
            .execute()
    }
    
    private func createUserPreferences(userId: UUID) async throws {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        let preferences: [String: Any] = [
            "user_id": userId.uuidString,
            "timezone": TimeZone.current.identifier,
            "location_zip": "",
            "voice": AIVoiceOption.voice1.rawValue,
            "weather_enabled": false,
            "headlines_categories": ["business", "technology"],
            "sports_categories": ["football", "basketball"],
            "last_sync_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        try await client
            .from("user_preferences")
            .insert(preferences)
            .execute()
    }
    
    // MARK: - AI Content Generation
    
    // func triggerAIContentGeneration(for alarm: Alarm, date: Date = Date().addingTimeInterval(86400)) async throws {
    //     guard let client = client else { throw SupabaseError.notConfigured }
    //     guard alarm.isAIEnabled else { return }
    //     
    //     // Get user preferences from Core Data
    //     let preferences = try? CoreDataManager.shared.fetchUserPreferences()
    //     
    //     let requestBody: [String: Any] = [
    //         "alarm_id": alarm.id.uuidString,
    //         "date": ISO8601DateFormatter.string(from: date, timeZone: .current, formatOptions: [.withFullDate, .withDashSeparatorInDate]),
    //         "user_preferences": [
    //             "name": preferences?.name ?? "",
    //             "city": preferences?.city ?? "",
    //             "state": preferences?.state ?? "",
    //             "timezone": preferences?.timezone ?? TimeZone.current.identifier,
    //             "voice": preferences?.voice.rawValue ?? "voice_1",
    //             "content_preferences": [
    //                 "include_weather": preferences?.contentPreferences.includeWeather ?? true,
    //                 "include_headlines": preferences?.contentPreferences.includeHeadlines ?? true,
    //                 "include_markets": preferences?.contentPreferences.includeMarkets ?? false,
    //                 "include_sports": preferences?.contentPreferences.includeSports ?? false,
    //                 "sports_teams": preferences?.contentPreferences.sportsTeams ?? []
    //             ]
    //         ]
    //     ]
    //     
    //     let response = try await client.functions.invoke(
    //         "generate-banana-content",
    //         options: FunctionInvokeOptions(body: requestBody)
    //     )
    //     
    //     print("AI content generation triggered: \(response)")
    // }
    
    // MARK: - Fetch AI Content
    
    // func fetchAIContent(for alarmId: UUID, date: Date) async throws -> AIContent? {
    //     guard let client = client else { throw SupabaseError.notConfigured }
    //     
    //     let dateString = ISO8601DateFormatter.string(
    //         from: date,
    //         timeZone: .current,
    //         formatOptions: [.withFullDate, .withDashSeparatorInDate]
    //     )
    //     
    //     let response: [ContentBlock] = try await client
    //         .from("content_blocks")
    //         .select()
    //         .eq("alarm_id", value: alarmId.uuidString)
    //         .eq("date", value: dateString)
    //         .eq("content_type", value: "banana")
    //         .execute()
    //         .value
    //     
    //     guard let contentBlock = response.first,
    //           contentBlock.status == "ready",
    //           let audioUrl = contentBlock.audioUrl else {
    //         return nil
    //     }
    //     
    //     return AIContent(
    //         id: contentBlock.id,
    //         alarmId: alarmId,
    //         audioUrl: audioUrl,
    //         script: contentBlock.script ?? "",
    //         duration: contentBlock.durationSeconds ?? 0,
    //         generatedAt: Date()
    //     )
    // }
    
    // MARK: - Download Audio
    
    // func downloadAIAudio(from urlString: String) async throws -> URL {
    //     guard let url = URL(string: urlString) else {
    //         throw SupabaseError.invalidURL
    //     }
    //     
    //     let session = URLSession.shared
    //     let (data, response) = try await session.data(from: url)
    //     
    //     guard let httpResponse = response as? HTTPURLResponse,
    //           httpResponse.statusCode == 200 else {
    //         throw SupabaseError.downloadFailed
    //     }
    //     
    //     // Cache to local directory
    //     let documentsPath = FileManager.default.urls(
    //         for: .documentDirectory,
    //         in: .userDomainMask
    //     )[0]
    //     
    //     let fileName = url.lastPathComponent
    //     let localURL = documentsPath.appendingPathComponent("AIAudio").appendingPathComponent(fileName)
    //     
    //     // Create directory if needed
    //     try FileManager.default.createDirectory(
    //         at: localURL.deletingLastPathComponent(),
    //         withIntermediateDirectories: true
    //     )
    //     
    //     try data.write(to: localURL)
    //     return localURL
    // }
    
    // MARK: - AI Time Converter
    
    // func convertTimeWithAI(query: String) async throws -> AITimeResponse {
    //     guard let client = client else { throw SupabaseError.notConfigured }
    //     
    //     let requestBody: [String: Any] = [
    //         "query": query,
    //         "context": [
    //             "user_timezone": TimeZone.current.identifier,
    //             "current_time": ISO8601DateFormatter().string(from: Date())
    //         ]
    //     ]
    //     
    //     let response = try await client.functions.invoke(
    //         "ai-time-converter",
    //         options: FunctionInvokeOptions(body: requestBody)
    //     )
    //     
    //     // Parse response
    //     guard let data = response.data,
    //           let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
    //           let result = json["result"] as? [String: Any],
    //           let answer = result["answer"] as? String else {
    //         throw SupabaseError.invalidResponse
    //     }
    //     
    //     return AITimeResponse(answer: answer)
    // }
    
    // MARK: - AI Content Generation
    
    // func generateAIContent(for date: Date, voice: String) async throws {
    //     // TODO: Implement AI content generation
    // }
    // 
    // func triggerAIContentGeneration(for date: Date) async throws {
    //     guard let client = client,
    //           let userId = currentUser?.id else {
    //         throw SupabaseError.notAuthenticated
    //     }
    //     
    //     let response = try await client.functions.invoke(
    //         "generate-banana-content",
    //         options: FunctionInvokeOptions(
    //             body: [
    //                 "date": date.ISO8601Format(),
    //                 "user_id": userId.uuidString
    //             ]
    //         )
    //     )
    //     
    //     if response.error != nil {
    //         throw SupabaseError.functionError
    //     }
    // }
    
    // MARK: - Log Events
    
    // func logAlarmEvent(alarmId: UUID, event: AlarmEvent) async {
    //     guard let client = client else { return }
    //     
    //     do {
    //         try await client
    //         .from("alarm_events")
    //         .insert([
    //         "alarm_id": alarmId.uuidString,
    //         "event_type": event.rawValue,
    //         "timestamp": ISO8601DateFormatter().string(from: Date()),
    //         "metadata": [
    //         "device_model": UIDevice.current.model,
    //         "ios_version": UIDevice.current.systemVersion
    //         ]
    //         ])
    //         .execute()
    //     } catch {
    //         print("Failed to log alarm event: \(error)")
    //     }
    // }
}

// MARK: - Models
struct AIContent {
    let id: UUID
    let alarmId: UUID
    let audioUrl: String
    let script: String
    let duration: Int
    let generatedAt: Date
}

struct AITimeResponse {
    let answer: String
}

enum AlarmEvent: String {
    case scheduled = "scheduled"
    case fired = "fired"
    case dismissed = "dismissed"
    case snoozed = "snoozed"
    case aiPlaybackStarted = "ai_playback_started"
    case aiPlaybackCompleted = "ai_playback_completed"
    case aiPlaybackFailed = "ai_playback_failed"
}

struct ContentBlock: Codable {
    let id: UUID
    let userId: UUID?
    let contentType: String
    let date: String
    let content: String?
    let script: String?
    let audioUrl: String?
    let status: String
    let voice: String?
    let durationSeconds: Int?
    let audioDuration: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case contentType = "content_type"
        case date
        case content
        case script
        case audioUrl = "audio_url"
        case status
        case voice
        case durationSeconds = "duration_seconds"
        case audioDuration = "audio_duration"
    }
}

// MARK: - Supabase Response Models
struct UserPreferencesResponse: Codable {
    let id: UUID
    let userId: String
    let timezone: String
    let locationZip: String?
    let name: String?
    let city: String?
    let state: String?
    let voice: String?
    let weatherEnabled: Bool
    let headlinesCategories: [String]
    let sportsCategories: [String]
    let lastSyncAt: String?
    let createdAt: String
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case timezone
        case locationZip = "location_zip"
        case name
        case city
        case state
        case voice
        case weatherEnabled = "weather_enabled"
        case headlinesCategories = "headlines_categories"
        case sportsCategories = "sports_categories"
        case lastSyncAt = "last_sync_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct LogEvent: Codable {
    let eventType: String
    let status: String
    let message: String?
    let metadata: [String: String]?
    
    private enum CodingKeys: String, CodingKey {
        case eventType = "event_type"
        case status
        case message
        case metadata
    }
}

// MARK: - Error Types
// Note: SupabaseError is defined in Core/Utilities/error-types.swift