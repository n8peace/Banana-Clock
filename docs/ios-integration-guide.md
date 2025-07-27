# Banana Clock iOS App Integration Guide

## 🎯 Overview

This document provides a comprehensive reference for building the SwiftUI iOS app integration with the Banana Clock backend system. The app will integrate with Supabase authentication, user preferences, weather data, and content delivery for personalized morning wake-up experiences.

## 📋 System Architecture Summary

### Backend Components
- **Supabase Database**: PostgreSQL with RLS policies
- **Edge Functions**: Content generation and audio synthesis
- **Storage**: Audio file hosting (AAC format)
- **Authentication**: Supabase Auth with email/password

### Core Tables
- `users` - User authentication and basic info
- `user_preferences` - User settings and location data
- `user_weather_data` - Cached weather information
- `content_blocks` - Generated content and audio URLs
- `logs` - System logging and debugging

### Content Types
- `banana` - Personalized wake-up content (user-specific)
- `weather` - Weather information and forecasts
- `headlines` - News headlines and summaries
- `markets` - Financial market updates
- `sports` - Sports updates and highlights
- `encouragement` - Motivational content

## 🔐 1. User Authentication & Management

### Setup Requirements
```swift
// Required dependencies
import Supabase
import Foundation

// Supabase configuration
let supabaseURL = "YOUR_SUPABASE_URL"
let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
```

### User Registration
```swift
// Register new user
func registerUser(email: String, password: String) async throws -> User {
    let response = try await supabase.auth.signUp(
        email: email,
        password: password
    )
    
    guard let user = response.user else {
        throw AuthError.registrationFailed
    }
    
    // Create user preferences record
    try await createUserPreferences(userId: user.id)
    
    return user
}

// Create initial user preferences
func createUserPreferences(userId: UUID) async throws {
    let preferences = [
        "user_id": userId.uuidString,
        "timezone": TimeZone.current.identifier,
        "location_zip": "", // Will be set during onboarding
        "voice": "voice_1", // Default voice
        "created_at": ISO8601DateFormatter().string(from: Date())
    ]
    
    try await supabase
        .from("user_preferences")
        .insert(preferences)
}
```

### User Login
```swift
func loginUser(email: String, password: String) async throws -> User {
    let response = try await supabase.auth.signIn(
        email: email,
        password: password
    )
    
    guard let user = response.user else {
        throw AuthError.loginFailed
    }
    
    return user
}

func logoutUser() async throws {
    try await supabase.auth.signOut()
}
```

### User Data Updates
```swift
func updateUserProfile(email: String) async throws {
    try await supabase.auth.update(user: [
        "email": email
    ])
}
```

## ⚙️ 2. User Preferences Management

### Data Structure
```swift
struct UserPreferences: Codable {
    let user_id: String
    let timezone: String
    let location_zip: String
    let name: String?
    let city: String?
    let state: String?
    let voice: String?
    let created_at: String?
    let updated_at: String?
}
```

### Fetch User Preferences
```swift
func fetchUserPreferences(userId: String) async throws -> UserPreferences {
    let response: [UserPreferences] = try await supabase
        .from("user_preferences")
        .select()
        .eq("user_id", value: userId)
        .single()
        .execute()
        .value
    
    guard let preferences = response.first else {
        throw PreferencesError.notFound
    }
    
    return preferences
}
```

### Update User Preferences
```swift
func updateUserPreferences(
    userId: String,
    timezone: String? = nil,
    locationZip: String? = nil,
    name: String? = nil,
    city: String? = nil,
    state: String? = nil,
    voice: String? = nil
) async throws {
    var updates: [String: Any] = [
        "updated_at": ISO8601DateFormatter().string(from: Date())
    ]
    
    if let timezone = timezone { updates["timezone"] = timezone }
    if let locationZip = locationZip { updates["location_zip"] = locationZip }
    if let name = name { updates["name"] = name }
    if let city = city { updates["city"] = city }
    if let state = state { updates["state"] = state }
    if let voice = voice { updates["voice"] = voice }
    
    try await supabase
        .from("user_preferences")
        .update(updates)
        .eq("user_id", value: userId)
}
```

### Voice Options
```swift
enum VoiceOption: String, CaseIterable {
    case voice_1 = "voice_1" // Female, meditative wake-up voice
    case voice_2 = "voice_2" // Male, drill sergeant voice
    case voice_3 = "voice_3" // Male, narrative voice
    
    var displayName: String {
        switch self {
        case .voice_1: return "Zen Master"
        case .voice_2: return "Sergeant"
        case .voice_3: return "Guide"
        }
    }
}
```

## 🌤️ 3. Weather Data Integration

### Weather Kit Setup
```swift
import WeatherKit
import CoreLocation

class WeatherService: ObservableObject {
    private let weatherService = WeatherService.shared
    
    func fetchWeatherData(for location: CLLocation) async throws -> Weather {
        return try await weatherService.weather(for: location)
    }
}
```

### Push Weather Data to Backend
```swift
func pushWeatherData(
    locationKey: String,
    weatherData: Weather,
    date: Date
) async throws {
    let dateString = ISO8601DateFormatter().string(from: date).prefix(10)
    let expiresAt = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    
    let weatherPayload: [String: Any] = [
        "location_key": locationKey,
        "date": String(dateString),
        "weather_data": [
            "location": [
                "latitude": weatherData.location.latitude,
                "longitude": weatherData.location.longitude
            ],
            "current": [
                "temperature": weatherData.currentWeather.temperature.value,
                "condition": weatherData.currentWeather.condition.description,
                "humidity": weatherData.currentWeather.humidity,
                "wind_speed": weatherData.currentWeather.wind.speed.value
            ],
            "forecast": [
                "high": weatherData.dailyForecast.forecast.first?.highTemperature.value,
                "low": weatherData.dailyForecast.forecast.first?.lowTemperature.value,
                "summary": weatherData.dailyForecast.forecast.first?.condition.description
            ]
        ],
        "expires_at": ISO8601DateFormatter().string(from: expiresAt),
        "last_updated": ISO8601DateFormatter().string(from: Date())
    ]
    
    try await supabase
        .from("user_weather_data")
        .upsert(weatherPayload, onConflict: "location_key,date")
}
```

### Location Key Strategy
```swift
func generateLocationKey(zipCode: String) -> String {
    return zipCode // For US locations
}

func generateLocationKey(latitude: Double, longitude: Double) -> String {
    return "\(latitude)_\(longitude)" // For international locations
}
```

## 🎵 4. Content Block Retrieval

### Content Block Structure
```swift
struct ContentBlock: Codable {
    let id: String
    let user_id: String?
    let content_type: String
    let date: String
    let content: String?
    let script: String?
    let audio_url: String?
    let status: String
    let voice: String?
    let duration_seconds: Int?
    let audio_duration: Int?
    let retry_count: Int
    let content_priority: Int
    let expiration_date: String
    let language_code: String
    let parameters: [String: Any]?
    let created_at: String
    let updated_at: String
    let script_generated_at: String?
    let audio_generated_at: String?
}
```

### Fetch Banana Content (User-Specific)
```swift
func fetchBananaContent(userId: String, date: Date? = nil) async throws -> ContentBlock? {
    let targetDate = date ?? Date()
    let dateString = ISO8601DateFormatter().string(from: targetDate).prefix(10)
    
    let response: [ContentBlock] = try await supabase
        .from("content_blocks")
        .select()
        .eq("user_id", value: userId)
        .eq("content_type", value: "banana")
        .eq("date", value: String(dateString))
        .in("status", values: ["ready", "content_ready"])
        .order("created_at", ascending: false)
        .limit(1)
        .execute()
        .value
    
    return response.first
}
```

### Fetch Shared Content (Weather, Headlines, etc.)
```swift
func fetchSharedContent(contentType: String, date: Date? = nil) async throws -> ContentBlock? {
    let targetDate = date ?? Date()
    let dateString = ISO8601DateFormatter().string(from: targetDate).prefix(10)
    
    let response: [ContentBlock] = try await supabase
        .from("content_blocks")
        .select()
        .is("user_id", value: nil) // Shared content has no user_id
        .eq("content_type", value: contentType)
        .eq("date", value: String(dateString))
        .in("status", values: ["ready", "content_ready"])
        .order("created_at", ascending: false)
        .limit(1)
        .execute()
        .value
    
    return response.first
}
```

### Trigger Banana Content Generation
```swift
func triggerBananaContentGeneration(userId: String) async throws {
    let payload = ["user_id": userId]
    
    let response = try await supabase.functions.invoke(
        "generate-banana-content",
        invokeOptions: InvokeFunctionOptions(
            body: payload
        )
    )
    
    // Function returns immediately with 200 status
    // Content generation happens asynchronously
    guard response.status == 200 else {
        throw ContentError.generationFailed
    }
}
```

## 🎧 5. Audio Playback & Management

### Audio URL Structure
```
https://[PROJECT_REF].supabase.co/storage/v1/object/public/audio-files/
{content_type}/{content_block_id}_{voice}_{timestamp}.aac
```

### Audio Playback Implementation
```swift
import AVFoundation

class AudioPlayer: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    func playAudio(from url: URL) async throws {
        // Download audio data
        let (data, _) = try await URLSession.shared.data(from: url)
        
        // Create audio player
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()
        
        // Update duration
        duration = audioPlayer?.duration ?? 0
        
        // Start playback
        audioPlayer?.play()
        isPlaying = true
        
        // Start progress tracking
        startProgressTracking()
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        currentTime = 0
    }
    
    private func startProgressTracking() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.audioPlayer else {
                timer.invalidate()
                return
            }
            
            self.currentTime = player.currentTime
            
            if !player.isPlaying {
                self.isPlaying = false
                timer.invalidate()
            }
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
    }
}
```

### Audio Caching Strategy
```swift
class AudioCache {
    private let cache = NSCache<NSString, NSData>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("audio_cache")
        
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func getCachedAudio(for url: URL) -> Data? {
        let filename = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        return try? Data(contentsOf: fileURL)
    }
    
    func cacheAudio(_ data: Data, for url: URL) {
        let filename = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(filename)
        
        try? data.write(to: fileURL)
    }
}
```

## ⏰ 6. Content Expiration & Refresh

### Expiration Handling
```swift
func isContentExpired(_ contentBlock: ContentBlock) -> Bool {
    let expirationDate = ISO8601DateFormatter().date(from: contentBlock.expiration_date) ?? Date()
    return Date() > expirationDate
}

func shouldRefreshContent(_ contentBlock: ContentBlock) -> Bool {
    // Refresh if content is older than 1 hour
    let createdDate = ISO8601DateFormatter().date(from: contentBlock.created_at) ?? Date()
    let oneHourAgo = Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()
    return createdDate < oneHourAgo
}
```

### Content Refresh Strategy
```swift
func refreshContentIfNeeded(contentType: String, userId: String? = nil) async throws {
    // Check if we need to refresh
    let existingContent = userId != nil 
        ? try await fetchBananaContent(userId: userId!, date: Date())
        : try await fetchSharedContent(contentType: contentType, date: Date())
    
    guard let content = existingContent else {
        // No content exists, trigger generation
        if contentType == "banana", let userId = userId {
            try await triggerBananaContentGeneration(userId: userId)
        }
        return
    }
    
    // Check if content needs refresh
    if isContentExpired(content) || shouldRefreshContent(content) {
        if contentType == "banana", let userId = userId {
            try await triggerBananaContentGeneration(userId: userId)
        }
    }
}
```

## 🔄 7. Error Handling & Retry Logic

### Network Error Handling
```swift
enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case unauthorized
}

func handleNetworkError(_ error: Error) -> NetworkError {
    if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet:
            return .noConnection
        case .timedOut:
            return .timeout
        default:
            return .serverError(urlError.code.rawValue)
        }
    }
    return .invalidResponse
}
```

### Retry Logic for Audio Downloads
```swift
func downloadAudioWithRetry(url: URL, maxRetries: Int = 3) async throws -> Data {
    var lastError: Error?
    
    for attempt in 1...maxRetries {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            return data
            
        } catch {
            lastError = error
            
            if attempt < maxRetries {
                // Exponential backoff
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? NetworkError.invalidResponse
}
```

## 📱 8. SwiftUI Implementation Patterns

### Content View Model
```swift
@MainActor
class ContentViewModel: ObservableObject {
    @Published var bananaContent: ContentBlock?
    @Published var weatherContent: ContentBlock?
    @Published var headlinesContent: ContentBlock?
    @Published var isLoading = false
    @Published var error: String?
    
    private let userId: String
    
    init(userId: String) {
        self.userId = userId
    }
    
    func loadContent() async {
        isLoading = true
        error = nil
        
        do {
            // Load content in parallel
            async let banana = fetchBananaContent(userId: userId)
            async let weather = fetchSharedContent(contentType: "weather")
            async let headlines = fetchSharedContent(contentType: "headlines")
            
            let (bananaResult, weatherResult, headlinesResult) = await (banana, weather, headlines)
            
            bananaContent = bananaResult
            weatherContent = weatherResult
            headlinesContent = headlinesResult
            
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
}
```

### Audio Player View
```swift
struct AudioPlayerView: View {
    @StateObject private var audioPlayer = AudioPlayer()
    let audioURL: URL
    
    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: audioPlayer.currentTime, total: audioPlayer.duration)
                .progressViewStyle(LinearProgressViewStyle())
            
            // Playback controls
            HStack {
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        Task {
                            try await audioPlayer.playAudio(from: audioURL)
                        }
                    }
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                
                Button(action: {
                    audioPlayer.stop()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.title)
                }
            }
        }
        .padding()
    }
}
```

## 🔧 9. Configuration & Environment

### Supabase Configuration
```swift
// App configuration
struct AppConfig {
    static let supabaseURL = "https://your-project.supabase.co"
    static let supabaseAnonKey = "your-anon-key"
    
    // Content settings
    static let maxRetries = 3
    static let requestTimeout: TimeInterval = 30
    static let audioCacheSize = 100 * 1024 * 1024 // 100MB
    
    // Audio settings
    static let defaultVoice = "voice_1"
    static let audioFormat = "aac"
}
```

### Environment Setup
```swift
// Initialize Supabase client
let supabase = SupabaseClient(
    supabaseURL: AppConfig.supabaseURL,
    supabaseKey: AppConfig.supabaseAnonKey
)
```

## 🚨 10. Important Implementation Notes

### Audio File Format
- **Format**: AAC (Advanced Audio Coding)
- **Quality**: Optimized for speech synthesis
- **Size**: Typically 100KB-500KB per file
- **Duration**: 90-120 seconds for banana content

### Content Status Flow
1. `pending` → Content generation started
2. `script_generating` → GPT-4o creating script
3. `script_generated` → Script ready, waiting for audio
4. `audio_generating` → ElevenLabs creating audio
5. `ready` → Complete and available for playback

### Fallback Strategy
```swift
func getFallbackContent(contentType: String) -> String {
    switch contentType {
    case "banana":
        return "Good morning! Time to start your day with purpose and energy."
    case "weather":
        return "Weather information is currently unavailable."
    case "headlines":
        return "News updates are being prepared."
    default:
        return "Content is loading..."
    }
}
```

### Rate Limiting
- **ElevenLabs API**: 10,000 characters per month (free tier)
- **Supabase**: 50,000 monthly active users (free tier)
- **Weather Kit**: 1,000 requests per day (free tier)

### Offline Support
- Cache audio files locally
- Store user preferences in UserDefaults
- Provide fallback content when offline
- Sync when connection restored

## 📚 11. Testing & Debugging

### Health Check Endpoints
```swift
func checkBackendHealth() async throws -> Bool {
    let response = try await supabase.functions.invoke("generate-banana-content")
    return response.status == 200
}
```

### Content Validation
```swift
func validateContentBlock(_ content: ContentBlock) -> Bool {
    guard !content.id.isEmpty,
          !content.content_type.isEmpty,
          !content.status.isEmpty,
          !content.expiration_date.isEmpty else {
        return false
    }
    
    // Check if audio URL is valid
    if let audioURL = content.audio_url {
        guard URL(string: audioURL) != nil else {
            return false
        }
    }
    
    return true
}
```

This guide provides the foundation for building a robust iOS app that integrates seamlessly with the Banana Clock backend system. The implementation follows iOS best practices and ensures reliable content delivery for users. 