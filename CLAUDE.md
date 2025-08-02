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
1. Daily generation at 2 AM local time
2. Generate personalized script with GPT-4o
3. Synthesize audio with ElevenLabs
4. Store in Supabase Storage (72-hour retention)
5. Fallback to standard alarm if generation fails
6. Retry mechanism for API failures
7. Rate limiting implemented for external APIs

### CI/CD Pipeline

**Branches**:
- `main`: Production
- `develop`: Development/staging

**Deployment**:
- Push to `develop` triggers automatic deployment
- Manual deployment via `./deploy.sh` script
- iOS builds via GitHub Actions on push to `develop`

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

- Complete alarm integration with AlarmKit for iOS 26+
- Implement local notification fallback for non-AlarmKit devices  
- Polish UI/UX for Dynamic Island animations and transitions
- Add AI wake-up content caching and offline fallback
- Implement subscription expiration handling during active alarms