//
//  AITimezoneService.swift
//  BananaClock
//
//  AI-powered timezone recommendations using OpenAI via Supabase proxy
//

import Foundation
import Combine

@MainActor
class AITimezoneService: ObservableObject {
    @Published var currentRecommendation: String = ""
    @Published var isLoading = false
    
    private var recommendationTimer: Foundation.Timer?
    
    init() {
        // Auto-clear recommendation after 5 minutes
        startAutoClearTimer()
    }
    
    deinit {
        recommendationTimer?.invalidate()
    }
    
    func getRecommendation(for clocks: [WorldClock], selectedDate: Date) async {
        print("🍌 AI: getRecommendation called with \(clocks.count) clocks")
        print("🍌 AI: Clock details:")
        for (index, clock) in clocks.enumerated() {
            print("🍌 AI:   [\(index)] \(clock.cityName) (\(clock.timeZoneIdentifier))")
        }
        
        // Only proceed if we have multiple timezones
        guard clocks.count >= 2 else {
            print("🍌 AI: Skipping - insufficient clocks")
            return
        }
        
        // Filter out planetary clocks and get regular cities
        let regularClocks = clocks.filter { clock in
            // Check if this is a planetary clock by looking for the isPlanet property
            // Since WorldClock doesn't have isPlanet, we check the city name for planetary emojis
            !clock.cityName.contains("🧠") && !clock.cityName.contains("💖") && !clock.cityName.contains("🌍") && 
            !clock.cityName.contains("🛡️") && !clock.cityName.contains("👑") && !clock.cityName.contains("🪐") && 
            !clock.cityName.contains("🔭") && !clock.cityName.contains("🌊")
        }
        
        print("🍌 AI: \(regularClocks.count) regular clocks after filtering")
        print("🍌 AI: Regular clock details:")
        for (index, clock) in regularClocks.enumerated() {
            print("🍌 AI:   [\(index)] \(clock.cityName) (\(clock.timeZoneIdentifier))")
        }
        
        guard regularClocks.count >= 2 else { 
            print("🍌 AI: Skipping - insufficient regular clocks")
            return 
        }
        
        // Include all regular clocks without limit
        await requestRecommendation(for: regularClocks, selectedDate: selectedDate)
    }
    
    private func requestRecommendation(for clocks: [WorldClock], selectedDate: Date) async {
        print("🍌 AI: Starting request for \(clocks.count) clocks")
        isLoading = true
        
        do {
            let recommendation = try await callOpenAI(for: clocks, selectedDate: selectedDate)
            print("🍌 AI: Received recommendation: \(recommendation)")
            currentRecommendation = recommendation
        } catch {
            // Log error but don't show anything to user
            print("🍌 AI: Recommendation failed: \(error)")
        }
        
        isLoading = false
    }
    
    private func callOpenAI(for clocks: [WorldClock], selectedDate: Date) async throws -> String {
        print("🍌 AI: callOpenAI called with \(clocks.count) clocks")
        
        let userTimezone = TimeZone.current.identifier
        let userCity = TimeZone.current.localizedName(for: .generic, locale: .current) ?? "Your Location"
        
        print("🍌 AI: User timezone: \(userTimezone)")
        print("🍌 AI: User city: \(userCity)")
        
        // Build timezone list with user's timezone first
        let userClock = clocks.first { $0.timeZoneIdentifier == userTimezone }
        let otherClocks = clocks.filter { $0.timeZoneIdentifier != userTimezone }
        
        // Optional: Sort by time difference from user's timezone (closest first)
        let sortedClocks = clocks.sorted {
            abs($0.timeZone.secondsFromGMT() - TimeZone.current.secondsFromGMT()) <
            abs($1.timeZone.secondsFromGMT() - TimeZone.current.secondsFromGMT())
        }
        
        print("🍌 AI: User clock found: \(userClock?.cityName ?? "none")")
        print("🍌 AI: Other clocks count: \(otherClocks.count)")
        
        var timezoneList = ""
        // Use sorted clocks to build timezone list (user's timezone will be first if it exists)
        let timezones = sortedClocks.map { clock in
            let offset = clock.timeZone.secondsFromGMT() / 3600
            let sign = offset >= 0 ? "+" : ""
            let timezoneString = "\(clock.cityName) (UTC\(sign)\(offset))"
            print("🍌 AI: Adding clock: \(timezoneString)")
            return timezoneString
        }.joined(separator: ", ")
        timezoneList = timezones
        
        print("🍌 AI: Final timezone list: \(timezoneList)")
        
        // Format selected date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d"
        let dateString = dateFormatter.string(from: selectedDate)
        
        let userPrompt = """
        You are an executive assistant and expert timezone scheduler. You and your boss work in the reference timezone.

        Given these timezones:
        \(timezoneList)

        Reference timezone: \(userCity) (\(userTimezone))  
        Date: \(dateString)

        Find the most inclusive possible time block that includes the maximum number of cities within acceptable hours. Your boss is trying to schedule time with all of these cities as best as possible.
        - Business hours: 8 AM – 6 PM
        - Also acceptable: early (6–8 AM) and evening (6–10 PM)
        - A city is considered excluded only if the meeting falls **entirely within its overnight hours (10 PM – 6 AM)**

        The block must be at least 30 minutes long but should strive to be as long as possible. In this priority order, **prefer most inclusive and longest** block. Only choose shorter or less inclusive blocks if no better option exists.

        Use the reference timezone (\(userCity)) for all output times.

        Output exactly two lines:  
        The best meeting time block (e.g., "6:00 AM – 9:00 AM Pacific Time")  
        Who is excluded or partially excluded, or say "All cities included."

        Do not explain your reasoning. Just give the result.

        Before finalizing your answer, double-check the local time for each city. If a city is even partially within 6 AM to 10 PM local time, it is not excluded.
        """
        
        let systemPrompt = "You are a helpful timezone meeting scheduler. Be concise and practical."
        
        // Debug: Log what timezones are being sent to GPT
        print("🍌 AI: Sending timezones to GPT: \(timezoneList)")
        print("🍌 AI: Full prompt: \(userPrompt)")
        
        // Use the OpenAI service instead of direct API calls
        do {
            let response = try await OpenAIService.shared.generateText(
                prompt: userPrompt,
                systemPrompt: systemPrompt,
                model: "gpt-4",
                temperature: 0.2,
                maxTokens: 600
            )
            
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            print("🍌 AI: OpenAI service error: \(error)")
            throw AIError.apiError
        }
    }
    
    private func startAutoClearTimer() {
        recommendationTimer?.invalidate()
        recommendationTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { _ in
            Task { @MainActor in
                self.currentRecommendation = ""
            }
        }
    }
    
    func clearRecommendation() {
        currentRecommendation = ""
        recommendationTimer?.invalidate()
    }
}

enum AIError: Error {
    case invalidURL
    case apiError
    case invalidResponse
} 