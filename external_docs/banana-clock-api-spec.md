# Banana Clock - API Endpoint Specification

## 🌐 Overview

This document specifies all API endpoints for Banana Clock, including Supabase Edge Functions, authentication flows, and real-time subscriptions.

**Base URL**: `https://[PROJECT_REF].supabase.co`  
**API Version**: v1  
**Authentication**: Supabase Auth (JWT Bearer tokens)  
**Content Type**: `application/json`

---

## 🔐 Authentication Endpoints

### Sign Up
```http
POST /auth/v1/signup
```

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123!",
  "data": {
    "timezone": "America/Los_Angeles",
    "app_version": "1.0.0",
    "device_model": "iPhone16,1"
  }
}
```

**Response** `201 Created`:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "v1.refresh_token_here",
  "expires_in": 3600,
  "token_type": "bearer",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "created_at": "2025-07-23T10:00:00Z",
    "app_metadata": {
      "provider": "email"
    },
    "user_metadata": {
      "timezone": "America/Los_Angeles",
      "app_version": "1.0.0",
      "device_model": "iPhone16,1"
    }
  }
}
```

**Error Responses**:
- `400 Bad Request` - Invalid email format or weak password
- `422 Unprocessable Entity` - Email already registered

### Sign In
```http
POST /auth/v1/token?grant_type=password
```

**Request Body**:
```json
{
  "email": "user@example.com",
  "password": "securePassword123!"
}
```

**Response** `200 OK`:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "v1.refresh_token_here",
  "expires_in": 3600,
  "token_type": "bearer",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com"
  }
}
```

**Error Responses**:
- `400 Bad Request` - Invalid credentials
- `429 Too Many Requests` - Rate limit exceeded

### Refresh Token
```http
POST /auth/v1/token?grant_type=refresh_token
```

**Request Body**:
```json
{
  "refresh_token": "v1.refresh_token_here"
}
```

**Response** `200 OK`: Same as Sign In response

### Sign Out
```http
POST /auth/v1/logout
Authorization: Bearer {access_token}
```

**Response** `204 No Content`

---

## 🚀 Edge Functions

### Generate AI Wake-Up Content
```http
POST /functions/v1/generate-banana-content
Authorization: Bearer {access_token}
```

**Description**: Triggers generation of personalized AI wake-up content for the authenticated user.

**Request Body**:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response** `200 OK`:
```json
{
  "success": true,
  "message": "Banana content generation started",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Error Responses**:
- `400 Bad Request` - Missing or invalid user_id
- `401 Unauthorized` - Invalid or expired token
- `500 Internal Server Error` - Processing error

### Health Check
```http
GET /functions/v1/health-check
```

**Response** `200 OK`:
```json
{
  "success": true,
  "overall_status": "healthy",
  "passed_checks": 8,
  "failed_checks": 0,
  "total_checks": 8,
  "checks": {
    "database_connection": "healthy",
    "storage_access": "healthy",
    "ai_generation": "healthy",
    "weather_api": "healthy"
  },
  "timestamp": "2025-07-23T12:00:00Z"
}
```

**Response** `503 Service Unavailable` (when unhealthy):
```json
{
  "success": false,
  "overall_status": "critical",
  "passed_checks": 5,
  "failed_checks": 3,
  "total_checks": 8,
  "checks": {
    "database_connection": "healthy",
    "storage_access": "critical",
    "ai_generation": "warning",
    "weather_api": "critical"
  },
  "timestamp": "2025-07-23T12:00:00Z"
}
```

---

## 📊 Database REST API

### User Preferences

#### Get User Preferences
```http
GET /rest/v1/user_preferences?user_id=eq.{user_id}
Authorization: Bearer {access_token}
```

**Response** `200 OK`:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "timezone": "America/Los_Angeles",
  "location_zip": "90210",
  "name": "John",
  "city": "Beverly Hills",
  "state": "CA",
  "voice": "voice_1",
  "created_at": "2025-07-23T10:00:00Z",
  "updated_at": "2025-07-23T10:00:00Z"
}
```

#### Update User Preferences
```http
PATCH /rest/v1/user_preferences?user_id=eq.{user_id}
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "voice": "voice_2",
  "name": "John",
  "city": "Beverly Hills",
  "state": "CA"
}
```

**Response** `200 OK`: Returns updated preferences

### Content Blocks

#### Get Content Block
```http
GET /rest/v1/content_blocks?user_id=eq.{user_id}&date=eq.{date}&content_type=eq.banana
Authorization: Bearer {access_token}
```

**Response** `200 OK`:
```json
[
  {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "user_id": "550e8400-e29b-41d4-a716-446655440000",
    "content_type": "banana",
    "date": "2025-07-24",
    "content": "{\"user_name\":\"John\",\"city\":\"Beverly Hills\",\"state\":\"CA\",\"weather\":{\"temperature\":72,\"condition\":\"sunny\"},\"headlines\":{\"business\":\"Business news\",\"political\":\"Political news\",\"popCulture\":\"Entertainment news\"},\"markets\":{\"summary\":\"Markets are moving\",\"trend\":\"up\",\"keyMovers\":[]},\"day_of_week\":\"Thursday\",\"date\":\"2025-07-24\"}",
    "script": "It's Thursday, July twenty-fourth. Good morning John! It's going to be a beautiful day...",
    "audio_url": "https://[PROJECT_REF].supabase.co/storage/v1/object/public/audio-files/banana/123e4567_voice_1_1721736000.aac",
    "status": "script_generated",
    "voice": "voice_1",
    "duration_seconds": 95,
    "audio_duration": 95,
    "retry_count": 0,
    "content_priority": 1,
    "expiration_date": "2025-07-27",
    "language_code": "en-US",
    "parameters": {
      "user_name": "John",
      "city": "Beverly Hills",
      "state": "CA",
      "weather": {
        "temperature": 72,
        "condition": "sunny"
      },
      "headlines": {
        "business": "Business news",
        "political": "Political news",
        "popCulture": "Entertainment news"
      },
      "markets": {
        "summary": "Markets are moving",
        "trend": "up",
        "keyMovers": []
      }
    },
    "created_at": "2025-07-24T02:00:00Z",
    "updated_at": "2025-07-24T02:02:00Z",
    "script_generated_at": "2025-07-24T02:02:00Z",
    "audio_generated_at": null
  }
]
```

#### Get Shared Content
```http
GET /rest/v1/content_blocks?user_id=is.null&date=eq.{date}&content_type=eq.{type}
Authorization: Bearer {access_token}
```

**Content Types**: `weather`, `headlines`, `markets`, `sports`, `encouragement`

### Weather Data

#### Push Weather Data
```http
POST /rest/v1/user_weather_data
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "location_key": "90210",
  "date": "2025-07-24",
  "weather_data": {
    "location": {
      "latitude": 34.0901,
      "longitude": -118.4065
    },
    "current": {
      "temperature": 72,
      "condition": "Sunny",
      "humidity": 45,
      "wind_speed": 5.2
    },
    "forecast": {
      "high": 78,
      "low": 65,
      "summary": "Sunny with light clouds in the afternoon"
    }
  },
  "expires_at": "2025-07-24T13:00:00Z",
  "last_updated": "2025-07-24T12:00:00Z"
}
```

**Response** `201 Created`

### Logs

#### Create Log Entry
```http
POST /rest/v1/logs
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "event_type": "alarm_fired",
  "status": "success",
  "message": "AI wake-up alarm triggered successfully",
  "metadata": {
    "alarm_id": "alarm_123",
    "audio_duration": 95,
    "playback_success": true
  },
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response** `201 Created`

---

## 🔄 Real-time Subscriptions

### Content Generation Updates
```javascript
// Subscribe to content generation status
const subscription = supabase
  .channel('content-generation')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'content_blocks',
      filter: `user_id=eq.${userId}&date=eq.${tomorrow}`
    },
    (payload) => {
      if (payload.new.status === 'ready' || payload.new.status === 'content_ready') {
        // Content is ready, update UI
      }
    }
  )
  .subscribe()
```

---

## 🛡️ Error Handling

### Standard Error Response
All endpoints return errors in this format:

```json
{
  "success": false,
  "error": "Error message description"
}
```

### Common Error Codes
| Code | HTTP Status | Description |
|------|-------------|-------------|
| `unauthorized` | 401 | Invalid or expired authentication |
| `forbidden` | 403 | Insufficient permissions |
| `not_found` | 404 | Resource not found |
| `rate_limit_exceeded` | 429 | Too many requests |
| `invalid_request` | 400 | Malformed request data |
| `server_error` | 500 | Internal server error |
| `service_unavailable` | 503 | Temporary service outage |

---

## 🔒 Security Headers

All requests must include:
```http
Authorization: Bearer {access_token}
X-Client-Version: 1.0.0
X-Device-Model: iPhone16,1
X-Operating-System: iOS 26.0
```

---

## 📈 Rate Limiting

### Endpoint Limits
| Endpoint | Limit | Window |
|----------|-------|--------|
| Authentication | 5 requests | 15 minutes |
| AI Content Generation | 3 requests | 24 hours |
| Database Reads | 1000 requests | Hour |
| Database Writes | 100 requests | Hour |

### Rate Limit Headers
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1721739600
```

---

## 🔄 Retry Strategy

### Recommended Retry Logic
```swift
func executeWithRetry<T>(
    request: URLRequest,
    maxRetries: Int = 3
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            lastError = error
            
            // Don't retry client errors
            if let httpResponse = (error as? URLError)?.response as? HTTPURLResponse,
               (400..<500).contains(httpResponse.statusCode) {
                throw error
            }
            
            // Exponential backoff
            let delay = pow(2.0, Double(attempt))
            try await Task.sleep(for: .seconds(delay))
        }
    }
    
    throw lastError ?? URLError(.unknown)
}
```

---

## 📦 Pagination

### List Endpoints
```http
GET /rest/v1/content_blocks?limit=20&offset=0&order=created_at.desc
```

**Headers**:
```http
Content-Range: 0-19/45
```

**Response includes**:
```json
{
  "data": [...],
  "count": 45,
  "has_more": true,
  "next_offset": 20
}
```

---

## 🧪 Testing Endpoints

### Test User
```http
POST /functions/v1/test-user
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response** `200 OK`:
```json
{
  "success": true,
  "message": "User test completed",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Test User Preferences
```http
POST /functions/v1/test-user-preferences
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response** `200 OK`:
```json
{
  "success": true,
  "message": "User preferences test completed",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Test User Weather Data
```http
POST /functions/v1/test-user-weather-data
Authorization: Bearer {access_token}
```

**Request Body**:
```json
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Response** `200 OK`:
```json
{
  "success": true,
  "message": "User weather data test completed",
  "user_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## 📝 API Versioning

- Current version: `v1`
- Version included in URL path
- Breaking changes require new version
- Deprecated endpoints supported for 6 months
- Version sunset notices sent via email

---

## 🔍 API Discovery

### Get API Capabilities
```http
GET /functions/v1/health-check
```

**Response** `200 OK`:
```json
{
  "success": true,
  "overall_status": "healthy",
  "passed_checks": 8,
  "failed_checks": 0,
  "total_checks": 8,
  "checks": {
    "database_connection": "healthy",
    "storage_access": "healthy",
    "ai_generation": "healthy",
    "weather_api": "healthy"
  },
  "timestamp": "2025-07-23T12:00:00Z"
}
```

---

This API specification provides a complete reference for all backend interactions in Banana Clock, ensuring consistent and reliable communication between the iOS app and Supabase backend.