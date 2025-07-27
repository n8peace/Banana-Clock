# Banana Clock - Data Models & Schema Documentation

## 🗄️ Overview

This document defines all data models, database schemas, and data flow patterns for Banana Clock. It covers both local (Core Data) and remote (Supabase) data structures.

**Database Stack**:
- **Local**: Core Data (SQLite)
- **Remote**: Supabase (PostgreSQL)
- **Sync Strategy**: Eventual consistency with conflict resolution

---

## 🏗️ Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   Core Data     │────▶│  Sync Service    │────▶│    Supabase     │
│  (Local Cache)  │◀────│ (Bidirectional)  │◀────│   (Source of    │
│                 │     │                  │     │     Truth)      │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

---

## 📊 Core Data Models

### 1. Alarm Entity
```swift
// Alarm.xcdatamodeld
@objc(CDAlarm)
public class CDAlarm: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var time: Date
    @NSManaged public var label: String
    @NSManaged public var isEnabled: Bool
    @NSManaged public var isAIEnabled: Bool
    @NSManaged public var soundIdentifier: String
    @NSManaged public var snoozeLength: Int16 // minutes (1-15)
    @NSManaged public var repeatDays: Data // [Weekday]
    @NSManaged public var volume: Float // 0.0-1.0
    @NSManaged public var vibrationEnabled: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var syncStatus: String // "pending", "synced", "conflict"
    @NSManaged public var lastSyncAt: Date?
    
    // Relationships
    @NSManaged public var alarmInstances: Set<CDAlarmInstance>
    @NSManaged public var user: CDUser?
}

// Swift Model
struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var label: String
    var isEnabled: Bool
    var isAIEnabled: Bool
    var soundIdentifier: String
    var snoozeLength: Int
    var repeatDays: [Weekday]
    var volume: Float
    var vibrationEnabled: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum Weekday: Int, CaseIterable, Codable {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
        
        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }
    }
    
    var repeatDescription: String {
        if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays.count == 5 && 
                  !repeatDays.contains(.saturday) && 
                  !repeatDays.contains(.sunday) {
            return "Weekdays"
        } else if repeatDays.count == 2 && 
                  repeatDays.contains(.saturday) && 
                  repeatDays.contains(.sunday) {
            return "Weekends"
        } else {
            return repeatDays.map { $0.shortName }.joined(separator: ", ")
        }
    }
}
```

### 2. AlarmInstance Entity
```swift
// For tracking individual alarm occurrences
@objc(CDAlarmInstance)
public class CDAlarmInstance: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var scheduledTime: Date
    @NSManaged public var actualFireTime: Date?
    @NSManaged public var dismissedAt: Date?
    @NSManaged public var snoozedAt: Date?
    @NSManaged public var snoozeCount: Int16
    @NSManaged public var wakeUpMethod: String // "dismissed", "snoozed", "auto-off"
    @NSManaged public var aiContentPlayed: Bool
    @NSManaged public var audioPlaybackDuration: Double // seconds
    
    // Relationships
    @NSManaged public var alarm: CDAlarm
}
```

### 3. Timer Entity
```swift
@objc(CDTimer)
public class CDTimer: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var label: String
    @NSManaged public var duration: Double // seconds
    @NSManaged public var remainingTime: Double
    @NSManaged public var state: String // "ready", "running", "paused", "finished"
    @NSManaged public var soundIdentifier: String
    @NSManaged public var createdAt: Date
    @NSManaged public var startedAt: Date?
    @NSManaged public var pausedAt: Date?
    @NSManaged public var finishedAt: Date?
    @NSManaged public var isPreset: Bool
    @NSManaged public var presetOrder: Int16
}

struct Timer: Identifiable, Codable {
    let id: UUID
    var label: String
    var duration: TimeInterval
    var remainingTime: TimeInterval
    var state: TimerState
    var soundIdentifier: String
    let createdAt: Date
    var startedAt: Date?
    var pausedAt: Date?
    var finishedAt: Date?
    var isPreset: Bool
    var presetOrder: Int
    
    enum TimerState: String, Codable {
        case ready, running, paused, finished
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return (duration - remainingTime) / duration
    }
}
```

### 4. WorldClock Entity
```swift
@objc(CDWorldClock)
public class CDWorldClock: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var cityName: String
    @NSManaged public var timeZoneIdentifier: String
    @NSManaged public var displayOrder: Int16
    @NSManaged public var createdAt: Date
    
    // Calculated
    @NSManaged public var currentOffset: Int16 // minutes from user's timezone
}

struct WorldClock: Identifiable, Codable {
    let id: UUID
    var cityName: String
    var timeZoneIdentifier: String
    var displayOrder: Int
    let createdAt: Date
    
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
    
    var currentTime: Date {
        Date() // Adjusted for timezone in UI
    }
    
    var offsetDescription: String {
        let offset = timeZone.secondsFromGMT() - TimeZone.current.secondsFromGMT()
        let hours = offset / 3600
        if hours == 0 { return "Same time" }
        let sign = hours > 0 ? "+" : ""
        return "\(sign)\(hours) hrs"
    }
}
```

### 5. User Entity
```swift
@objc(CDUser)
public class CDUser: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var email: String
    @NSManaged public var phone: String?
    @NSManaged public var onboardingStatus: String // "pending", "completed", "skipped"
    @NSManaged public var subscriptionStatus: String // "free", "premium", "cancelled"
    @NSManaged public var isAdmin: Bool
    @NSManaged public var lastLogin: Date?
    @NSManaged public var createdAt: Date
    @NSManaged public var lastSyncAt: Date?
    
    // Relationships
    @NSManaged public var preferences: CDUserPreferences?
    @NSManaged public var alarms: Set<CDAlarm>
}
```

### 6. UserPreferences Entity
```swift
@objc(CDUserPreferences)
public class CDUserPreferences: NSManagedObject {
    @NSManaged public var userId: UUID
    @NSManaged public var timezone: String
    @NSManaged public var locationZip: String
    @NSManaged public var name: String?
    @NSManaged public var city: String?
    @NSManaged public var state: String?
    @NSManaged public var voice: String? // "voice_1", "voice_2", "voice_3"
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    
    // Relationships
    @NSManaged public var user: CDUser
}

struct UserPreferences: Codable {
    let userId: UUID
    var timezone: String
    var locationZip: String
    var name: String?
    var city: String?
    var state: String?
    var voice: String?
    let createdAt: Date
    var updatedAt: Date
}
```

---

## 🌐 Supabase Schema

### 1. Users Table
```sql
CREATE TABLE public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    onboarding_status VARCHAR(50) DEFAULT 'pending' CHECK (onboarding_status IN ('pending', 'completed', 'skipped')),
    subscription_status VARCHAR(50) DEFAULT 'free' CHECK (subscription_status IN ('free', 'premium', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_admin BOOLEAN DEFAULT FALSE,
    last_login TIMESTAMP WITH TIME ZONE,
    
    -- Email validation constraint
    CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_subscription_status ON public.users(subscription_status);
CREATE INDEX idx_users_created_at ON public.users(created_at);
CREATE INDEX idx_users_last_login ON public.users(last_login);

-- RLS Policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admins can insert users" ON public.users
    FOR INSERT WITH CHECK (auth.uid() IN (
        SELECT id FROM public.users WHERE is_admin = TRUE
    ));

CREATE POLICY "Admins can delete users" ON public.users
    FOR DELETE USING (auth.uid() IN (
        SELECT id FROM public.users WHERE is_admin = TRUE
    ));
```

### 2. User Preferences Table
```sql
CREATE TABLE public.user_preferences (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    timezone VARCHAR(50) NOT NULL,
    location_zip VARCHAR(10) NOT NULL,
    name VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(2),
    voice VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT user_preferences_timezone_check CHECK (timezone IS NOT NULL),
    CONSTRAINT user_preferences_location_zip_check CHECK (location_zip IS NOT NULL),
    CONSTRAINT user_preferences_city_check CHECK (city IS NULL OR length(trim(city)) > 0),
    CONSTRAINT user_preferences_state_check CHECK (state IS NULL OR length(trim(state)) = 2),
    CONSTRAINT user_preferences_name_check CHECK (name IS NULL OR length(trim(name)) > 0)
);

-- Indexes
CREATE INDEX idx_user_preferences_location_zip ON public.user_preferences(location_zip);
CREATE INDEX idx_user_preferences_timezone ON public.user_preferences(timezone);
CREATE INDEX idx_user_preferences_city ON public.user_preferences(city);
CREATE INDEX idx_user_preferences_state ON public.user_preferences(state);
CREATE INDEX idx_user_preferences_name ON public.user_preferences(name);

-- RLS Policies
ALTER TABLE public.user_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own preferences" ON public.user_preferences
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Service role has full access" ON public.user_preferences
    FOR ALL USING (auth.role() = 'service_role');
```

### 3. Content Blocks Table
```sql
CREATE TABLE public.content_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    content_type VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    content TEXT,
    script TEXT,
    audio_url VARCHAR(500),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    voice VARCHAR(100),
    duration_seconds INTEGER CHECK (duration_seconds >= 0),
    audio_duration INTEGER CHECK (audio_duration >= 0),
    retry_count INTEGER DEFAULT 0 CHECK (retry_count >= 0),
    content_priority INTEGER DEFAULT 0 CHECK (content_priority >= 0),
    expiration_date DATE NOT NULL,
    language_code VARCHAR(10) DEFAULT 'en-US',
    parameters JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    script_generated_at TIMESTAMP WITH TIME ZONE,
    audio_generated_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT content_blocks_content_type_check CHECK (
        content_type IN (
            'wake_up', 'stretch', 'challenge', 'weather', 'encouragement',
            'headlines', 'sports', 'markets', 'user_intro', 'user_outro', 'user_reminders', 'banana'
        )
    ),
    CONSTRAINT content_blocks_status_check CHECK (
        status IN (
            'pending', 'script_generating', 'script_generated', 'audio_generating',
            'ready', 'script_failed', 'audio_failed', 'failed', 'expired', 'retry_pending'
        )
    ),
    CONSTRAINT content_blocks_date_check CHECK (date >= CURRENT_DATE),
    CONSTRAINT content_blocks_expiration_date_check CHECK (expiration_date >= date)
);

-- Indexes
CREATE INDEX idx_content_blocks_content_type_date ON public.content_blocks(content_type, date);
CREATE INDEX idx_content_blocks_user_content_type_date ON public.content_blocks(user_id, content_type, date);
CREATE INDEX idx_content_blocks_status ON public.content_blocks(status);
CREATE INDEX idx_content_blocks_created_at ON public.content_blocks(created_at);
CREATE INDEX idx_content_blocks_expiration_date ON public.content_blocks(expiration_date);
CREATE INDEX idx_content_blocks_content_priority ON public.content_blocks(content_priority);
CREATE INDEX idx_content_blocks_language_code ON public.content_blocks(language_code);
CREATE INDEX idx_content_blocks_parameters ON public.content_blocks USING GIN (parameters);
CREATE INDEX idx_content_blocks_audio_duration ON public.content_blocks(audio_duration);

-- RLS Policies
ALTER TABLE public.content_blocks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read shared content" ON public.content_blocks
    FOR SELECT USING (user_id IS NULL);

CREATE POLICY "Users can read their own content" ON public.content_blocks
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can write their own content" ON public.content_blocks
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Service role has full access" ON public.content_blocks
    FOR ALL USING (auth.role() = 'service_role');
```

### 4. User Weather Data Table
```sql
CREATE TABLE public.user_weather_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    location_key VARCHAR(100) NOT NULL,
    date DATE NOT NULL,
    weather_data JSONB NOT NULL DEFAULT '{}',
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    fetch_count INTEGER DEFAULT 0 CHECK (fetch_count >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT user_weather_data_location_key_check CHECK (location_key IS NOT NULL),
    CONSTRAINT user_weather_data_date_check CHECK (date IS NOT NULL),
    CONSTRAINT user_weather_data_expires_at_check CHECK (expires_at > created_at),
    CONSTRAINT user_weather_data_unique_location_date UNIQUE (location_key, date)
);

-- Indexes
CREATE INDEX idx_user_weather_data_location_date ON public.user_weather_data(location_key, date);
CREATE INDEX idx_user_weather_data_expires_at ON public.user_weather_data(expires_at);
CREATE INDEX idx_user_weather_data_last_updated ON public.user_weather_data(last_updated);
CREATE INDEX idx_user_weather_data_weather_data ON public.user_weather_data USING GIN (weather_data);

-- RLS Policies
ALTER TABLE public.user_weather_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read weather data" ON public.user_weather_data
    FOR SELECT USING (true);

CREATE POLICY "Service role can manage weather data" ON public.user_weather_data
    FOR ALL USING (auth.role() = 'service_role');
```

### 5. Logs Table
```sql
CREATE TABLE public.logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(100) NOT NULL,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    content_block_id UUID REFERENCES public.content_blocks(id) ON DELETE CASCADE,
    status VARCHAR(50) NOT NULL,
    message TEXT,
    metadata JSONB DEFAULT '{}',
    ip_address INET,
    user_agent VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT logs_event_type_check CHECK (event_type IS NOT NULL),
    CONSTRAINT logs_status_check CHECK (
        status IN ('success', 'error', 'warning', 'info')
    )
);

-- Indexes
CREATE INDEX idx_logs_event_type ON public.logs(event_type);
CREATE INDEX idx_logs_created_at ON public.logs(created_at);
CREATE INDEX idx_logs_user_id ON public.logs(user_id);
CREATE INDEX idx_logs_status ON public.logs(status);
CREATE INDEX idx_logs_content_block_id ON public.logs(content_block_id);
CREATE INDEX idx_logs_user_created_at ON public.logs(user_id, created_at);
CREATE INDEX idx_logs_event_type_status ON public.logs(event_type, status);

-- RLS Policies
ALTER TABLE public.logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read their own logs" ON public.logs
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Service role has full access" ON public.logs
    FOR ALL USING (auth.role() = 'service_role');
```

---

## 🔄 Data Sync Strategy

### Conflict Resolution
```swift
enum ConflictResolution {
    case localWins
    case remoteWins
    case mostRecentWins
    case merge
}

struct SyncConflict {
    let entityType: String
    let entityId: UUID
    let localVersion: Any
    let remoteVersion: Any
    let localUpdatedAt: Date
    let remoteUpdatedAt: Date
    
    func resolve(using strategy: ConflictResolution) -> Any {
        switch strategy {
        case .localWins:
            return localVersion
        case .remoteWins:
            return remoteVersion
        case .mostRecentWins:
            return localUpdatedAt > remoteUpdatedAt ? localVersion : remoteVersion
        case .merge:
            // Custom merge logic per entity type
            return mergeVersions()
        }
    }
}
```

### Sync Flow
```swift
class SyncService {
    func performSync() async throws {
        // 1. Push local changes
        let pendingChanges = try await fetchPendingLocalChanges()
        try await pushToSupabase(pendingChanges)
        
        // 2. Pull remote changes
        let lastSyncDate = UserDefaults.standard.lastSyncDate ?? .distantPast
        let remoteChanges = try await fetchRemoteChanges(since: lastSyncDate)
        
        // 3. Detect conflicts
        let conflicts = detectConflicts(
            local: pendingChanges,
            remote: remoteChanges
        )
        
        // 4. Resolve conflicts
        for conflict in conflicts {
            let resolved = conflict.resolve(using: .mostRecentWins)
            try await applyResolution(resolved)
        }
        
        // 5. Apply remote changes
        try await applyRemoteChanges(remoteChanges)
        
        // 6. Update sync metadata
        UserDefaults.standard.lastSyncDate = Date()
    }
}
```

---

## 📈 Data Migration Strategy

### Core Data Migrations
```swift
// Version 1 -> Version 2: Add AI features
class MigrationV1ToV2: NSEntityMigrationPolicy {
    override func createDestinationInstances(
        forSource sInstance: NSManagedObject,
        in mapping: NSEntityMapping,
        manager: NSMigrationManager
    ) throws {
        try super.createDestinationInstances(
            forSource: sInstance,
            in: mapping,
            manager: manager
        )
        
        // Add default values for new properties
        if let alarm = sInstance as? CDAlarm {
            alarm.isAIEnabled = false
            alarm.snoozeLength = 9
        }
    }
}
```

### Supabase Migrations
```sql
-- Migration: Add voice preferences
ALTER TABLE user_preferences 
ADD COLUMN voice VARCHAR(100);

-- Migration: Add city and state
ALTER TABLE user_preferences 
ADD COLUMN city VARCHAR(100),
ADD COLUMN state VARCHAR(2);

-- Migration: Add name
ALTER TABLE user_preferences 
ADD COLUMN name VARCHAR(100);

-- Migration: Add audio_duration column
ALTER TABLE content_blocks 
ADD COLUMN audio_duration INTEGER CHECK (audio_duration >= 0);

-- Migration: Add banana content type
ALTER TABLE content_blocks DROP CONSTRAINT content_blocks_content_type_check;
ALTER TABLE content_blocks ADD CONSTRAINT content_blocks_content_type_check CHECK (
    content_type IN (
        'wake_up', 'stretch', 'challenge', 'weather', 'encouragement',
        'headlines', 'sports', 'markets', 'user_intro', 'user_outro', 'user_reminders', 'banana'
    )
);
```

---

## 🔐 Data Validation

### Model Validation Rules
```swift
extension Alarm {
    func validate() throws {
        // Time validation
        guard time > Date() else {
            throw ValidationError.alarmInPast
        }
        
        // Label validation
        guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyLabel
        }
        
        // Snooze validation
        guard (1...15).contains(snoozeLength) else {
            throw ValidationError.invalidSnoozeLength
        }
        
        // Volume validation
        guard (0...1).contains(volume) else {
            throw ValidationError.invalidVolume
        }
        
        // AI validation
        if isAIEnabled && !hasActiveSubscription() {
            throw ValidationError.subscriptionRequired
        }
    }
}
```

### Database Constraints
```sql
-- Ensure valid alarm times
ALTER TABLE alarms ADD CONSTRAINT valid_time 
CHECK (EXTRACT(HOUR FROM time) >= 0 AND EXTRACT(HOUR FROM time) <= 23);

-- Ensure valid repeat days
ALTER TABLE alarms ADD CONSTRAINT valid_repeat_days 
CHECK (repeat_days <@ ARRAY[1,2,3,4,5,6,7]);

-- Ensure content block dates are not too far in future
ALTER TABLE content_blocks ADD CONSTRAINT reasonable_date 
CHECK (date <= CURRENT_DATE + INTERVAL '7 days');
```

---

## 📊 Analytics Data Model

### Event Structure
```swift
struct AnalyticsEvent: Codable {
    let eventType: EventType
    let userId: UUID?
    let timestamp: Date
    let properties: [String: Any]
    let deviceInfo: DeviceInfo
    
    enum EventType: String, Codable {
        // Alarm events
        case alarmCreated = "alarm_created"
        case alarmFired = "alarm_fired"
        case alarmDismissed = "alarm_dismissed"
        case alarmSnoozed = "alarm_snoozed"
        
        // AI events
        case aiWakeUpPlayed = "ai_wakeup_played"
        case aiWakeUpFailed = "ai_wakeup_failed"
        case aiTimeConverterUsed = "ai_time_converter_used"
        
        // Subscription events
        case paywallViewed = "paywall_viewed"
        case subscriptionStarted = "subscription_started"
        case subscriptionCancelled = "subscription_cancelled"
        
        // App lifecycle
        case appLaunched = "app_launched"
        case appBackgrounded = "app_backgrounded"
    }
    
    struct DeviceInfo: Codable {
        let model: String
        let osVersion: String
        let appVersion: String
        let locale: String
        let timezone: String
    }
}
```

---

## 🔍 Query Patterns

### Common Queries
```swift
// Get next alarm
func getNextAlarm(for userId: UUID) -> Alarm? {
    let request = CDAlarm.fetchRequest()
    request.predicate = NSPredicate(
        format: "user.id == %@ AND isEnabled == true",
        userId as CVarArg
    )
    request.sortDescriptors = [
        NSSortDescriptor(key: "time", ascending: true)
    ]
    request.fetchLimit = 1
    // Transform time to next occurrence based on repeat days
}

// Get active timers
func getActiveTimers() -> [Timer] {
    let request = CDTimer.fetchRequest()
    request.predicate = NSPredicate(
        format: "state IN %@",
        [TimerState.running.rawValue, TimerState.paused.rawValue]
    )
    request.sortDescriptors = [
        NSSortDescriptor(key: "startedAt", ascending: false)
    ]
}

// Get today's AI content
func getTodayAIContent(for userId: UUID) async throws -> ContentBlock? {
    let today = Calendar.current.startOfDay(for: Date())
    
    return try await supabase
        .from("content_blocks")
        .select()
        .eq("user_id", value: userId.uuidString)
        .eq("content_type", value: "banana")
        .eq("date", value: today.ISO8601Format())
        .single()
        .execute()
        .value
}
```

---

## 🎯 Performance Optimization

### Indexes
```sql
-- Core queries
CREATE INDEX idx_alarms_user_enabled ON alarms(user_id, is_enabled);
CREATE INDEX idx_content_blocks_user_date_type ON content_blocks(user_id, date, content_type);
CREATE INDEX idx_logs_user_type_timestamp ON logs(user_id, event_type, timestamp DESC);

-- Cleanup queries
CREATE INDEX idx_content_blocks_expiration ON content_blocks(expiration_date) 
WHERE status = 'ready';
```

### Data Retention
```swift
// Cleanup old data
func cleanupExpiredData() async throws {
    // Remove logs older than 30 days
    let thirtyDaysAgo = Calendar.current.date(
        byAdding: .day, 
        value: -30, 
        to: Date()
    )!
    
    try await supabase
        .from("logs")
        .delete()
        .lt("created_at", value: thirtyDaysAgo.ISO8601Format())
        .execute()
    
    // Remove expired content blocks
    try await supabase
        .from("content_blocks")
        .delete()
        .lt("expiration_date", value: Date().ISO8601Format())
        .execute()
}
```

---

This comprehensive data model documentation ensures consistent data handling across the entire Banana Clock application, from local storage to cloud synchronization.