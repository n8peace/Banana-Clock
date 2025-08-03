# Banana Clock iOS App 📱

**SwiftUI + AlarmKit powered morning transformation system**

This README covers iOS-specific development setup, architecture, and guidelines for contributing to the Banana Clock iOS application.

## 🚀 Quick Start

### Prerequisites
- **Xcode 15.0+** (iOS 26+ deployment target)
- **iOS 26+ physical device** (AlarmKit requires real hardware - not available in simulator)
- **Apple Developer Account** (for signing and AlarmKit capabilities)
- **macOS Sonoma 14.0+** recommended

> ⚠️ **Important**: This app requires iOS 26 or later due to AlarmKit framework dependency. AlarmKit provides system-level alarm reliability that works even when the app is backgrounded or closed, and must be tested on physical devices.

### Initial Setup

1. **Clone and Navigate**
   ```bash
   git clone <repository-url>
   cd Banana-Clock/ios
   ```

2. **Configure Secrets** ⚠️ **CRITICAL STEP**
   ```bash
   # Create secrets file (gitignored)
   touch BananaClock/App/Config/Secrets.swift
   ```
   
   Add this content to `Secrets.swift`:
   ```swift
   import Foundation
   
   struct Secrets {
       // Supabase Configuration
       static let supabaseURL = "your_supabase_url_here"
       static let supabaseAnonKey = "your_supabase_anon_key_here"
       
       // AI Services
       static let openAIAPIKey = "your_openai_api_key_here"
       
       // RevenueCat
       static let revenueCatAPIKey = "your_revenuecat_api_key_here"
   }
   ```

3. **Open in Xcode**
   ```bash
   open BananaClock.xcodeproj
   ```

4. **Configure Signing**
   - Select your development team in Project settings
   - Enable required capabilities (see [Capabilities](#capabilities) below)
   - Ensure bundle identifier is unique to your team

5. **Build and Run**
   - Select a physical iOS device (not simulator)
   - Build and run (⌘R)

## 🏗️ Architecture Overview

### **Design Pattern: MVVM + SwiftUI**
```
View ↔ ViewModel ↔ Model/Service
```

- **Views**: Pure SwiftUI with minimal business logic
- **ViewModels**: `@Observable` classes handling state and business logic
- **Models**: Value types (structs) for data representation
- **Services**: Singletons for cross-cutting concerns (networking, storage, etc.)

### **Key Architectural Decisions**

#### **State Management**
- **`@Observable`** for ViewModels (iOS 17+ modern approach)
- **`@State`** for local view state
- **`@EnvironmentObject`** for app-wide state (AppState, CoreDataManager)
- **No Redux/TCA** - keeping it simple with native SwiftUI patterns

#### **Data Flow**
```
Core Data (Local) ↔ Sync Service ↔ Supabase (Cloud)
                     ↕
                ViewModels
                     ↕
                  Views
```

#### **Navigation**
- **NavigationStack** (iOS 16+) for hierarchical navigation
- **Sheets** for modal presentations
- **Persistent tab state** with UserDefaults

## 📁 Project Structure Deep Dive

```
BananaClock/
├── App/                          # Application lifecycle & configuration
│   ├── banana-clock-app.swift   # App entry point, dependency injection
│   └── Config/
│       ├── environment-config.swift  # Environment detection
│       └── Secrets.swift            # API keys (gitignored)
│
├── Core/                         # Shared functionality
│   ├── Models/                   # Data models
│   │   ├── alarm-model.swift     # Alarm entity with AI preferences
│   │   ├── timer-model.swift     # Timer and stopwatch models
│   │   └── user-model.swift      # User preferences and settings
│   │
│   ├── Services/                 # Business logic & external integrations
│   │   ├── core-data-manager.swift     # Local storage + CloudKit
│   │   ├── supabase-service.swift      # Backend API integration
│   │   ├── ai-timezone-service.swift   # GPT-4o timezone intelligence
│   │   ├── sync-service.swift          # Data synchronization
│   │   ├── audio-service.swift         # Sound playback
│   │   ├── purchase-service.swift      # RevenueCat subscriptions
│   │   └── haptic-manager.swift        # Haptic feedback
│   │
│   ├── AIWakeUp/                 # ✅ AI Wake-up Integration (Phase 1 Complete)
│   │   ├── Models/               # Foundation models with comprehensive validation
│   │   │   ├── ContentBlock.swift      # → AIContentBlock (Supabase content mapping)
│   │   │   ├── ContentError.swift      # Error handling with recovery strategies
│   │   │   └── ContentMetrics.swift    # Performance tracking & monitoring
│   │   └── Tests/                # 100% test coverage for all models
│   │       ├── ContentBlockTests.swift   # AIContentBlock model tests
│   │       ├── ContentErrorTests.swift   # Error handling tests
│   │       └── ContentMetricsTests.swift # Metrics and performance tests
│   │
│   └── Components/               # Reusable UI components
│       ├── BananaButton.swift    # Styled buttons
│       ├── BananaCard.swift      # Container components
│       ├── BananaConfettiView.swift    # Celebration animations
│       └── GoldenGlowModifier.swift    # Visual effects
│
├── Features/                     # Feature-specific modules
│   ├── Alarms/                   # Wake-up & regular alarms
│   │   ├── ViewModels/
│   │   │   ├── alarms-view-model.swift      # Main alarm list logic
│   │   │   └── WakeUpAlarmsViewModel.swift  # Wake-up specific logic
│   │   └── Views/
│   │       ├── alarms-view.swift           # Main alarm list
│   │       ├── alarm-detail-view.swift     # Regular alarm editing
│   │       ├── WakeUpManagementView.swift  # Wake-up alarm hub
│   │       ├── WakeUpScheduleView.swift    # Flexible scheduling
│   │       └── WakeUpAISettingsView.swift  # AI personalization
│   │
│   ├── Timers/                   # Timer functionality
│   │   └── Views/timers-view.swift        # Timer management & creation
│   │
│   ├── WorldClock/               # Global time management
│   │   └── Views/world-clock-view.swift   # Cities + AI timezone converter
│   │
│   ├── Stopwatch/                # Precision timing
│   │   └── Views/stopwatch-view.swift     # Lap timing & controls
│   │
│   ├── TabView/                  # Navigation
│   │   └── main-tab-view.swift           # Bottom tab navigation
│   │
│   └── Premium/                  # Subscription management
│       └── paywall-view.swift            # Upgrade prompts & billing
│
└── Design/                       # Visual design system
    ├── BananaTheme.swift         # Colors, spacing, typography
    └── Extensions/               # SwiftUI extensions for styling
```

## 🎯 Core Features Implementation

### **🌅 Wake-Up Alarms (Primary Feature)**

**Key Components:**
- `WakeUpManagementView`: Main interface for wake-up alarm configuration
- `WakeUpAlarmsViewModel`: Business logic for one-alarm-per-day constraint
- `WakeUpScheduleView`: Flexible day-based scheduling (MWF 7am, TTh 8am, etc.)
- `WakeUpAISettingsView`: Personalization preferences for AI content

**Critical Business Rules:**
- **One wake-up alarm per day maximum** (prevents over-scheduling)
- **18-hour visibility rule**: Tomorrow's alarm visible after 6pm today
- **Day-based scheduling**: Different times for different days of week
- **AI content integration**: Weather, news, sports, philosophy, reminders

**Implementation Details:**
```swift
// Wake-up alarm model supports flexible scheduling
struct Alarm {
    var isWakeUpAlarm: Bool
    var wakeUpDays: Set<Weekday>?  // Mon-Sun flexibility
    var aiEnabled: Bool
    var aiPreferences: AIPreferences
}

// One-alarm-per-day enforcement
class WakeUpAlarmsViewModel {
    func canAddAlarmForDay(_ day: Weekday) -> Bool {
        return !existingAlarms.contains { $0.wakeUpDays?.contains(day) == true }
    }
}
```

### **⏲️ Smart Timers**

**Key Features:**
- **Quick presets** (1, 5, 10 minutes) for instant start
- **Bulk management** for editing/deleting multiple timers
- **Smart deduplication** prevents identical timer clutter
- **Background operation** continues when app is closed

**Implementation Highlights:**
```swift
// Timer state management with proper cleanup
class TimersViewModel: ObservableObject {
    @Published var timers: [BananaTimer] = []
    private var timerTasks: [UUID: Task<Void, Never>] = [:]
    
    // Automatic cleanup of duplicate inactive timers
    private func cleanupDuplicateInactiveTimers() {
        // Keep only most recent timer for each duration+label combination
    }
}
```

### **🌍 AI Timezone Converter**

**Unique Value Proposition:**
- Input multiple cities → get AI-powered meeting time recommendations
- Considers business hours, cultural preferences, and optimal windows
- Beautiful confetti effects celebrate successful coordination

**Implementation:**
```swift
// AI-powered timezone intelligence
class AITimezoneService: ObservableObject {
    @Published var currentRecommendation: String = ""
    
    func getRecommendation(for clocks: [WorldClock], selectedDate: Date) async {
        // GPT-4o analysis of optimal meeting times across timezones
        // Considers business hours, cultural preferences, exclusion rules
    }
}

// Confetti celebration system
struct BananaConfettiView: UIViewRepresentable {
    // CAEmitterLayer-based particle system
    // Banana emojis burst from timezone converter when AI responds
}
```

## 🔧 Development Guidelines

### **Code Style & Standards**

#### **SwiftUI Best Practices**
```swift
// ✅ Good: Computed properties for complex views
private var complexSection: some View {
    VStack {
        // Complex layout logic
    }
}

// ✅ Good: Extract view logic to separate functions
private func handleUserAction() {
    // Business logic here
}

// ❌ Avoid: Massive view bodies
var body: some View {
    // 200+ lines of layout code
}
```

#### **State Management**
```swift
// ✅ Good: @Observable ViewModels (iOS 17+)
@Observable
class AlarmsViewModel {
    var alarms: [Alarm] = []
    var isLoading = false
}

// ✅ Good: Environment injection for shared state
struct ContentView: View {
    @EnvironmentObject var appState: AppState
}

// ❌ Avoid: @StateObject for simple state
@StateObject private var simpleCounter = Counter() // Use @State instead
```

#### **Error Handling**
```swift
// ✅ Good: Structured error handling
enum AlarmsError: LocalizedError {
    case alarmKitPermissionDenied
    case maxAlarmsReached
    case invalidTime
    
    var errorDescription: String? {
        switch self {
        case .alarmKitPermissionDenied:
            return "Please enable alarm permissions in Settings"
        // etc.
        }
    }
}
```

### **Performance Considerations**

#### **AlarmKit Integration**
- **Physical device required**: AlarmKit doesn't work in simulator
- **Permission handling**: Request permissions contextually, not on app launch
- **System integration**: Alarms appear in native iOS Clock app

#### **Core Data + CloudKit**
- **Background context** for sync operations
- **Batch operations** for large data sets
- **Conflict resolution** for multi-device scenarios

#### **Memory Management**
```swift
// ✅ Good: Weak references in closures
timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.updateUI()
}

// ✅ Good: Automatic cleanup
deinit {
    timer?.invalidate()
    // Cancel async tasks
    tasks.forEach { $0.cancel() }
}
```

## 🔒 Required Capabilities

Add these to your app's capabilities in Xcode:

### **Essential Capabilities**
- **Background Modes**: Background App Refresh, Background Processing
- **Push Notifications**: For alarm notifications
- **CloudKit**: For Core Data sync across devices

### **Optional Capabilities** (for full feature set)
- **Location Services**: For weather-based AI content
- **Siri & Shortcuts**: For voice interaction
- **App Groups**: For sharing data with extensions

## 🧪 Testing Strategy

### **Unit Testing Focus Areas**
```swift
// ✅ COMPLETED: AI Wake-up Foundation Tests
class ContentBlockTests: XCTestCase {
    func testAIContentBlockValidation() {
        // ✅ Comprehensive model validation testing
    }
    
    func testContentErrorRecoveryStrategies() {
        // ✅ Error handling and recovery action testing
    }
    
    func testContentMetricsPerformanceSLAs() {
        // ✅ Performance tracking and threshold validation
    }
}

// Core business logic
class AlarmsViewModelTests: XCTestCase {
    func testOneAlarmPerDayConstraint() {
        // Verify wake-up alarm day conflict prevention
    }
    
    func testAlarmSchedulingLogic() {
        // Test next fire date calculations
    }
}

// Data persistence
class CoreDataTests: XCTestCase {
    func testAlarmSyncWithCloudKit() {
        // Verify cloud sync behavior
    }
}
```

### **Integration Testing**
- **AlarmKit integration**: Test on physical devices only
- **AI service integration**: Mock responses for consistent testing
- **Subscription flow**: Test with RevenueCat sandbox environment

### **Manual Testing Checklist**
- [ ] Wake-up alarms fire at correct times
- [ ] AI timezone converter provides intelligent recommendations
- [ ] Timers continue running in background
- [ ] Subscription paywall blocks features appropriately
- [ ] Confetti effects render smoothly on all device sizes

## 🚨 Common Issues & Solutions

### **AlarmKit Issues**
```swift
// Issue: Alarms not appearing in system Clock app
// Solution: Verify permissions and AlarmKit setup
func setupAlarmKit() {
    // Ensure proper AlarmKit configuration
    // Check alarm store authorization status
}
```

### **Core Data + CloudKit Issues**
```swift
// Issue: Data not syncing across devices
// Solution: Verify CloudKit container setup and network connectivity
func debugCloudKitSync() {
    // Check CKContainer status
    // Verify user is signed into iCloud
}
```

### **AI Service Issues**
```swift
// Issue: OpenAI API calls failing
// Solution: Verify API key configuration and rate limits
func debugAIService() {
    // Check API key validity
    // Implement proper error handling and retry logic
}
```

## 🔐 Security Considerations

### **⚠️ Critical Security Issues**
1. **API Keys in Source Code**: Currently hardcoded in `Secrets.swift`
2. **Solution Required**: Move to iOS Keychain for encrypted storage

```swift
// TODO: Implement secure key management
class SecureKeyManager {
    static func storeAPIKey(_ key: String, for service: String) {
        // Store in iOS Keychain with proper encryption
    }
    
    static func retrieveAPIKey(for service: String) -> String? {
        // Retrieve from Keychain securely
    }
}
```

### **Best Practices**
- **Never commit API keys** to version control
- **Use App Transport Security** for network requests
- **Validate user input** especially for AI content generation
- **Implement certificate pinning** for production API calls

## 🚀 Build & Distribution

### **Debug Builds**
```bash
# Build for development
xcodebuild -scheme BananaClock -configuration Debug -destination 'platform=iOS,name=Your Device'

# With verbose logging
xcodebuild -scheme BananaClock -configuration Debug -verbose
```

### **Release Builds**
```bash
# Build for App Store distribution
xcodebuild -scheme BananaClock -configuration Release -archivePath BananaClock.xcarchive archive

# Export for App Store
xcodebuild -exportArchive -archivePath BananaClock.xcarchive -exportPath ./Export -exportOptionsPlist ExportOptions.plist
```

### **GitHub Actions Integration**
The project includes automated CI/CD via GitHub Actions:
- **Build verification** on pull requests
- **Automated testing** on device simulators
- **App Store Connect upload** on main branch merges

## 📊 Performance Monitoring

### **Key Metrics to Track**
- **App launch time**: Target <2 seconds cold start
- **Memory usage**: Monitor for memory leaks in timer management
- **Battery usage**: Especially for background timer operations
- **Crash rate**: Target <0.1% crash-free sessions

### **Instruments Profiles**
```bash
# Profile memory usage
instruments -t "Allocations" -D BananaClock.trace BananaClock.app

# Profile time complexity
instruments -t "Time Profiler" -D BananaClock.trace BananaClock.app
```

## 🎯 Next Steps for Contributors

### **High-Priority Development Areas**
1. ✅ **Phase 1 Complete**: Foundation models, error handling, and testing
2. 🚧 **Phase 2 Next**: Network services, caching, and audio downloading
3. **Audio Mixer Implementation**: Seamless music + AI voice experience
4. **Push Notification System**: Reliable alarm delivery
5. **Subscription Flow Polish**: Complete RevenueCat integration  
6. **Background Processing**: Efficient content generation
7. **Security Hardening**: Keychain-based API key storage

### **Feature Enhancement Opportunities**
1. **Apple Watch Support**: Wrist-based alarm management
2. **Siri Integration**: Voice-controlled alarm creation
3. **Shortcuts Support**: iOS automation integration
4. **Multi-language Support**: Global market expansion
5. **Smart Home Integration**: IoT device coordination

---

## 🆘 Need Help?

### **Development Questions**
- Check [CLAUDE.md](../CLAUDE.md) for architectural guidance
- Review [docs/](../docs/) for comprehensive documentation
- Search existing GitHub Issues before creating new ones

### **Technical Support**
- iOS-specific issues: Create GitHub Issue with "ios" label
- Architecture questions: Reference this README and CLAUDE.md
- Performance issues: Include Instruments traces when reporting

---

**Happy coding! 🍌** Remember: we're not just building an alarm app—we're crafting morning experiences that transform how people start their day.

*"Code with intention, test with devices, ship with confidence."*