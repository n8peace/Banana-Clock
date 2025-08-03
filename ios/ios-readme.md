# Banana Clock iOS App

Native iOS client for Banana Clock - an AI-powered alarm clock app built with SwiftUI and AlarmKit.

## 🚀 Quick Start

### Prerequisites

- Xcode 15+ 
- iOS 26+ device (physical device required for AlarmKit)
- Apple Developer account (for AlarmKit)
- Supabase project (already configured in parent repo)
- RevenueCat account (for subscriptions)

### Setup

1. **Clone and navigate to iOS directory**
   ```bash
   git clone https://github.com/n8peace/Banana-Clock.git
   cd Banana-Clock/ios
   ```

2. **Open in Xcode**
   ```bash
   open BananaClock.xcodeproj
   ```

3. **Configure environment variables**
   
   Create `Config/Secrets.swift` (gitignored):
   ```swift
   struct Secrets {
       static let supabaseAnonKey = "your-anon-key-here"
       static let revenueCatAPIKey = "your-revenuecat-key-here"
   }
   ```

4. **Configure signing**
   - Select your development team in Xcode
   - Update bundle identifier if needed

5. **Build and run**
   - Select target device/simulator
   - Press Cmd+R or click Run

## 🏗️ Architecture

### Project Structure
```
BananaClock/
├── App/                    # App entry point and configuration
├── Core/                   # Models, services, utilities
│   ├── Models/            # Data models
│   ├── Services/          # Business logic
│   └── Extensions/        # Swift extensions
├── Features/              # Feature modules
│   ├── Alarms/           # Alarm functionality
│   ├── WorldClock/       # World clock feature
│   ├── Stopwatch/        # Stopwatch feature
│   ├── Timers/           # Timer functionality
│   └── Premium/          # Subscription features
├── Design/               # UI components and theme
│   ├── Components/       # Reusable UI components
│   └── Theme/           # Design system
└── Resources/            # Assets and localization
```

### Key Technologies
- **SwiftUI** - Modern declarative UI
- **AlarmKit** - Native alarm integration (iOS 26+)
- **Supabase** - Backend and real-time sync
- **RevenueCat** - Subscription management
- **Swift Concurrency** - Async/await throughout

## 🔧 Development

### Environment Configuration

The app uses different Supabase projects for development and production:

- **Debug scheme** → Development Supabase project
- **Release scheme** → Production Supabase project

### Running Tests

```bash
# Unit tests
xcodebuild test -scheme BananaClock -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI tests
xcodebuild test -scheme BananaClockUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Code Style

- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Prefer value types (structs) over reference types
- Use `@MainActor` for UI-related code

## 🎨 Design System

The app uses a custom design system defined in `BananaTheme.swift`:

- **Colors**: Dark mode only with banana yellow accent
- **Typography**: System fonts with custom scales
- **Spacing**: Consistent spacing tokens
- **Components**: Reusable UI components

## 🔐 Security

### API Keys
- Never commit API keys to the repository
- Use environment variables or `Secrets.swift` (gitignored)
- Keys are injected at build time

### Data Protection
- User preferences encrypted in Keychain
- Audio files cached securely
- No sensitive data in UserDefaults

## 📱 Features

### Free Tier
- Unlimited alarms
- World clock
- Stopwatch
- Multiple timers
- Standard alarm sounds

### Premium (Banana Plus)
- AI wake-up experiences
- Weather-aware scripts
- 3 voice personalities
- AI time converter
- Premium alarm sounds

## 🧪 Testing on Device

1. **AlarmKit Requirements**
   - Requires physical device (not simulator)
   - Needs alarm permissions
   - Must be signed with development certificate

2. **TestFlight Distribution**
   ```bash
   # Archive for TestFlight
   xcodebuild archive -scheme BananaClock -archivePath build/BananaClock.xcarchive
   
   # Export for upload
   xcodebuild -exportArchive -archivePath build/BananaClock.xcarchive -exportPath build/ -exportOptionsPlist ExportOptions.plist
   ```

## 🐛 Debugging

### Common Issues

1. **AlarmKit not available**
   - Ensure iOS 26+ target
   - Check entitlements file
   - Verify on physical device

2. **Supabase connection fails**
   - Verify API keys in Secrets.swift
   - Check network connectivity
   - Ensure correct project URL

3. **Audio playback issues**
   - Check audio session configuration
   - Verify file formats (AAC/CAF)
   - Test background audio capability

### Debug Tools
- Xcode Instruments for performance
- Network Link Conditioner for testing
- Console app for device logs

## 🚀 Deployment

### App Store Submission

1. **Update version numbers**
   ```bash
   agvtool new-marketing-version 1.0.1
   agvtool next-version -all
   ```

2. **Create archive**
   - Product → Archive in Xcode
   - Validate archive
   - Upload to App Store Connect

3. **Required for submission**
   - App Store screenshots
   - Privacy policy URL
   - Support URL
   - App description

## 📄 License

Copyright © 2025 Banana Intelligence. All rights reserved.

## 🤝 Contributing

1. Create feature branch from `develop`
2. Make changes and test thoroughly
3. Submit PR to `develop` branch
4. Ensure all tests pass
5. Request code review

## 📞 Support

- Technical issues: Create GitHub issue
- App support: support@bananaintelligence.ai
- Documentation: See `/docs` folder