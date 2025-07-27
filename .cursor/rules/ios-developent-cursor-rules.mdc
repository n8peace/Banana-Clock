# Banana Clock iOS App — Complete Technical Specification

## 🍌 Overview
Banana Clock is a premium iOS clock utility app by Banana Intelligence that reimagines the native Clock experience with AI-powered features. Built for iOS 26+, it combines familiar clock functionality with innovative AI wake-up experiences and intelligent time management tools.

**Version**: 1.0  
**Platform**: iOS 26+ (iPhone only)  
**Frameworks**: AlarmKit, WeatherKit, HealthKit, Siri, RevenueCat  
**Backend**: Supabase (Auth, Database, Storage, Edge Functions)  

---

## 🎯 Product Vision

### Core Philosophy
- **Feel**: Native iPhone experience with Banana personality
- **Function**: Reliable clock utility with premium AI enhancements
- **Freedom**: Free tier with essential features, paid tier with AI magic

### User Value Proposition
- **Free Users**: Full-featured clock app (World Clock, Alarms, Stopwatch, Timers)
- **Premium Users**: AI wake-up experiences, intelligent time converter, advanced features

---

## 🏗️ Architecture

### Frontend Architecture
- **Pattern**: MVVM + SwiftUI @Observable
- **Navigation**: NavigationStack with persistent "Banana Clock" title
- **State Management**: Swift Concurrency + Combine
- **Dependency Injection**: SimpleServiceContainer pattern
- **UI Framework**: SwiftUI 6 with native iOS components

### Backend Architecture (Supabase)
- **Authentication**: Supabase Auth (email/password)
- **Database**: PostgreSQL with RLS policies
- **Storage**: Audio file hosting (AAC format)
- **Edge Functions**: Content generation, audio synthesis
- **Real-time**: Alarm state synchronization

### Core Services
```swift
// Primary Services
- AlarmKitService: System alarm management
- AudioGenerationService: AI wake-up content
- WeatherKitService: Weather data integration
- HealthKitService: Sleep tracking integration
- RevenueCatService: Subscription management
- SupabaseService: Backend communication
```

---

## 🚦 Feature Tiers

### Free Tier
1. **World Clock**
   - Unlimited city clocks
   - Automatic timezone updates
   - Day/night indicators

2. **Alarms**
   - Unlimited alarms
   - Standard alarm sounds
   - Repeat schedules
   - Snooze (1-15 minutes)
   - Labels and notes

3. **Stopwatch**
   - Lap times
   - Share functionality

4. **Timers**
   - Multiple concurrent timers
   - Quick presets
   - Standard timer sounds

### Premium Tier (Banana Plus)
1. **AI Wake-Up Experience**
   - Personalized daily wake-up content
   - Weather-aware scripts
   - News briefings
   - Motivational messages
   - 3 voice options (Zen Master, Sergeant, Guide)
   - Local fallback audio

2. **AI Time Converter**
   - Natural language time queries
   - GPT-4o powered responses
   - Context-aware suggestions
   - Meeting time optimizer

3. **Advanced Features**
   - Unlimited timer presets
   - Custom alarm sounds
   - Sleep analysis integration
   - Siri Shortcuts automation
   - Widget customization

---

## 🎨 Design System

### Brand Identity
- **App Icon**: Minimalist banana clock fusion
- **Typography**: Clean sans-serif (avoid SF Pro)
- **Motion**: Subtle, purposeful animations

### Color Palette
```swift
// Core Colors
Background: #000000 (Pure Black)
Primary Text: #FFFFFF (Pure White)
Accent: #FDE043 (Banana Yellow)
Secondary: #808080 (System Gray)
Success: #34C759 (System Green)
Warning: #FF9500 (System Orange)
Error: #FF3B30 (System Red)

// Semantic Colors
selectedTab: Banana Yellow
unselectedTab: System Gray
divider: System Gray (0.3 opacity)
overlay: Black (0.5 opacity)
```

### Design Tokens
```swift
// Spacing
xSmall: 4pt
small: 8pt
medium: 16pt
large: 24pt
xLarge: 32pt

// Corner Radius
small: 8pt
medium: 12pt
large: 20pt
full: 1000pt

// Animation
quick: 0.2s
standard: 0.3s
slow: 0.5s

// Typography
largeTitle: 34pt
title1: 28pt
title2: 22pt
headline: 17pt
body: 17pt
callout: 16pt
footnote: 13pt
caption: 12pt
```

### UI Components
All components follow Apple HIG with Banana personality:
- **Tab Bar**: Native with yellow accent
- **Navigation**: Standard iOS patterns
- **Controls**: 44pt minimum touch targets
- **Accessibility**: Full VoiceOver support

---

## 🔔 AlarmKit Integration

### Core Implementation
```swift
import AlarmKit

// Authorization
func requestAlarmAuthorization() async -> Bool {
    return await AlarmManager.shared.requestAuthorization()
}

// Alarm Creation
func createAlarm(configuration: AlarmConfiguration) async throws -> Alarm {
    let alarm = try await AlarmManager.shared.schedule(
        id: UUID().uuidString,
        configuration: configuration
    )
    return alarm
}

// Alarm Configuration
struct AlarmConfiguration {
    let scheduledDate: Date
    let label: String
    let sound: AlarmSound
    let snoozeLength: Int // 1-15 minutes
    let repeatDays: [Weekday]
    let isAIWakeUp: Bool
}
```

### Key Features
- **System Integration**: Alarms appear in native Clock app
- **Reliability**: Works in silent mode and Focus modes
- **Lock Screen**: Full-screen alarm interface
- **Dynamic Island**: Countdown support
- **Apple Watch**: Synchronized alarms
- **Siri**: Voice control support

### Live Activity Integration
For countdown timers:
```swift
// Required for countdown alarms
struct BananaAlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            // Lock Screen appearance
            AlarmLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island appearance
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.center) {
                    AlarmExpandedView(context: context)
                }
            } compactLeading: {
                AlarmCompactLeading(context: context)
            } compactTrailing: {
                AlarmCompactTrailing(context: context)
            } minimal: {
                AlarmMinimalView(context: context)
            }
        }
    }
}
```

---

## 🤖 AI Wake-Up System

### Content Generation Pipeline
1. **Daily Generation** (2 AM local time)
   - Check user preferences
   - Fetch weather data
   - Generate personalized script
   - Synthesize audio with selected voice
   - Store in Supabase

2. **Content Types**
   - `banana`: Personalized wake-up message
   - `weather`: Local weather summary
   - `headlines`: News briefing
   - `markets`: Financial updates (if enabled)
   - `sports`: Sports highlights (if enabled)
   - `encouragement`: Motivational content

### Supabase Integration
```swift
// Database Schema
table content_blocks {
    id: UUID
    user_id: UUID (nullable for shared content)
    content_type: String
    date: Date
    content: String
    script: String
    audio_url: String
    status: String // pending, ready, failed
    voice: String
    duration_seconds: Int
    retry_count: Int
    expiration_date: Timestamp
    created_at: Timestamp
    updated_at: Timestamp
}

table user_preferences {
    user_id: UUID
    timezone: String
    location_zip: String
    name: String
    city: String
    state: String
    voice: String // voice_1, voice_2, voice_3
    content_preferences: JSONB
    created_at: Timestamp
    updated_at: Timestamp
}
```

### Audio Delivery
```swift
// Audio URL Structure
https://[PROJECT_REF].supabase.co/storage/v1/object/public/audio-files/
{content_type}/{content_block_id}_{voice}_{timestamp}.aac

// AI Wake-Up Audio Mixer Implementation
class AIWakeUpAudioMixer {
    private let audioEngine = AVAudioEngine()
    private var musicPlayer: AVAudioPlayerNode?
    private var aiVoicePlayer: AVAudioPlayerNode?
    
    func playWakeUpSequence(
        musicURL: URL,
        aiAudioURL: URL,
        targetVolume: Float
    ) async throws {
        // 1. Start background music at 10% volume
        musicPlayer = try await startMusic(
            url: musicURL,
            initialVolume: targetVolume * 0.1
        )
        
        // 2. Gradually increase music volume over 30 seconds
        fadeInMusic(
            from: targetVolume * 0.1,
            to: targetVolume,
            duration: 30.0
        )
        
        // 3. After 10 seconds, overlay AI voice
        try await Task.sleep(for: .seconds(10))
        
        aiVoicePlayer = try await startAIVoice(
            url: aiAudioURL,
            volume: targetVolume * 0.8 // Slightly lower than music
        )
        
        // 4. Monitor completion
        monitorPlayback()
    }
    
    private func fadeInMusic(from: Float, to: Float, duration: TimeInterval) {
        let steps = Int(duration * 10) // 10 updates per second
        let increment = (to - from) / Float(steps)
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            guard let player = self.musicPlayer else {
                timer.invalidate()
                return
            }
            
            let currentVolume = player.volume
            if currentVolume < to {
                player.volume = min(currentVolume + increment, to)
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func monitorPlayback() {
        // If AI audio fails or takes > 10 seconds to load
        Task {
            try await Task.sleep(for: .seconds(10))
            if aiVoicePlayer == nil {
                // Fallback to regular alarm
                await fallbackToStandardAlarm()
            }
        }
    }
}

// Wake-Up Flow
1. T+0s: Music starts at 10% volume
2. T+0-30s: Music fades to target volume
3. T+10s: AI voice joins (80% of target volume)
4. T+end of AI: Check if user acknowledged
5. If not acknowledged: Play standard alarm sound
```

### Fallback Strategy
```swift
// Enhanced fallback with retry mechanism
class AIWakeUpFallbackHandler {
    private var retryCount = 0
    private let maxRetries = 2
    
    func handleAudioFailure(for alarm: Alarm) async throws {
        // 1. Log failure for analytics
        Analytics.log(.aiAudioFailed, properties: [
            "retry_count": retryCount,
            "alarm_id": alarm.id
        ])
        
        // 2. Attempt retry if under limit
        if retryCount < maxRetries {
            retryCount += 1
            try await Task.sleep(for: .seconds(2))
            try await retryAudioGeneration()
        } else {
            // 3. Alert user and fallback
            await showFailureAlert()
            await playStandardAlarm()
        }
    }
    
    private func showFailureAlert() async {
        // Show non-intrusive notification
        let notification = UNMutableNotificationContent()
        notification.title = "AI Wake-Up Unavailable"
        notification.body = "Using standard alarm. We'll fix this for tomorrow!"
        notification.sound = nil // Don't add sound to notification
        
        try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: "ai-fallback",
                content: notification,
                trigger: nil
            )
        )
    }
}

// Local fallback audio hierarchy
1. Try Supabase audio (if premium + connected)
2. Use cached audio (if available)
3. Play generic AI wake-up (if premium)
4. Default to standard alarm sound (always available)
```

---

## 📱 Core Features Implementation

### 1. World Clock
```swift
struct WorldClockView: View {
    @State private var cities: [City] = []
    
    var body: some View {
        List(cities) { city in
            WorldClockRow(city: city)
        }
        .navigationTitle("World Clock")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") { 
                    // Show city picker
                }
            }
        }
    }
}
```

### 2. Alarms
```swift
struct AlarmsView: View {
    @StateObject private var viewModel = AlarmsViewModel()
    
    var body: some View {
        List {
            ForEach(viewModel.alarms) { alarm in
                AlarmRow(alarm: alarm)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteAlarm(alarm)
                        }
                    }
            }
        }
        .navigationTitle("Alarms")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add") {
                    viewModel.showAddAlarm = true
                }
            }
        }
    }
}
```

### 3. Stopwatch
```swift
struct StopwatchView: View {
    @StateObject private var stopwatch = StopwatchService()
    
    var body: some View {
        VStack {
            // Time display
            Text(stopwatch.formattedTime)
                .font(.system(size: 80, weight: .thin, design: .monospaced))
            
            // Controls
            HStack {
                Button(stopwatch.isRunning ? "Lap" : "Reset") {
                    stopwatch.isRunning ? stopwatch.lap() : stopwatch.reset()
                }
                .buttonStyle(.secondary)
                
                Button(stopwatch.isRunning ? "Stop" : "Start") {
                    stopwatch.toggle()
                }
                .buttonStyle(.primary)
            }
            
            // Lap times
            List(stopwatch.laps) { lap in
                LapRow(lap: lap)
            }
        }
    }
}
```

### 4. Timers
```swift
struct TimersView: View {
    @StateObject private var viewModel = TimersViewModel()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))]) {
                ForEach(viewModel.timers) { timer in
                    TimerCard(timer: timer)
                }
                
                Button {
                    viewModel.addTimer()
                } label: {
                    AddTimerCard()
                }
            }
            .padding()
        }
        .navigationTitle("Timers")
    }
}
```

---

## 💰 Monetization (RevenueCat)

### Subscription Tiers
```swift
enum SubscriptionTier {
    case free
    case bananaPlus // $4.99/month or $29.99/year
}

// RevenueCat Configuration
class PurchaseService {
    static let entitlementID = "banana_plus"
    static let monthlyProductID = "banana_plus_monthly"
    static let yearlyProductID = "banana_plus_yearly"
    
    func configure() {
        Purchases.configure(withAPIKey: "your_revenuecat_api_key")
        Purchases.shared.delegate = self
    }
}
```

### Paywall Implementation
```swift
struct PaywallView: View {
    @StateObject private var purchaseService = PurchaseService()
    
    var body: some View {
        VStack {
            // Hero section
            BananaHero()
            
            // Feature comparison
            FeatureComparisonList()
            
            // Pricing options
            PricingCards(
                monthly: purchaseService.monthlyPackage,
                yearly: purchaseService.yearlyPackage
            )
            
            // Purchase button
            PurchaseButton()
            
            // Restore purchases
            RestorePurchasesLink()
        }
    }
}
```

---

## 🔒 Security & Privacy

### Data Protection
- **On-Device**: All time calculations and basic features
- **Encrypted**: User preferences and authentication
- **Anonymous**: Analytics and crash reporting
- **Secure**: Keychain for sensitive data

### Permissions
```swift
// Info.plist
NSLocationWhenInUseUsageDescription: "For accurate weather in your AI wake-up"
NSHealthShareUsageDescription: "To optimize wake-up times based on sleep"
NSMicrophoneUsageDescription: "For voice commands with Siri"
NSSiriUsageDescription: "To control alarms with your voice"
```

### Privacy Policy
- Minimal data collection
- No selling user data
- Transparent data usage
- GDPR/CCPA compliant

---

## 🧪 Testing Strategy

### Unit Tests
- AlarmKit integration
- Time calculations
- Subscription logic
- Audio playback

### UI Tests
- Alarm creation flow
- Timer interactions
- Paywall presentation
- Accessibility

### Integration Tests
- Supabase connection
- WeatherKit API
- HealthKit sync
- RevenueCat purchases

### Device Testing
- iPhone 15/16 Pro (primary)
- iPhone SE (minimum)
- iOS 26 beta versions
- Various timezones

---

## 📦 Launch Strategy

### App Store Optimization
- **Name**: Banana Clock - AI Wake Up
- **Subtitle**: Smart Alarms & Timers
- **Keywords**: alarm, clock, timer, AI, wake up, sleep, morning
- **Category**: Utilities

### Launch Features
1. Core clock functionality
2. AI wake-up (premium)
3. Basic Siri support
4. English only (v1.0)

### Future Roadmap
- [ ] Apple Watch app
- [ ] iPad support
- [ ] Additional languages
- [ ] Sleep cycle integration
- [ ] Smart home integration
- [ ] Calendar integration
- [ ] Full onboarding flow (Note: v1.0 requests permissions contextually)

---

## 🗣️ Siri Integration

### Supported Intents
```swift
// Voice Commands
- "Hey Siri, what time is it in [City]?"
- "Hey Siri, set my bedtime for 10pm"
- "Hey Siri, start a 5-minute timer"
- "Hey Siri, start the stopwatch"
- "Hey Siri, wake me up at 6am"
- "Hey Siri, snooze my alarm"
- "Hey Siri, cancel all my alarms"
- "Hey Siri, show my timers"

// App Intents Implementation
struct SetAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Alarm"
    
    @Parameter(title: "Time")
    var alarmTime: Date
    
    @Parameter(title: "Label", default: "Alarm")
    var label: String
    
    func perform() async throws -> some IntentResult {
        try await AlarmKitService.shared.createAlarm(
            time: alarmTime,
            label: label
        )
        return .result()
    }
}
```

---

## 🛠️ Development Guidelines

### Code Standards
```swift
// Follow iOS 26 best practices
- Use Swift 6 features
- Implement actor isolation
- Handle all optionals safely
- Document public APIs
- Write testable code
```

### Performance Targets
- App launch: < 1 second
- Alarm scheduling: < 100ms
- Audio playback: Instant
- Memory usage: < 100MB
- Battery impact: Minimal

### Accessibility
- Full VoiceOver support
- Dynamic Type compliance
- High contrast mode
- Reduced motion support
- Keyboard navigation
- **Testing**: Run Accessibility Inspector and VoiceOver flow validation before TestFlight submission

---

## 📚 Technical Dependencies

### Swift Packages
```swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.0.0"),
    // Additional packages as needed
]
```

### System Frameworks
- AlarmKit (iOS 26+)
- WeatherKit
- HealthKit
- SiriKit
- AVFoundation
- CoreData
- Combine
- SwiftUI

---

## 🚀 Success Metrics

### Key Performance Indicators
- Daily Active Users (DAU)
- Alarm completion rate
- Premium conversion rate
- User retention (Day 1, 7, 30)
- App Store rating (target: 4.5+)

### Quality Metrics
- Crash-free rate: > 99.5%
- Alarm reliability: > 99.9%
- Audio playback success: > 99%
- User satisfaction: > 90%

---

## 🍌 The Banana Promise

Banana Clock isn't just another clock app—it's your personal time companion that combines the reliability you expect with the intelligence you deserve. Wake up better, manage time smarter, and add a little banana magic to your daily routine.

**Built with 🍌 by Banana Intelligence**