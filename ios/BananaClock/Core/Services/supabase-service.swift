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
        print("🔧 Configuring Supabase...")
        print("🌐 URL: \(AppEnvironment.supabaseURL)")
        print("🔑 Key length: \(AppEnvironment.supabaseAnonKey.count)")
        print("🔑 Key starts with: \(String(AppEnvironment.supabaseAnonKey.prefix(20)))...")
        
        guard !AppEnvironment.supabaseURL.isEmpty,
              !AppEnvironment.supabaseAnonKey.isEmpty else {
            print("⚠️ Supabase credentials not configured")
            print("❌ URL empty: \(AppEnvironment.supabaseURL.isEmpty)")
            print("❌ Key empty: \(AppEnvironment.supabaseAnonKey.isEmpty)")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: URL(string: AppEnvironment.supabaseURL)!,
            supabaseKey: AppEnvironment.supabaseAnonKey
        )
        
        isConfigured = true
        print("✅ Supabase configured successfully")
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws -> User {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        let user = response.user
        
        currentUser = User(
            id: user.id,
            email: user.email ?? "",
            hasActiveSubscription: false,
            createdAt: user.createdAt
        )
        isAuthenticated = true
        
        return currentUser!
    }
    
    func signUp(email: String, password: String) async throws -> User {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        // Step 1: Sign up the user
        let signUpResponse = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        let user = signUpResponse.user
        
        // Step 2: Sign in immediately to establish auth session
        let signInResponse = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        // Step 3: Update current user with session data
        currentUser = User(
            id: user.id,
            email: user.email ?? "",
            hasActiveSubscription: false,
            createdAt: user.createdAt
        )
        isAuthenticated = true
        
        // Step 4: Create initial user preferences (now with proper auth session)
        try await createUserPreferencesWithRetry(userId: user.id)
        
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
                let user = session.user
                currentUser = User(
                    id: user.id,
                    email: user.email ?? "",
                    hasActiveSubscription: false,
                    createdAt: user.createdAt
                )
                isAuthenticated = true
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
        
        let updateData = UpdateUserPreferencesRequest(
            timezone: preferences.timezone,
            locationZip: preferences.locationZip ?? "",
            name: preferences.name ?? "",
            city: preferences.city ?? "",
            state: preferences.state ?? "",
            voice: preferences.voice.rawValue,
            weatherEnabled: preferences.weatherEnabled,
            headlinesCategories: preferences.headlinesCategories,
            sportsCategories: preferences.sportsCategories,
            lastSyncAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("user_preferences")
            .update(updateData)
            .eq("user_id", value: currentUser.id.uuidString)
            .execute()
    }
    
    private func createUserPreferences(userId: UUID) async throws {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        let preferences = CreateUserPreferencesRequest(
            userId: userId.uuidString,
            timezone: TimeZone.current.identifier,
            locationZip: "",
            voice: AIVoiceOption.voice1.rawValue,
            weatherEnabled: false,
            headlinesCategories: ["business", "technology"],
            sportsCategories: ["football", "basketball"],
            lastSyncAt: ISO8601DateFormatter().string(from: Date())
        )
        
        // Use service role to bypass RLS for initial user setup
        // This avoids the auth.uid() timing issue
        let serviceClient = SupabaseClient(
            supabaseURL: URL(string: AppEnvironment.supabaseURL)!,
            supabaseKey: AppEnvironment.supabaseServiceKey
        )
        
        try await serviceClient
            .from("user_preferences")
            .insert(preferences)
            .execute()
    }
    
    private func createUserPreferencesWithRetry(userId: UUID) async throws {
        let maxRetries = 2
        let baseDelay: TimeInterval = 0.2
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 Creating user preferences (attempt \(attempt)/\(maxRetries))")
                try await createUserPreferences(userId: userId)
                print("✅ User preferences created successfully")
                return
            } catch {
                print("❌ Failed to create user preferences (attempt \(attempt)/\(maxRetries)): \(error)")
                
                if attempt == maxRetries {
                    print("⚠️ User preferences creation failed, but signup completed successfully")
                    // Don't throw error - let signup complete even if preferences fail
                    return
                }
                
                // Short delay before retry
                let delay = baseDelay * Double(attempt)
                print("⏳ Waiting \(delay) seconds before retry...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
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

// MARK: - Request Models
struct CreateUserPreferencesRequest: Codable {
    let userId: String
    let timezone: String
    let locationZip: String
    let voice: String
    let weatherEnabled: Bool
    let headlinesCategories: [String]
    let sportsCategories: [String]
    let lastSyncAt: String
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case timezone
        case locationZip = "location_zip"
        case voice
        case weatherEnabled = "weather_enabled"
        case headlinesCategories = "headlines_categories"
        case sportsCategories = "sports_categories"
        case lastSyncAt = "last_sync_at"
    }
}

struct UpdateUserPreferencesRequest: Codable {
    let timezone: String
    let locationZip: String
    let name: String
    let city: String
    let state: String
    let voice: String
    let weatherEnabled: Bool
    let headlinesCategories: [String]
    let sportsCategories: [String]
    let lastSyncAt: String
    
    private enum CodingKeys: String, CodingKey {
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
    }
}

// MARK: - Error Types
// Note: SupabaseError is defined in Core/Utilities/error-types.swift



