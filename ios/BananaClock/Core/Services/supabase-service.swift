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
        
        // Enhanced debugging for keychain status
        print("🔍 Checking SecureKeyManager status...")
        SecureKeyManager.shared.checkAllKeyStatuses()
        
        guard !AppEnvironment.supabaseURL.isEmpty,
              !AppEnvironment.supabaseAnonKey.isEmpty else {
            print("⚠️ Supabase credentials not configured")
            print("❌ URL empty: \(AppEnvironment.supabaseURL.isEmpty)")
            print("❌ Key empty: \(AppEnvironment.supabaseAnonKey.isEmpty)")
            
            // Show setup instructions
            print("\n💡 To fix this issue:")
            print("1. Get your Supabase anon key from https://supabase.com/dashboard/project/\(AppEnvironment.supabaseProjectRef)/settings/api")
            print("2. In Xcode debug console, run:")
            print("   try! SecureKeyManager.shared.storeAPIKey(\"your_actual_supabase_anon_key\", service: .supabaseAnon)")
            print("3. Restart the app")
            
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
        let _ = try await client.auth.signIn(
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
    
    // MARK: - Debug Environment Support
    
    #if DEBUG
    func clearDebugSession() async {
        print("🧪 Clearing debug authentication session...")
        
        // Clear Supabase session
        do {
            try await signOut()
            print("✅ Supabase session cleared")
        } catch {
            print("⚠️ Error clearing Supabase session: \(error.localizedDescription)")
            // Force clear local state even if server signout fails
            currentUser = nil
            isAuthenticated = false
        }
        
        // Clear UserDefaults auth-related data
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "user_session")
        userDefaults.removeObject(forKey: "last_auth_check")
        userDefaults.removeObject(forKey: "cached_user_id")
        userDefaults.removeObject(forKey: AppEnvironment.StorageKey.hasCompletedOnboarding)
        
        print("✅ Debug authentication state cleared")
    }
    #endif
    
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
    
    // MARK: - Public Session Access
    
    func getCurrentSession() async throws -> Supabase.Session? {
        guard let client = client else { throw SupabaseError.notConfigured }
        return try await client.auth.session
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
            print("❌ updateUserPreferences: Not authenticated")
            throw SupabaseError.notAuthenticated
        }
        
        print("🔍 updateUserPreferences: Starting update for user \(currentUser.id.uuidString)")
        print("🔍 updateUserPreferences: User email: \(currentUser.email)")
        
        let updateData = UpdateUserPreferencesRequest(
            timezone: preferences.timezone,
            locationZip: preferences.locationZip?.isEmpty == false ? preferences.locationZip! : "00000", // Use user's zip or default
            name: preferences.name, // Allow nil to pass through
            city: preferences.city, // Allow nil to pass through
            state: preferences.state, // Allow nil to pass through
            voice: preferences.voice.rawValue,
            weatherEnabled: preferences.weatherEnabled,
            locationEnabled: preferences.locationEnabled,
            headlinesCategories: preferences.headlinesCategories,
            sportsCategories: preferences.sportsCategories,
            lastSyncAt: ISO8601DateFormatter().string(from: Date())
        )
        
        print("🔍 updateUserPreferences: Update data:")
        print("  - timezone: \(updateData.timezone)")
        print("  - locationZip: '\(updateData.locationZip)' (length: \(updateData.locationZip.count))")
        print("  - name: \(updateData.name ?? "nil")")
        print("  - city: \(updateData.city ?? "nil")")
        print("  - state: \(updateData.state ?? "nil")")
        print("  - voice: \(updateData.voice)")
        print("  - weatherEnabled: \(updateData.weatherEnabled)")
        print("  - locationEnabled: \(updateData.locationEnabled)")
        print("  - headlinesCategories: \(updateData.headlinesCategories)")
        print("  - sportsCategories: \(updateData.sportsCategories)")
        print("  - lastSyncAt: \(updateData.lastSyncAt)")
        
        do {
            let response = try await client
                .from("user_preferences")
                .update(updateData)
                .eq("user_id", value: currentUser.id.uuidString)
                .execute()
            
            print("🔍 updateUserPreferences: Supabase response received")
            print("🔍 updateUserPreferences: Response status: \(response.status)")
            print("🔍 updateUserPreferences: Response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            // Check if any rows were actually updated
            if let responseString = String(data: response.data, encoding: .utf8) {
                if responseString.isEmpty || responseString == "[]" {
                    print("⚠️ updateUserPreferences: WARNING - No rows updated! User may not exist in database.")
                    print("⚠️ updateUserPreferences: Attempting to create initial preferences...")
                    
                    // Create initial user preferences since they don't exist
                    try await createUserPreferences(userId: currentUser.id)
                    print("✅ updateUserPreferences: Created initial preferences, now retrying update...")
                    
                    // Retry the update now that preferences exist
                    let retryResponse = try await client
                        .from("user_preferences")
                        .update(updateData)
                        .eq("user_id", value: currentUser.id.uuidString)
                        .execute()
                    
                    print("🔍 updateUserPreferences: Retry response: \(String(data: retryResponse.data, encoding: .utf8) ?? "nil")")
                    
                    if let retryString = String(data: retryResponse.data, encoding: .utf8), 
                       (retryString.isEmpty || retryString == "[]") {
                        print("❌ updateUserPreferences: Retry also failed - this shouldn't happen")
                        throw SupabaseError.invalidResponse
                    }
                }
            }
            
            print("✅ updateUserPreferences: Update completed successfully")
        } catch {
            print("❌ updateUserPreferences: Update failed with error: \(error)")
            if let error = error as? SupabaseError {
                print("❌ updateUserPreferences: SupabaseError details: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    private func createUserPreferences(userId: UUID) async throws {
        guard client != nil else { throw SupabaseError.notConfigured }
        
        print("🔍 createUserPreferences: Creating initial preferences for user \(userId.uuidString)")
        
        let preferences = CreateUserPreferencesRequest(
            userId: userId.uuidString,
            timezone: TimeZone.current.identifier,
            locationZip: "90210",  // Default zip code to satisfy NOT NULL constraint
            name: nil,  // NULL instead of empty string to satisfy constraint
            city: nil,  // NULL instead of empty string to satisfy constraint
            state: nil, // NULL instead of empty string to satisfy constraint
            voice: AIVoiceOption.voice1.rawValue,
            weatherEnabled: false,
            locationEnabled: false,
            headlinesCategories: ["business", "technology"],
            sportsCategories: ["football", "basketball"],
            lastSyncAt: ISO8601DateFormatter().string(from: Date())
        )
        
        print("🔍 createUserPreferences: Initial preferences data:")
        print("  - userId: \(preferences.userId)")
        print("  - timezone: \(preferences.timezone)")
        print("  - locationZip: \(preferences.locationZip)")
        print("  - name: \(preferences.name ?? "nil")")
        print("  - city: \(preferences.city ?? "nil")")
        print("  - state: \(preferences.state ?? "nil")")
        print("  - voice: \(preferences.voice)")
        
        // Use service role to bypass RLS for initial user setup
        // This avoids the auth.uid() timing issue
        print("🔍 createUserPreferences: Using service role for initial creation")
        let serviceClient = SupabaseClient(
            supabaseURL: URL(string: AppEnvironment.supabaseURL)!,
            supabaseKey: AppEnvironment.supabaseServiceKey
        )
        
        do {
            let response = try await serviceClient
                .from("user_preferences")
                .insert(preferences)
                .execute()
            
            print("🔍 createUserPreferences: Insert response status: \(response.status)")
            print("🔍 createUserPreferences: Insert response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            print("✅ createUserPreferences: Initial preferences created successfully")
        } catch {
            print("❌ createUserPreferences: Failed to create initial preferences: \(error)")
            throw error
        }
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
    
    // MARK: - AI Content Generation (Mobile-Initiated)
    
    /// Trigger mobile-initiated content generation with weather data
    func triggerContentGeneration(userId: UUID, weatherData: [String: Any]?) async throws -> ContentGenerationResponse {
        guard let client = client else { throw SupabaseError.notConfigured }
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }
        
        print("🔄 Triggering mobile-initiated content generation")
        print("  - User ID: \(userId)")
        print("  - Weather data included: \(weatherData != nil)")
        
        // Create encodable request
        let requestBody = ContentGenerationRequest(
            userId: userId.uuidString,
            weatherData: weatherData
        )
        
        let result: ContentGenerationResponse = try await client.functions.invoke(
            "generate-banana-content",
            options: FunctionInvokeOptions(body: requestBody)
        )
        
        print("✅ Content generation response received")
        print("  - Success: \(result.success)")
        print("  - Message: \(result.message ?? "No message")")
        
        return result
    }
    
    /// Fetch content block by ID
    func fetchContentBlock(id: UUID) async throws -> AIContentBlock? {
        guard let client = client else { throw SupabaseError.notConfigured }
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }
        
        let response: [AIContentBlockResponse] = try await client
            .from("content_blocks")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        guard let contentResponse = response.first else {
            return nil
        }
        
        return try convertToAIContentBlock(contentResponse)
    }
    
    /// Fetch content blocks for a user and date
    func fetchContentBlocks(userId: UUID, date: Date, contentType: String = "banana") async throws -> [AIContentBlock] {
        guard let client = client else { throw SupabaseError.notConfigured }
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        let dateString = dateFormatter.string(from: date)
        
        print("🔍 Fetching content blocks for user \(userId), date \(dateString)")
        
        let response: [AIContentBlockResponse] = try await client
            .from("content_blocks")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: dateString)
            .eq("content_type", value: contentType)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ Found \(response.count) content blocks")
        
        return try response.compactMap { try convertToAIContentBlock($0) }
    }
    
    /// Update shared weather cache
    func updateWeatherCache(zipCode: String, weatherData: [String: Any], userId: UUID) async throws {
        guard let client = client else { throw SupabaseError.notConfigured }
        guard isAuthenticated else { throw SupabaseError.notAuthenticated }
        
        print("🔄 Updating shared weather cache for zip \(zipCode)")
        
        // Convert weather data to JSON string for RPC call
        let weatherJSON = try JSONSerialization.data(withJSONObject: weatherData)
        let weatherString = String(data: weatherJSON, encoding: .utf8) ?? "{}"
        
        _ = try await client.rpc(
            "upsert_weather_data",
            params: [
                "p_zip": zipCode,
                "p_weather": weatherString,
                "p_user_id": userId.uuidString
            ]
        ).execute()
        
        print("✅ Weather cache updated successfully")
    }
    
    /// Get weather from shared cache
    func getWeatherFromCache(zipCode: String) async throws -> [String: Any]? {
        guard let client = client else { throw SupabaseError.notConfigured }
        
        let response: [WeatherCacheResponse] = try await client
            .from("user_weather_data")
            .select("weather_data, updated_at")
            .eq("location_zip", value: zipCode)
            .single()
            .execute()
            .value
        
        guard let weatherResponse = response.first else {
            print("⚠️ No cached weather found for zip \(zipCode)")
            return nil
        }
        
        // Check if data is fresh (within 5 minutes)
        let updatedAt = ISO8601DateFormatter().date(from: weatherResponse.updatedAt) ?? Date.distantPast
        let cacheAge = Date().timeIntervalSince(updatedAt)
        
        if cacheAge > 300 { // 5 minutes
            print("⚠️ Cached weather data is stale (\(Int(cacheAge/60)) minutes old)")
            return nil
        }
        
        print("✅ Using fresh cached weather data")
        return weatherResponse.weatherData
    }
    
    // Helper method to convert response to model
    private func convertToAIContentBlock(_ response: AIContentBlockResponse) throws -> AIContentBlock {
        return AIContentBlock(
            id: response.id,
            userId: UUID(uuidString: response.userId) ?? UUID(),
            contentType: response.contentType,
            date: response.date,
            script: response.script,
            audioUrl: response.audioUrl,
            status: response.status,
            voice: response.voice ?? "voice_1",
            expirationDate: response.expirationDate ?? "",
            languageCode: response.language,
            contentPriority: response.contentPriority,
            createdAt: response.createdAt ?? "",
            updatedAt: response.updatedAt,
            scriptGeneratedAt: response.scriptGeneratedAt,
            audioGeneratedAt: response.audioGeneratedAt,
            parameters: nil, // TODO: Convert [String: Any] to ContentParameters
            content: response.content,
            metadata: nil // TODO: Add metadata conversion if needed
        )
    }
    
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
    let name: String?
    let city: String?
    let state: String?
    let voice: String
    let weatherEnabled: Bool
    let locationEnabled: Bool
    let headlinesCategories: [String]
    let sportsCategories: [String]
    let lastSyncAt: String
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case timezone
        case locationZip = "location_zip"
        case name
        case city
        case state
        case voice
        case weatherEnabled = "weather_enabled"
        case locationEnabled = "location_enabled"
        case headlinesCategories = "headlines_categories"
        case sportsCategories = "sports_categories"
        case lastSyncAt = "last_sync_at"
    }
}

struct UpdateUserPreferencesRequest: Codable {
    let timezone: String
    let locationZip: String
    let name: String?
    let city: String?
    let state: String?
    let voice: String
    let weatherEnabled: Bool
    let locationEnabled: Bool
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
        case locationEnabled = "location_enabled"
        case headlinesCategories = "headlines_categories"
        case sportsCategories = "sports_categories"
        case lastSyncAt = "last_sync_at"
    }
}

// MARK: - Content Generation Models

struct ContentGenerationRequest: Encodable {
    let userId: String
    let weatherData: [String: Any]?
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case weatherData = "weather_data"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userId, forKey: .userId)
        
        // Handle weatherData as raw JSON
        if let weatherData = weatherData {
            // Convert to JSON data and then encode as raw value
            let jsonData = try JSONSerialization.data(withJSONObject: weatherData)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? "{}"
            try container.encode(jsonString, forKey: .weatherData)
        }
    }
}

struct ContentGenerationResponse: Codable {
    let success: Bool
    let message: String?
    let userId: String?
    let weatherProvided: Bool?
    
    private enum CodingKeys: String, CodingKey {
        case success
        case message
        case userId = "user_id"
        case weatherProvided = "weather_provided"
    }
}

struct AIContentBlockResponse: Decodable {
    let id: UUID
    let userId: String
    let contentType: String
    let date: String
    let script: String?
    let scriptGeneratedAt: String?
    let audioUrl: String?
    let audioGeneratedAt: String?
    let status: String
    let voice: String?
    let language: String?
    let contentPriority: Int?
    let expirationDate: String?
    let createdAt: String?
    let updatedAt: String?
    let parameters: [String: Any]?
    let content: String?
    let durationSeconds: Int?
    let audioDuration: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case contentType = "content_type"
        case date
        case script
        case scriptGeneratedAt = "script_generated_at"
        case audioUrl = "audio_url"
        case audioGeneratedAt = "audio_generated_at"
        case status
        case voice
        case language = "language_code"
        case contentPriority = "content_priority"
        case expirationDate = "expiration_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parameters
        case content
        case durationSeconds = "duration_seconds"
        case audioDuration = "audio_duration"
    }
    
    // Custom decoder for parameters field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        contentType = try container.decode(String.self, forKey: .contentType)
        date = try container.decode(String.self, forKey: .date)
        script = try container.decodeIfPresent(String.self, forKey: .script)
        scriptGeneratedAt = try container.decodeIfPresent(String.self, forKey: .scriptGeneratedAt)
        audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)
        audioGeneratedAt = try container.decodeIfPresent(String.self, forKey: .audioGeneratedAt)
        status = try container.decode(String.self, forKey: .status)
        voice = try container.decodeIfPresent(String.self, forKey: .voice)
        language = try container.decodeIfPresent(String.self, forKey: .language)
        contentPriority = try container.decodeIfPresent(Int.self, forKey: .contentPriority)
        expirationDate = try container.decodeIfPresent(String.self, forKey: .expirationDate)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        durationSeconds = try container.decodeIfPresent(Int.self, forKey: .durationSeconds)
        audioDuration = try container.decodeIfPresent(Int.self, forKey: .audioDuration)
        
        // Handle parameters as generic dictionary from JSONB
        if container.contains(.parameters) {
            // Try to decode as a nested container first (if it's a JSON object)
            if let nestedContainer = try? container.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .parameters) {
                parameters = try nestedContainer.decode([String: Any].self)
            } else {
                // Fallback to nil if parameters field is not present or is null
                parameters = nil
            }
        } else {
            parameters = nil
        }
    }
}

// Helper for decoding [String: Any]
private struct GenericCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = String(intValue)
    }
}

extension KeyedDecodingContainer where Key == GenericCodingKeys {
    func decode(_ type: [String: Any].Type) throws -> [String: Any] {
        var dictionary: [String: Any] = [:]
        
        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else {
                // Handle nested objects by attempting to decode them recursively
                if let nestedContainer = try? nestedContainer(keyedBy: GenericCodingKeys.self, forKey: key) {
                    dictionary[key.stringValue] = try nestedContainer.decode([String: Any].self)
                } else if let nestedArray = try? decode([Any].self, forKey: key) {
                    dictionary[key.stringValue] = nestedArray
                }
            }
        }
        
        return dictionary
    }
    
    func decode(_ type: [Any].Type, forKey key: Key) throws -> [Any] {
        var container = try nestedUnkeyedContainer(forKey: key)
        var array: [Any] = []
        
        while !container.isAtEnd {
            if let boolValue = try? container.decode(Bool.self) {
                array.append(boolValue)
            } else if let intValue = try? container.decode(Int.self) {
                array.append(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                array.append(doubleValue)
            } else if let stringValue = try? container.decode(String.self) {
                array.append(stringValue)
            }
        }
        
        return array
    }
}

struct WeatherCacheResponse: Decodable {
    let weatherData: [String: Any]
    let updatedAt: String
    
    private enum CodingKeys: String, CodingKey {
        case weatherData = "weather_data"
        case updatedAt = "updated_at"
    }
    
    // Custom decoder for weather_data JSONB field
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        updatedAt = try container.decode(String.self, forKey: .updatedAt)
        
        // Handle weather_data as generic dictionary from JSONB
        if container.contains(.weatherData) {
            // Try to decode as a nested container first (if it's a JSON object)
            if let nestedContainer = try? container.nestedContainer(keyedBy: GenericCodingKeys.self, forKey: .weatherData) {
                weatherData = try nestedContainer.decode([String: Any].self)
            } else {
                // Fallback to empty dictionary if weather_data is not present or is null
                weatherData = [:]
            }
        } else {
            weatherData = [:]
        }
    }
}

// MARK: - Error Types
// Note: SupabaseError is defined in Core/Utilities/error-types.swift



