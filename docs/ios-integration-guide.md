# iOS Integration Guide

## Overview

This guide documents the integration between the Banana Clock iOS app and the Supabase backend, including authentication, data synchronization, and content caching strategies.

## Authentication Strategy

### Environment Configuration
The iOS app supports two environments:
- **Development**: Debug builds connect to Supabase develop environment
- **Production**: Release builds connect to Supabase production environment

### Supabase Auth Integration
- **User Registration**: Email/password authentication via Supabase Auth
- **Session Management**: Automatic token refresh and session persistence
- **User Isolation**: RLS policies ensure users only access their own data
- **Offline Support**: Local session caching for offline functionality

## Data Models

### User Preferences
```swift
struct UserPreferences: Codable {
    let userId: UUID
    var timezone: String
    var locationZip: String
    var city: String?
    var state: String?
    var name: String?
    var voice: String?
    var weatherEnabled: Bool
    var headlinesCategories: [String]
    var sportsCategories: [String]
    var lastSyncAt: Date?
}
```

### Content Caching
```swift
struct CachedContent: Codable {
    let id: UUID
    let alarmId: UUID
    let contentType: String
    let contentData: [String: Any]
    let expiresAt: Date
}
```

## Database Schema Integration

### user_preferences Table
The iOS app syncs AI wake-up preferences to the `user_preferences` table:

| Column | iOS Property | Description |
|--------|-------------|-------------|
| `weather_enabled` | `weatherEnabled` | Boolean toggle for weather content |
| `headlines_categories` | `headlinesCategories` | JSONB array of news categories |
| `sports_categories` | `sportsCategories` | JSONB array of sports categories |
| `last_sync_at` | `lastSyncAt` | Timestamp of last iOS sync |

### content_blocks Table
The iOS app uses the existing `content_blocks` table for content caching:

| Content Type | Description | Cache Duration |
|--------------|-------------|----------------|
| `ios_banana` | AI wake-up content | 72 hours |
| `ios_headlines` | News content | 72 hours |
| `ios_sports` | Sports content | 72 hours |
| `ios_weather` | Weather content | 72 hours |
| `ios_markets` | Market content | 72 hours |

## Sync Strategy

### Bidirectional Sync
1. **On App Launch**: Download user preferences from Supabase
2. **On Preference Change**: Update local Core Data + Supabase
3. **On Alarm Creation**: Trigger content prefetching
4. **Background Sync**: Periodic content updates

### Conflict Resolution
- **Last Write Wins**: Most recent timestamp wins
- **Offline Changes**: Queued for sync when online
- **Data Validation**: Server-side validation of all changes

### Content Prefetching
1. **Trigger**: When alarm is set/enabled
2. **Timing**: 24 hours before alarm time
3. **Content Types**: All enabled content (weather, headlines, sports, markets)
4. **Storage**: Local Core Data + Supabase content_blocks table

## Offline Support

### Content Caching
- **72-Hour Cache**: Content expires after 72 hours
- **Local Storage**: Core Data for offline access
- **Fallback Content**: Generic templates when cached content unavailable
- **Background Refresh**: Automatic content updates when online

### Offline Flow
1. **Check Local Cache**: Look for specific alarm content
2. **Check Remote Cache**: Fallback to Supabase content_blocks
3. **Generic Fallback**: Use pre-cached templates
4. **Log Event**: Record alarm trigger in logs table

## API Integration

### Content Generation Functions
The iOS app triggers content generation via Supabase Edge Functions:

| Function | Purpose | iOS Integration |
|----------|---------|-----------------|
| `generate-wake-up-content` | Daily wake-up messages | Respects user preferences |
| `generate-weather-content` | Weather reports | Respects `weather_enabled` |
| `generate-headlines-content` | News headlines | Respects `headlines_categories` |
| `generate-sports-content` | Sports updates | Respects `sports_categories` |
| `generate-markets-content` | Market updates | Always included if enabled |

### Logging Integration
The iOS app logs events to the `logs` table:

```swift
enum LogEventType {
    case userPreferencesSynced
    case contentCached
    case offlineFallbackUsed
    case alarmTriggered
    case syncFailed
}
```

## Error Handling

### Network Failures
- **Graceful Degradation**: App continues with cached content
- **Retry Logic**: Exponential backoff for failed requests
- **User Feedback**: Clear error messages and status indicators

### Data Validation
- **Client-Side Validation**: Validate data before sending to server
- **Server-Side Validation**: Supabase constraints and triggers
- **Error Recovery**: Automatic retry with corrected data

## Performance Considerations

### Caching Strategy
- **Content Cache**: 72-hour expiration for all content types
- **User Preferences**: Local cache with periodic sync
- **Audio Files**: Local storage with background download
- **Metadata**: Lightweight JSON for quick queries

### Background Processing
- **Content Prefetching**: 24 hours before alarm time
- **Periodic Sync**: Every 6 hours when app is active
- **Cleanup**: Remove expired content and old logs
- **Battery Optimization**: Efficient background operations

## Security

### Data Protection
- **RLS Policies**: User isolation at database level
- **Encrypted Storage**: Keychain for sensitive data
- **Token Management**: Secure Supabase token handling
- **Privacy Controls**: Granular permission management

### Authentication
- **Supabase Auth**: Secure user authentication
- **Session Management**: Automatic token refresh
- **Offline Security**: Local session validation
- **Data Encryption**: End-to-end encryption for sensitive data

## Testing Strategy

### Offline Testing
- **Airplane Mode**: Verify offline fallbacks work
- **Network Interruption**: Test sync recovery
- **Cache Expiration**: Test content refresh
- **Data Corruption**: Test error recovery

### Content Testing
- **Weather Enabled/Disabled**: Verify content generation
- **Category Selection**: Test headlines/sports filtering
- **Content Quality**: Verify generated content meets requirements
- **Audio Generation**: Test ElevenLabs integration

### Sync Testing
- **Conflict Resolution**: Test simultaneous edits
- **Large Data Sets**: Test with many alarms
- **Performance**: Verify sync doesn't block UI
- **Error Scenarios**: Test network failures and recovery

## Monitoring

### Key Metrics
- **Sync Success Rate**: Track successful preference syncs
- **Content Cache Hit Rate**: Monitor cache effectiveness
- **Offline Usage**: Track fallback usage
- **User Engagement**: Monitor alarm usage patterns

### Logging
- **Event Tracking**: Comprehensive event logging
- **Error Monitoring**: Track and alert on failures
- **Performance Metrics**: Monitor sync and cache performance
- **User Analytics**: Track feature usage and engagement

## Future Enhancements

### Planned Features
- **Real-time Sync**: WebSocket-based real-time updates
- **Advanced Caching**: Predictive content prefetching
- **Multi-device Sync**: Seamless experience across devices
- **Offline Analytics**: Track offline usage patterns

### Performance Optimizations
- **Incremental Sync**: Only sync changed data
- **Compression**: Reduce data transfer size
- **Background Processing**: More efficient background operations
- **Memory Optimization**: Better memory management for large datasets 