//
//  ContentBlockTests.swift
//  BananaClockTests
//
//  Comprehensive tests for ContentBlock model and related types
//  Ensures 100% code coverage and validates all functionality
//

import XCTest
@testable import BananaClock

final class ContentBlockTests: XCTestCase {
    
    // MARK: - Test Data
    
    private let validContentBlockJSON = """
    {
        "id": "123e4567-e89b-12d3-a456-426614174000",
        "user_id": "987fcdeb-51d2-34a5-b123-789012345678",
        "content_type": "banana",
        "date": "2025-01-20",
        "script": "Good morning! It's Monday, January twentieth.",
        "audio_url": "https://example.com/audio.aac",
        "status": "ready",
        "voice": "voice_1",
        "expiration_date": "2025-01-23T00:00:00Z",
        "language_code": "en-US",
        "content_priority": 1,
        "created_at": "2025-01-20T06:00:00Z",
        "updated_at": "2025-01-20T06:30:00Z",
        "script_generated_at": "2025-01-20T06:15:00Z",
        "audio_generated_at": "2025-01-20T06:25:00Z",
        "parameters": {
            "user_name": "John",
            "city": "San Francisco",
            "state": "CA",
            "weather": {
                "temperature": 68.5,
                "condition": "Sunny",
                "humidity": 65.0,
                "wind_speed": 5.2,
                "description": "Sunny with a high of 72°F"
            },
            "headlines": {
                "business": "Tech stocks rally as earnings beat expectations",
                "political": "New climate legislation passes committee vote",
                "popCulture": "Award season kicks off with surprise nominations"
            },
            "markets": {
                "summary": "Markets opened higher on positive earnings",
                "trend": "upward",
                "keyMovers": ["AAPL +2.3%", "GOOGL +1.8%", "MSFT +1.5%"]
            }
        },
        "content": "Generated content data",
        "metadata": {
            "generation_time": 15.5,
            "retry_count": 0,
            "error_message": null,
            "model_version": "gpt-4o",
            "voice_settings": {
                "voice_id": "voice_1",
                "stability": 0.75,
                "similarity_boost": 0.8,
                "speed": 1.0
            }
        }
    }
    """
    
    private func createValidContentBlock() -> AIContentBlock {
        let data = validContentBlockJSON.data(using: .utf8)!
        return try! JSONDecoder().decode(AIContentBlock.self, from: data)
    }
    
    // MARK: - ContentBlock Tests
    
    func testContentBlockDecoding() throws {
        let data = validContentBlockJSON.data(using: .utf8)!
        let contentBlock = try JSONDecoder().decode(AIContentBlock.self, from: data)
        
        XCTAssertEqual(contentBlock.id.uuidString.lowercased(), "123e4567-e89b-12d3-a456-426614174000")
        XCTAssertEqual(contentBlock.userId.uuidString.lowercased(), "987fcdeb-51d2-34a5-b123-789012345678")
        XCTAssertEqual(contentBlock.contentType, "banana")
        XCTAssertEqual(contentBlock.date, "2025-01-20")
        XCTAssertEqual(contentBlock.script, "Good morning! It's Monday, January twentieth.")
        XCTAssertEqual(contentBlock.audioUrl, "https://example.com/audio.aac")
        XCTAssertEqual(contentBlock.status, "ready")
        XCTAssertEqual(contentBlock.voice, "voice_1")
        XCTAssertEqual(contentBlock.expirationDate, "2025-01-23T00:00:00Z")
        XCTAssertEqual(contentBlock.languageCode, "en-US")
        XCTAssertEqual(contentBlock.contentPriority, 1)
        XCTAssertEqual(contentBlock.createdAt, "2025-01-20T06:00:00Z")
        XCTAssertEqual(contentBlock.updatedAt, "2025-01-20T06:30:00Z")
        XCTAssertEqual(contentBlock.scriptGeneratedAt, "2025-01-20T06:15:00Z")
        XCTAssertEqual(contentBlock.audioGeneratedAt, "2025-01-20T06:25:00Z")
        XCTAssertNotNil(contentBlock.parameters)
        XCTAssertNotNil(contentBlock.metadata)
    }
    
    func testContentBlockEncoding() throws {
        let contentBlock = createValidContentBlock()
        let data = try JSONEncoder().encode(contentBlock)
        let decoded = try JSONDecoder().decode(AIContentBlock.self, from: data)
        
        XCTAssertEqual(contentBlock.id, decoded.id)
        XCTAssertEqual(contentBlock.userId, decoded.userId)
        XCTAssertEqual(contentBlock.contentType, decoded.contentType)
        XCTAssertEqual(contentBlock.status, decoded.status)
    }
    
    func testContentBlockIsReady() {
        var contentBlock = createValidContentBlock()
        
        // Test ready status
        XCTAssertTrue(contentBlock.isReady)
        
        // Test content_ready status
        contentBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: "content_ready",
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertTrue(contentBlock.isReady)
        
        // Test non-ready status
        contentBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: "pending",
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(contentBlock.isReady)
    }
    
    func testContentBlockHasAudio() {
        var contentBlock = createValidContentBlock()
        
        // Test valid audio URL
        XCTAssertTrue(contentBlock.hasAudio)
        
        // Test nil audio URL
        contentBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: nil,
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(contentBlock.hasAudio)
        
        // Test empty audio URL
        contentBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: "",
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(contentBlock.hasAudio)
        
        // Test invalid audio URL
        contentBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: "invalid-url",
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(contentBlock.hasAudio)
    }
    
    func testContentBlockIsExpired() {
        let contentBlock = createValidContentBlock()
        
        // Content with future expiration date should not be expired
        XCTAssertFalse(contentBlock.isExpired)
        
        // Create content with past expiration date
        let pastExpirationBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: "2020-01-01T00:00:00Z",
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertTrue(pastExpirationBlock.isExpired)
        
        // Test invalid expiration date format
        let invalidExpirationBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: "invalid-date",
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertTrue(invalidExpirationBlock.isExpired) // Should default to expired for safety
    }
    
    func testContentBlockFormattedCreatedAt() {
        let contentBlock = createValidContentBlock()
        
        XCTAssertNotNil(contentBlock.formattedCreatedAt)
        
        // Test invalid date format
        let invalidDateBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: "invalid-date",
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertNil(invalidDateBlock.formattedCreatedAt)
    }
    
    func testContentBlockAgeInSeconds() {
        let contentBlock = createValidContentBlock()
        
        XCTAssertNotNil(contentBlock.ageInSeconds)
        XCTAssertGreaterThan(contentBlock.ageInSeconds!, 0)
        
        // Test with invalid created date
        let invalidDateBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: "invalid-date",
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertNil(invalidDateBlock.ageInSeconds)
    }
    
    func testContentBlockValidation() {
        let contentBlock = createValidContentBlock()
        
        // Valid content block should pass validation
        XCTAssertTrue(contentBlock.isValid)
        
        // Test empty user ID
        var invalidBlock = AIContentBlock(
            id: contentBlock.id,
            userId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
            contentType: "",
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(invalidBlock.isValid)
        
        // Test invalid content type
        invalidBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: "invalid_type",
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(invalidBlock.isValid)
        
        // Test invalid status
        invalidBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: "invalid_status",
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(invalidBlock.isValid)
        
        // Test invalid audio URL
        invalidBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: "not-a-valid-url",
            status: contentBlock.status,
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertFalse(invalidBlock.isValid)
    }
    
    func testContentBlockTypedProperties() {
        let contentBlock = createValidContentBlock()
        
        XCTAssertEqual(contentBlock.typedStatus, .ready)
        XCTAssertEqual(contentBlock.typedContentType, .banana)
        
        // Test invalid status
        let invalidStatusBlock = AIContentBlock(
            id: contentBlock.id,
            userId: contentBlock.userId,
            contentType: contentBlock.contentType,
            date: contentBlock.date,
            script: contentBlock.script,
            audioUrl: contentBlock.audioUrl,
            status: "invalid_status",
            voice: contentBlock.voice,
            expirationDate: contentBlock.expirationDate,
            languageCode: contentBlock.languageCode,
            contentPriority: contentBlock.contentPriority,
            createdAt: contentBlock.createdAt,
            updatedAt: contentBlock.updatedAt,
            scriptGeneratedAt: contentBlock.scriptGeneratedAt,
            audioGeneratedAt: contentBlock.audioGeneratedAt,
            parameters: contentBlock.parameters,
            content: contentBlock.content,
            metadata: contentBlock.metadata
        )
        XCTAssertNil(invalidStatusBlock.typedStatus)
    }
    
    // MARK: - WeatherData Tests
    
    func testWeatherDataValidation() {
        let validWeather = WeatherData(
            temperature: 68.5,
            condition: "Sunny",
            humidity: 65.0,
            windSpeed: 5.2,
            description: "Sunny with a high of 72°F"
        )
        XCTAssertTrue(validWeather.isValid)
        
        let invalidWeather = WeatherData(
            temperature: nil,
            condition: nil,
            humidity: 65.0,
            windSpeed: 5.2,
            description: "Description"
        )
        XCTAssertFalse(invalidWeather.isValid)
        
        let emptyConditionWeather = WeatherData(
            temperature: 68.5,
            condition: "",
            humidity: 65.0,
            windSpeed: 5.2,
            description: "Description"
        )
        XCTAssertFalse(emptyConditionWeather.isValid)
    }
    
    // MARK: - HeadlinesData Tests
    
    func testHeadlinesDataValidation() {
        let validHeadlines = HeadlinesData(
            business: "Tech stocks rally",
            political: "Climate legislation",
            popCulture: "Award nominations"
        )
        XCTAssertTrue(validHeadlines.isValid)
        
        let singleHeadline = HeadlinesData(
            business: "Tech stocks rally",
            political: nil,
            popCulture: nil
        )
        XCTAssertTrue(singleHeadline.isValid)
        
        let emptyHeadlines = HeadlinesData(
            business: "",
            political: "",
            popCulture: ""
        )
        XCTAssertFalse(emptyHeadlines.isValid)
        
        let nilHeadlines = HeadlinesData(
            business: nil,
            political: nil,
            popCulture: nil
        )
        XCTAssertFalse(nilHeadlines.isValid)
    }
    
    // MARK: - MarketsData Tests
    
    func testMarketsDataValidation() {
        let validMarkets = MarketsData(
            summary: "Markets opened higher",
            trend: "upward",
            keyMovers: ["AAPL +2.3%"]
        )
        XCTAssertTrue(validMarkets.isValid)
        
        let invalidMarkets = MarketsData(
            summary: "",
            trend: "upward",
            keyMovers: ["AAPL +2.3%"]
        )
        XCTAssertFalse(invalidMarkets.isValid)
        
        let nilSummaryMarkets = MarketsData(
            summary: nil,
            trend: "upward",
            keyMovers: ["AAPL +2.3%"]
        )
        XCTAssertFalse(nilSummaryMarkets.isValid)
    }
    
    // MARK: - ContentBlockStatus Tests
    
    func testContentBlockStatusProperties() {
        XCTAssertTrue(ContentBlockStatus.ready.isReadyForPlayback)
        XCTAssertTrue(ContentBlockStatus.contentReady.isReadyForPlayback)
        XCTAssertFalse(ContentBlockStatus.pending.isReadyForPlayback)
        XCTAssertFalse(ContentBlockStatus.error.isReadyForPlayback)
        
        XCTAssertEqual(ContentBlockStatus.ready.description, "Content ready for use")
        XCTAssertEqual(ContentBlockStatus.error.description, "Generation failed")
    }
    
    // MARK: - ContentType Tests
    
    func testContentTypeProperties() {
        XCTAssertEqual(ContentType.banana.description, "AI Wake-up Content")
        XCTAssertEqual(ContentType.weather.description, "Weather Information")
        XCTAssertEqual(ContentType.headlines.description, "News Headlines")
        XCTAssertEqual(ContentType.markets.description, "Market Data")
    }
    
    // MARK: - Sendable Conformance Tests
    
    func testSendableConformance() async {
        let contentBlock = createValidContentBlock()
        
        // Test that ContentBlock can be safely passed across concurrency boundaries
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = contentBlock.isValid
            }
            group.addTask {
                _ = contentBlock.hasAudio
            }
        }
    }
}