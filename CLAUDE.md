# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### iOS Development

```bash
# Build and test iOS app
cd ios
xcodebuild test -scheme BananaClock -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Build for specific configuration
xcodebuild build -scheme BananaClock -configuration Debug
xcodebuild build -scheme BananaClock -configuration Release

# Run tests only
xcodebuild test-without-building -scheme BananaClock -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Clean build folder
xcodebuild clean -scheme BananaClock

# SwiftLint (if installed)
swiftlint --strict --path ios/
```

### Supabase Development

```bash
# Start local Supabase
cd supabase && supabase start

# Stop local Supabase
cd supabase && supabase stop

# Reset database
cd supabase && supabase db reset

# Deploy to development
cd supabase && supabase db push

# Deploy functions
cd supabase && supabase functions deploy

# Check database diff
cd supabase && supabase db diff
```

### General Development

```bash
# Deploy to develop branch (triggers CI/CD)
./deploy.sh

# Install dependencies
npm install

# Run package.json scripts
npm run dev:supabase    # Start local Supabase
npm run db:reset        # Reset database
npm run functions:deploy # Deploy all functions
```

## iOS 26 AlarmKit API Reference

### Overview
AlarmKit is a new framework in iOS 26+ that provides native alarm and timer functionality with system-level integration. It replaces the previous unofficial alarm APIs with a proper framework that supports:
- Prominent alarms that override Focus and Silent modes
- Custom alarm sounds and haptics
- Live Activities integration for countdown timers
- App Intents for custom alarm actions
- System UI with customizable presentation

### Key Concepts

1. **Authorization Required**: Apps must request authorization via `AlarmManager.requestAuthorization()`
2. **Info.plist Key**: Must include `NSAlarmKitUsageDescription` with usage description
3. **Widget Extension Required**: For countdown presentations, a widget extension is mandatory
4. **Sound API**: Custom sounds are now supported through the configuration (previously only `.default`)

### Core Components

#### AlarmManager
The singleton instance for all alarm operations:
```swift
AlarmManager.shared
```

Key methods:
- `requestAuthorization()` - Request permission to schedule alarms
- `schedule(id:configuration:)` - Schedule a new alarm
- `cancel(id:)` - Cancel an existing alarm
- `pause(id:)` - Pause a countdown alarm
- `resume(id:)` - Resume a paused alarm
- `stop(id:)` - Stop an alerting alarm
- `countdown(id:)` - Trigger countdown/snooze for alerting alarm

Properties:
- `authorizationState` - Current authorization status
- `alarms` - Array of current alarms
- `alarmUpdates` - AsyncSequence for alarm state changes
- `authorizationUpdates` - AsyncSequence for auth state changes

#### AlarmConfiguration
Configuration object for scheduling alarms:
```swift
AlarmManager.AlarmConfiguration<Metadata>(
    countdownDuration: Alarm.CountdownDuration?,
    schedule: Alarm.Schedule?,
    attributes: AlarmAttributes<Metadata>,
    stopIntent: AppIntent?,
    secondaryIntent: AppIntent?,
    sound: AlarmSound  // Custom sounds supported in iOS 26+
)
```

#### Alarm.Schedule
Defines when an alarm should fire:
- `.relative(Alarm.Schedule.Relative)` - Time-based schedule
  - `time: Alarm.Schedule.Relative.Time(hour: Int, minute: Int)`
  - `repeats: Recurrence` (.never or .weekly([Locale.Weekday]))

#### Alarm.CountdownDuration
For timer-style alarms:
```swift
Alarm.CountdownDuration(
    preAlert: TimeInterval?,  // Countdown duration before alert
    postAlert: TimeInterval?   // Snooze/repeat duration after alert
)
```

#### AlarmPresentation
Defines UI for different alarm states:
```swift
AlarmPresentation(
    alert: Alert,           // Required: When alarm is alerting
    countdown: Countdown?,  // Optional: During countdown
    paused: Paused?        // Optional: When paused
)
```

Each state includes:
- Title text
- Button configurations (stop, snooze, pause, resume)
- Secondary button behavior (.countdown or .custom)

#### AlarmAttributes
Wraps presentation with metadata and styling:
```swift
AlarmAttributes<Metadata>(
    presentation: AlarmPresentation,
    metadata: Metadata?,  // Custom data conforming to AlarmMetadata
    tintColor: Color     // App branding color
)
```

### Custom Sounds (iOS 26+)

The `sound` parameter in `AlarmConfiguration` now supports custom alarm sounds. While the exact API isn't detailed in the documentation, it appears to support:
- Custom sound files from app bundle
- Sound configuration (volume, haptics, etc.)
- Fallback to `.default` if custom sound fails

Note: The current implementation uses `.default` as a placeholder until the custom sound API is fully documented.

### Live Activities Integration

For alarms with countdown presentations, you must:
1. Add a Widget Extension target
2. Implement ActivityConfiguration for AlarmAttributes
3. Handle AlarmPresentationState updates
4. Support Dynamic Island and Lock Screen presentations

### Migration from iOS 17-25

Key changes in iOS 26:
1. Custom sound API replaces previous sound limitations
2. Enhanced Live Activities support
3. Improved authorization flow
4. Better state management with AsyncSequence

## Architecture Overview

### Repository Structure

```
Banana-Clock/
├── ios/                  # iOS app (SwiftUI + AlarmKit)
│   ├── BananaClock/     # Main app code
│   │   ├── App/         # App entry point, configuration
│   │   ├── Core/        # Models, services, utilities
│   │   ├── Features/    # Feature modules (Alarms, Timers, etc.)
│   │   └── Design/      # UI components, theme
│   ├── BananaClockWidgets/ # Widget Extension for Live Activities
│   │   ├── TimerLiveActivity.swift    # Timer Live Activity
│   │   ├── StopwatchLiveActivity.swift # Stopwatch Live Activity
│   │   ├── AlarmLiveActivity.swift    # Alarm Live Activity
│   │   └── WidgetModels.swift         # Shared models
│   └── BananaClock.xcodeproj/
├── supabase/            # Backend infrastructure
│   ├── functions/       # Edge functions for AI content
│   └── migrations/      # Database schema
└── .github/workflows/   # CI/CD pipelines
```

### iOS App Architecture

**Pattern**: MVVM with SwiftUI and @Observable
- **Navigation**: NavigationStack with persistent "Banana Clock" title
- **State Management**: Swift Concurrency (async/await)
- **Core Services**: AlarmKit, AudioService, AIWakeUpAudioMixer, LiveActivityService, SupabaseService, RevenueCat
- **Design**: Dark mode only with banana yellow (#FDE043) accent
- **Monetization**: Hard paywall with subscription-only access

**Key Technologies**:
- AlarmKit (iOS 17+) for system alarm integration
- ActivityKit (iOS 16+) for Live Activities and Dynamic Island
- Supabase Swift SDK for backend
- RevenueCat for subscriptions
- AVFoundation for audio playback and mixing
- App Intents for interactive notification controls

### Backend Architecture

**Supabase Project** with:
- PostgreSQL database with RLS policies
- Edge Functions for AI content generation (GPT-4o + ElevenLabs)
- Storage bucket for audio files (AAC format)
- Real-time subscriptions for alarm sync

**Database Tables**:
- `users`: User accounts
- `user_preferences`: Settings, timezone, voice preference
- `content_blocks`: AI-generated content with audio URLs
- `user_weather_data`: Weather information for AI scripts
- `logs`: System logging

**Content Generation Pipeline**:
1. Weather data fetched at 2 AM local time
2. Content generation triggered 60-90 minutes before alarm time
3. **Load distribution**: User-specific offset (0-30 min) based on user_id hash prevents API overload
4. Generate personalized script with GPT-4o
5. Synthesize audio with ElevenLabs
6. Store in Supabase Storage (72-hour retention)
7. **Silent push notification** sent 30 minutes before alarm to wake iOS app
8. iOS app prefetches and caches audio content in background
9. **AlarmKit fires alarm** → Plays cached AI audio or falls back gracefully
10. **Multi-layer fallback**: Cached content → Generic audio → Standard alarm sound
11. Retry mechanism for API failures and rate limiting

**Generation Timing Strategy**:
- For 7 AM alarms: Generation occurs between 5:30-6:00 AM
- Each user gets consistent offset: `(hashtext(user_id) % 31) minutes`
- Prevents thundering herd problem when many alarms fire at same time
- Distributes API load evenly across 30-minute window

**iOS App Reliability Strategy**:
- **Silent push notifications** wake app 30 minutes before alarm (even when closed/backgrounded)
- **Background execution time** (~30 seconds) sufficient for content prefetch
- **AlarmKit integration** ensures alarm fires regardless of app state
- **Works across all states**: App active, backgrounded, closed, phone locked
- **Does NOT work**: When phone is completely powered off (no solution possible)
- **Recovery**: If phone turns on 15+ minutes before alarm, full prefetch available

### CI/CD Pipeline

**Branches**:
- `main`: Production
- `develop`: Development/staging

**Deployment**:
- Push to `develop` triggers automatic deployment
- Manual deployment via `./deploy.sh` script
- iOS builds via GitHub Actions on push to `develop`

## AI Wake-Up Development Methodology

### Pre-Implementation Checklist
- [ ] **Environment Setup**: Verify Xcode 15+, iOS 26+ deployment target
- [ ] **Dependencies**: Confirm all packages compile without warnings
- [ ] **API Keys**: Validate all Supabase and external service credentials
- [ ] **Code Review**: Senior developer review of architecture before implementation
- [ ] **Testing Strategy**: Define unit test cases and integration test scenarios
- [ ] **Performance Baselines**: Establish current app performance metrics
- [ ] **Rollback Plan**: Document how to disable AI features if issues arise

### Implementation Standards
- **Error-First Development**: Write error handling before happy path
- **Interface Segregation**: Create protocols for all services to enable testing
- **Dependency Injection**: Use constructor injection for all dependencies
- **Immutable Models**: All data models should be immutable structs
- **Async/Await**: Use modern concurrency patterns throughout
- **Resource Management**: Explicit cleanup in deinit methods
- **Documentation**: Comprehensive code documentation with examples

### Build & Quality Gates
```bash
# Required before each commit
xcodebuild clean build -scheme BananaClock -configuration Debug
xcodebuild test -scheme BananaClock -destination 'platform=iOS,name=iPhone 15 Pro'
swiftlint --strict --path ios/BananaClock/
```

### Code Structure Requirements
```
BananaClock/Core/AIWakeUp/
├── Models/                          # ✅ COMPLETED (Phase 1)
│   ├── ContentBlock.swift           # → AIContentBlock (renamed for conflict resolution)
│   ├── ContentError.swift           # Comprehensive error types with recovery actions
│   └── ContentMetrics.swift         # Analytics models with performance SLAs
├── Services/                        # 🚧 NEXT (Phase 2)
│   ├── ContentPrefetchService.swift # Protocol + implementation
│   ├── ContentCacheService.swift    # Thread-safe caching
│   └── AudioDownloadService.swift   # Network layer
├── Protocols/                       # 🚧 NEXT (Phase 2)
│   ├── ContentFetching.swift        # Service abstractions
│   └── AudioCaching.swift           # Cache abstractions
└── Tests/                           # ✅ COMPLETED (Phase 1)
    ├── ContentBlockTests.swift      # AIContentBlock model tests (100% coverage)
    ├── ContentErrorTests.swift      # Error handling tests
    ├── ContentMetricsTests.swift    # Metrics and performance tests
    ├── ContentPrefetchTests.swift   # 🚧 NEXT - Unit tests
    ├── CacheServiceTests.swift      # 🚧 NEXT - Cache tests
    └── IntegrationTests.swift       # 🚧 NEXT - End-to-end tests
```

### Error Handling Requirements ✅ IMPLEMENTED
```swift
// ✅ COMPLETED: All errors are strongly typed with recovery strategies
enum ContentFetchError: LocalizedError, Sendable {
    case networkUnavailable
    case authenticationFailed
    case invalidResponse(Data)
    case contentNotFound
    case contentNotReady
    case downloadTimeout
    case invalidURL(String)
    case storageError(underlying: Error)
    case subscriptionRequired
    case userNotFound
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case serverError(statusCode: Int, message: String?)
    case decodingError(underlying: Error)
    
    // ✅ Implemented: User-friendly messages
    var errorDescription: String? { /* comprehensive descriptions */ }
    
    // ✅ Implemented: Actionable recovery steps  
    var recoverySuggestion: String? { /* specific recovery actions */ }
    
    // ✅ Implemented: Recovery action strategies
    var recoveryAction: ErrorRecoveryAction { /* automatic handling */ }
}
```

### Performance Requirements
- **Audio Download**: Must complete within 30 seconds
- **Cache Retrieval**: Must return within 500ms
- **Memory Usage**: Audio files must not exceed 10MB in memory
- **Background Time**: Must complete prefetch within iOS background limit
- **Network Efficiency**: Use HTTP/2, compression, and conditional requests

### Testing Requirements
```swift
// Example test structure
class ContentPrefetchServiceTests: XCTestCase {
    var mockNetworkService: MockNetworkService!
    var mockCacheService: MockCacheService!
    var sut: ContentPrefetchService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockCacheService = MockCacheService()
        sut = ContentPrefetchService(
            networkService: mockNetworkService,
            cacheService: mockCacheService
        )
    }
    
    func testPrefetchSuccess() async throws {
        // Test happy path
    }
    
    func testPrefetchNetworkFailure() async throws {
        // Test network error handling
    }
    
    func testPrefetchTimeout() async throws {
        // Test timeout scenarios
    }
}
```

## Development Guidelines

### iOS Development

1. **Environment Setup**:
   - Configure signing in Xcode
   - API keys are managed via SecureKeyManager (iOS Keychain)
   - For development: Use `SecureKeyManager.shared.storeAPIKey()` to add keys
   - For production: Keys are stored in Supabase secrets

2. **API Key Management**:
   - **All environments**: OpenAI API calls proxied through Supabase Edge Functions
   - iOS app never stores OpenAI keys locally (security best practice)
   - Never commit API keys to source control
   - Use `OpenAIService.shared` for all AI interactions in iOS

3. **Code Style**:
   - Follow iOS development rules in `.cursor/rules/ios-developent-cursor-rules.mdc`
   - Use Swift 6 features where appropriate
   - Prefer value types (structs) over reference types
   - Use `@MainActor` for UI code

3. **Testing**:
   - AlarmKit requires physical device (not simulator)
   - Test on iOS 17+ devices
   - Verify audio playback and background modes

### Supabase Functions

1. **Function Structure**:
   - TypeScript/Deno runtime
   - Async/await patterns
   - Error handling with proper status codes

2. **Content Generation Functions**:
   - `generate-banana-content`: Main wake-up script
   - `generate-weather-content`: Weather summaries
   - `generate-headlines-content`: News briefings
   - `generate-audio`: ElevenLabs synthesis

3. **Testing Functions**:
   ```bash
   # Test locally
   supabase functions serve generate-banana-content
   
   # Deploy single function
   supabase functions deploy generate-banana-content
   
   # Deploy OpenAI proxy
   supabase functions deploy openai-proxy
   
   # Test functions available:
   - test-user: Test user data
   - test-user-weather-data: Test weather integration
   - test-banana-content: Test content generation
   - test-user-preferences: Test preference handling
   - health-check: Runs on cron job for monitoring
   - openai-proxy: Secure proxy for OpenAI API calls
   ```

## Key Integration Points

### AlarmKit Integration
- Alarms created via AlarmKit appear in native Clock app
- Support for snooze (1-15 minutes), repeat schedules
- AI wake-up audio plays via custom audio mixer
- Fallback to standard alarm sound if AI fails

### AI Wake-Up Flow
1. User sets alarm with AI wake-up enabled
2. 2 AM: Generate content for next day
3. Alarm time: Play background music + AI voice via AIWakeUpAudioMixer
   - 10s music fade-in to 60% volume
   - AI voice starts at 15s at 100% volume with music at 60%
   - After voice ends: 20s music crescendo to 120%
   - Transition to alarm sound at 120% volume
   - 5 minute auto-stop maximum
4. Monitor playback, fallback if needed
5. Offline: Use cached general audio content

### OpenAI Integration (via Proxy)
- **All environments**: All OpenAI calls go through `/functions/v1/openai-proxy`
- iOS app uses `OpenAIService.shared` for all AI interactions
- Proxy validates user authentication and subscription status
- OpenAI API key stored as Supabase secret (`OPENAI_API_KEY`)
- Usage tracked per user for monitoring
- No API keys stored locally in iOS app (enhanced security)

### Live Activities & Push Notifications
- **Timer Live Activities**: Persistent notifications with countdown and controls
- **Stopwatch Live Activities**: Real-time tracking with start/stop/lap controls
- **Alarm Live Activities**: Full-screen alarm takeover with AI wake-up integration
- **Dynamic Island Support**: Compact and expanded states for all activities
- **Widget Extension**: BananaClockWidgets target with proper app group configuration
- **App Intents**: Interactive controls for timer/stopwatch operations
- **LiveActivityService**: Centralized management for all Live Activity types

### RevenueCat Subscription
- Monthly: $4.99/month (3-day free trial)
- Annual: $39.99/year (7-day free trial)
- Entitlement ID: `banana_plus`
- Hard paywall: All features require active subscription

## Important Notes

1. **Security**: 
   - Never commit API keys to source control
   - Development: Use SecureKeyManager for iOS Keychain storage
   - Production: Store secrets in Supabase (`supabase secrets set`)
   - OpenAI calls must go through proxy in production
2. **Audio Format**: All audio files must be AAC format for iOS compatibility
3. **Testing**: Physical iOS device required for AlarmKit testing
4. **Database**: Always write migrations for schema changes
5. **Deployment**: Use GitHub Actions and PR to main branch (never deploy directly to Supabase)
6. **RLS Policies**: Ensure proper row-level security for all tables
7. **Audio Storage**: Files stored in Supabase for 72 hours
8. **Voice Configuration**: Voice personalities configured in ElevenLabs prompts
9. **Error Monitoring**: Check Supabase logs for debugging
10. **Subscription Expiry**: Alarms must still function even if subscription expires during active alarm
11. **OpenAI API Setup**:
    - Store key in Supabase: `supabase secrets set OPENAI_API_KEY=sk-...`
    - Deploy proxy function: `supabase functions deploy openai-proxy`
    - iOS usage: `OpenAIService.shared.generateText(prompt: "Hello")`

## Known TODOs

### AlarmKit Integration (iOS 26+)
- Complete alarm integration with AlarmKit for iOS 26+
- Implement custom sound API for iOS 26+
- Add alarm firing delegate/handler to connect with AI audio

### Widget & Notifications
- Implement local notification fallback for non-AlarmKit devices  
- Polish UI/UX for Dynamic Island animations and transitions
- Connect Live Activities to actual timer/alarm services

### AI Wake-Up Voice Integration (Phased Implementation)

#### Phase 1: Foundation & Models (Week 1) ✅ COMPLETED
**Tasks:**
- [x] Create `AIWakeUp` module structure with proper folder organization
- [x] Implement `AIContentBlock` model with comprehensive validation (renamed to avoid conflicts)
- [x] Add `ContentError` enum with all error cases and recovery suggestions
- [x] Create `ContentMetrics` model for analytics tracking
- [x] Write unit tests for all models (100% coverage required)

**Verification:** ✅ PASSED
```bash
# All verification steps completed successfully
✅ xcodebuild build -scheme BananaClock (compilation successful)
✅ Unit tests: ContentBlockTests, ContentErrorTests, ContentMetricsTests (100% coverage)
✅ Build verification with zero compilation errors
✅ Naming conflicts resolved (AIContentBlock, AIAppState)
```

#### Phase 2: Network & Caching Services (Week 2)
**Tasks:**
- [ ] Extend SupabaseService with content fetching methods
- [ ] Implement `AudioDownloadService` with timeout and retry logic
- [ ] Create `ContentCacheService` with thread-safe operations
- [ ] Add comprehensive error handling for all network operations
- [ ] Implement analytics tracking for all service operations
- [ ] Write integration tests for Supabase connectivity

**Verification:**
```bash
# Network tests must pass on real device with various network conditions
xcodebuild test -scheme BananaClock -only-testing:BananaClockTests/SupabaseServiceTests
xcodebuild test -scheme BananaClock -only-testing:BananaClockTests/AudioDownloadServiceTests
xcodebuild test -scheme BananaClock -only-testing:BananaClockTests/ContentCacheServiceTests
```

#### Phase 3: Silent Push & Prefetch Logic (Week 3)
**Tasks:**
- [ ] Implement silent push notification handling in AppDelegate
- [ ] Create `ContentPrefetchService` with background execution support
- [ ] Add push token registration and management
- [ ] Implement prefetch scheduling with proper timer management
- [ ] Add background task handling for iOS background execution limits
- [ ] Create debug UI for testing push notifications

**Verification:**
```bash
# Test on physical device with app in various states
xcodebuild test -scheme BananaClock -only-testing:BananaClockTests/ContentPrefetchServiceTests
# Manual testing required for background states
```

#### Phase 4: AlarmKit Integration (Week 4)
**Tasks:**
- [ ] Connect AlarmKit alarm firing to content cache lookup
- [ ] Implement multi-layer fallback strategy with proper error handling
- [ ] Add immediate fetch fallback for missing cached content
- [ ] Integrate with existing `AIWakeUpAudioMixer`
- [ ] Add content cache cleanup and management
- [ ] Implement analytics for alarm success/failure rates

**Verification:**
```bash
# End-to-end integration tests
xcodebuild test -scheme BananaClock -only-testing:BananaClockTests/AlarmKitIntegrationTests
# Performance tests for sub-500ms cache retrieval
xcodebuild test -scheme BananaClock -only-testing:BananaClockTests/PerformanceTests
```

#### Phase 5: Backend Scheduling (Parallel to iOS work)
**Tasks:**
- [ ] Create scheduled weather fetching at 2 AM daily
- [ ] Implement alarm-based content generation with load distribution
- [ ] Add randomized offset strategy: `(hashtext(user_id) % 31) minutes`
- [ ] Add silent push notification system (30 min before alarms)
- [ ] Create monitoring and alerting for failed generations
- [ ] Add rate limiting and retry logic for external APIs

**Verification:**
```sql
-- Test queries for verification
SELECT COUNT(*) FROM content_blocks WHERE created_at > NOW() - INTERVAL '1 day';
SELECT AVG(generation_time) FROM content_generation_metrics;
```

### Code Quality & Testing Requirements
- **Unit Tests**: 90%+ coverage for all new services and models
- **Integration Tests**: End-to-end AI wake-up flow testing
- **Error Handling**: Comprehensive error cases with user-friendly messages
- **Performance**: Sub-2s audio prefetch, <500ms cache retrieval
- **Memory Management**: Proper cleanup of audio files and timers
- **Thread Safety**: All services must be thread-safe with proper `@MainActor` usage
- **Logging**: Structured logging for debugging and monitoring
- **Build Verification**: Clean compilation with zero warnings
- **Static Analysis**: SwiftLint compliance and memory leak detection

### Security & Privacy
- **API Key Protection**: Never expose keys in logs or error messages
- **Audio Storage**: Secure local storage with proper cleanup
- **Push Token Management**: Secure handling of device tokens
- **Data Validation**: Input sanitization for all external data
- **Subscription Verification**: Server-side verification before content generation

### Monitoring & Analytics
- **Content Generation Success Rate**: Track failures and retry attempts
- **Audio Download Performance**: Monitor download times and failures
- **Cache Hit Rate**: Measure prefetch effectiveness
- **Fallback Usage**: Track when and why fallbacks are used
- **User Experience Metrics**: Alarm reliability and audio quality feedback

## Quality Assurance Checklist

### Pre-Merge Requirements
- [ ] **Build Verification**: Clean compilation with zero warnings on Debug and Release
- [ ] **Unit Tests**: All tests pass with 90%+ code coverage
- [ ] **Integration Tests**: End-to-end scenarios tested on physical device
- [ ] **Performance Tests**: Audio download <30s, cache retrieval <500ms
- [ ] **Memory Tests**: No memory leaks detected via Instruments
- [ ] **Static Analysis**: SwiftLint passes with zero violations
- [ ] **Thread Safety**: All concurrent code properly uses `@MainActor` or thread-safe patterns
- [ ] **Error Handling**: All error paths tested and provide user-friendly messages

### Device Testing Matrix
- [ ] **iPhone SE (3rd gen)**: Minimum screen size testing
- [ ] **iPhone 15 Pro**: Standard device testing
- [ ] **iPhone 15 Pro Max**: Large screen testing
- [ ] **iOS 26.0**: Minimum supported version
- [ ] **iOS 26.x**: Latest version compatibility

### App State Testing
- [ ] **App Active**: Full functionality verification
- [ ] **App Backgrounded**: Silent push notification handling
- [ ] **App Terminated**: Cold start from push notification
- [ ] **Low Memory**: Graceful degradation and cleanup
- [ ] **No Network**: Offline fallback behavior
- [ ] **Poor Network**: Timeout and retry behavior

### Edge Case Testing
- [ ] **Empty Cache**: Immediate fetch fallback works
- [ ] **Corrupted Audio**: Fallback to generic audio
- [ ] **Expired Content**: Proper cleanup and regeneration
- [ ] **Multiple Alarms**: Concurrent handling without conflicts
- [ ] **Subscription Expired**: Graceful fallback to standard alarms
- [ ] **API Rate Limits**: Proper backoff and retry logic

## Rollback & Safety Strategy

### Feature Flags
```swift
struct FeatureFlags {
    static let aiWakeUpEnabled = true  // Can be disabled remotely
    static let silentPushEnabled = true
    static let contentPrefetchEnabled = true
}
```

### Monitoring & Alerts
- **Success Rate < 95%**: Automatic rollback trigger
- **Download Failures > 10%**: Alert engineering team
- **Cache Misses > 20%**: Investigate prefetch timing
- **Memory Usage > 50MB**: Memory leak investigation

### Emergency Rollback Procedure
1. **Immediate**: Set `FeatureFlags.aiWakeUpEnabled = false`
2. **Backend**: Disable content generation cron jobs
3. **Push**: Stop silent push notifications
4. **Cache**: Clear all cached content to free memory
5. **Fallback**: All AI alarms revert to standard alarm behavior

### Deployment Strategy
1. **Phase 1**: Deploy to internal TestFlight (50 users)
2. **Phase 2**: Deploy to external beta (500 users)  
3. **Phase 3**: Gradual rollout (10% → 50% → 100%)
4. **Monitoring**: Real-time dashboards for all metrics
5. **Rollback**: Automatic rollback if success rate drops below threshold

This ensures production-ready, enterprise-grade implementation with comprehensive safety nets.