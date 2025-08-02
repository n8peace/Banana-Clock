//
//  WorldClockView.swift
//  BananaClock
//
//  World clock feature
//

import SwiftUI
import UIKit
import Foundation
import Combine

struct WorldClockView: View {
    @StateObject private var viewModel = WorldClockViewModel()
    @State private var showingAddCity = false
    @State private var isEditing = false
    @State private var showConfetti = false
    @State private var showGoldenGlow = false
    @State private var showingCalendar = false
    @State private var glowAnimation = false
    
    var body: some View {
        ZStack {
            // Base black background (foundation layer)
            Color.black.ignoresSafeArea()
            
            // Enhanced Sunrise Glow - Inspired by Apple Health
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.60),   // Soft banana yellow
                    Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.50),   // Tangerine orange
                    Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.40),   // Warm coral red
                    Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.30),   // Soft lavender for depth
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.5, y: 0.3)
            )
            .blur(radius: 40)
            .ignoresSafeArea()
            .blendMode(.screen)
            .opacity(glowAnimation ? 1.0 : 0.70)
            .animation(.easeInOut(duration: 4), value: glowAnimation)
            
            // Radial gradient behind time display
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.35),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 200
            )
            .frame(height: 300)
            .frame(maxHeight: .infinity, alignment: .top)
            .blur(radius: 20)
            .blendMode(.screen)
            
            VStack(spacing: 0) {
                // Fixed user time section at top
                if let currentClock = viewModel.currentTimezoneClock {
                    VStack(spacing: 0) {
                        // User's time - sticky at top
                        WorldClockRow(clock: currentClock, viewModel: viewModel)
                    }
                    .background(.ultraThinMaterial.opacity(0.1))
                }
                
                NavigationStack {
                    // Scrollable content for other timezones
                    if viewModel.otherClocks.isEmpty {
                        emptyStateView()
                            .frame(maxWidth: .infinity, minHeight: 400)
                    } else {
                        clocksList
                    }
                }
                .navigationTitle(dynamicTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
            }
            
            // Floating elements positioned at bottom
            VStack {
                Spacer()
                
                // Timezone converter (when multiple clocks exist and not in edit mode)
                if viewModel.clocks.count >= 2 && !isEditing {
                    timezoneConverterView
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.backgroundSecondary.opacity(0.95))
                        )
                        .padding(.horizontal, BSpacing.md)
                        .padding(.bottom, BSpacing.md)
                }
                
                // Selection mode action bar
                if isEditing && !viewModel.selectableClocks.isEmpty {
                    HStack(spacing: 16) {
                        Button {
                            if viewModel.selectedClocksCount == viewModel.selectableClocks.count {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll()
                            }
                        } label: {
                            Text(viewModel.selectedClocksCount == viewModel.selectableClocks.count ? "Deselect All" : "Select All")
                                .font(.body.weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(BananaTheme.Colors.backgroundSecondary)
                                .cornerRadius(BananaTheme.Layout.cornerRadius)
                        }
                        
                        if viewModel.selectedClocksCount > 0 {
                            Button {
                                viewModel.deleteSelectedClocks()
                            } label: {
                                Text("Delete Selected (\(viewModel.selectedClocksCount))")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(BananaTheme.Colors.error)
                                    .cornerRadius(BananaTheme.Layout.cornerRadius)
                            }
                        }
                    }
                    .padding(.horizontal, BSpacing.md)
                    .padding(.bottom, BSpacing.md)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .background(Color.clear)
            
            // Calendar overlay with dismiss background
            if viewModel.clocks.count >= 2 && !isEditing && showingCalendar {
                ZStack {
                    // Full screen tap to dismiss
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showingCalendar = false
                            }
                        }
                    
                    // Calendar positioned at bottom - no tap gestures
                    VStack {
                        Spacer()
                        
                            NativeCalendarView(selectedDate: $viewModel.selectedDate)
        .frame(maxWidth: UIScreen.main.bounds.width - 2 * BSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.backgroundSecondary.opacity(0.95))
        )
        .padding(.horizontal, BSpacing.md)
        .padding(.bottom, 200) // Position above converter
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity
                ))
            }
        }
        .sheet(isPresented: $showingAddCity) {
            CityPickerView { city in
                viewModel.addClock(for: city)
            }
        }
        .onDisappear {
            // Reset date to today when leaving the page
            viewModel.selectedDate = Date()
            // Clear AI recommendation when leaving the page
            viewModel.aiService.clearRecommendation()
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                // Clear selection when exiting edit mode
                viewModel.deselectAll()
            }
        }
        .onAppear {
            glowAnimation = true
        }
    }
    

    // MARK: - Dynamic Title Properties
    
    private var dynamicTitle: String {
        // Use the viewModel's navigationTitle property which already handles planetary clock detection
        return viewModel.navigationTitle
    }
    

    
    // MARK: - Views
    
    private var timezoneConverterView: some View {
        VStack(spacing: 12) {
            // Title and countdown row
            HStack {
                Text("🍌🧠 Timezone Converter")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Countdown circle on the right (when active)
                if viewModel.isConverterActive && viewModel.countdownSeconds > 0 {
                    Button {
                        viewModel.endConverterMode()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            
                            Circle()
                                .trim(from: 0, to: viewModel.countdownProgress)
                                .stroke(Color.gray, lineWidth: 2)
                                .frame(width: 24, height: 24)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(viewModel.countdownSeconds)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Custom date picker
            CustomDatePicker(selectedDate: $viewModel.selectedDate, showingCalendar: $showingCalendar)
            
            // Slider
            Slider(
                value: $viewModel.timeSliderValue,
                in: 0...1,
                step: 1.0/96 // 15-minute intervals (24 hours * 4 intervals per hour)
            ) { editing in
                viewModel.handleSliderEditing(editing)
            }
            .accentColor(viewModel.isConverterActive ? BananaTheme.Colors.bananaYellow : .gray)
            
            // AI Recommendation row
            if !viewModel.aiRecommendation.isEmpty {
                Text(viewModel.aiRecommendation)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(BananaTheme.Spacing.md)
        .background(BananaTheme.Colors.backgroundSecondary)
        .cornerRadius(BananaTheme.Layout.cornerRadius)
        .goldenGlow(isActive: showGoldenGlow)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isConverterActive)
        .overlay(
            // Confetti overlay positioned at top
            BananaConfettiView(
                isActive: showConfetti,
                sourceRect: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 32, height: 100)
            )
            .allowsHitTesting(false),
            alignment: .top
        )
        .onChange(of: viewModel.aiRecommendation) { oldValue, newValue in
            // Trigger confetti every time AI recommendation changes (not just empty to non-empty)
            if !newValue.isEmpty && oldValue != newValue {
                triggerConfettiEffect()
            }
        }
    }
    
    // MARK: - Confetti Effect
    
    private func triggerConfettiEffect() {
        // Reset first to ensure clean trigger
        showConfetti = false
        showGoldenGlow = false
        
        // Small delay then trigger both effects
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            showConfetti = true
            showGoldenGlow = true
        }
        
        // Reset confetti after particles fall off screen (6 seconds is enough for single burst)
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            showConfetti = false
        }
        
        // Reset glow after shorter duration
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showGoldenGlow = false
        }
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: BananaTheme.Spacing.lg) {
            Image(systemName: "globe")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No World Clocks")
                .font(.title2)
                .foregroundColor(.white)
            
            (Text("Add cities to track and convert time around the ")
                .font(.body)
                .foregroundColor(.gray) +
             Text("world")
                .font(.body)
                .foregroundColor(.gray)
                .strikethrough() +
             Text(" universe.")
                .font(.body)
                .foregroundColor(.gray))
                .multilineTextAlignment(.center)
            
            // Quick presets
            VStack(spacing: BananaTheme.Spacing.md) {
                HStack(spacing: BananaTheme.Spacing.md) {
                    ForEach(WorldClockPreset.defaults, id: \.city.timeZoneIdentifier) { preset in
                        Button {
                            viewModel.addClock(for: preset.city)
                        } label: {
                            Text(preset.label)
                                .font(.title3.weight(.medium))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, BananaTheme.Spacing.md)
                                .background(BananaTheme.Colors.backgroundSecondary)
                                .cornerRadius(BananaTheme.Layout.cornerRadius)
                        }
                    }
                }
            }
            
            BananaButton("Add City", icon: "plus") {
                showingAddCity = true
            }
            .frame(width: 200)
        }
        .padding()
    }
    
    private var clocksList: some View {
        List {
            ForEach(viewModel.otherClocks) { clock in
                WorldClockRow(
                    clock: clock, 
                    viewModel: viewModel,
                    onTap: {
                        if isEditing {
                            // In edit mode, toggle selection instead of doing nothing
                            viewModel.toggleSelection(for: clock)
                        }
                    },
                    isSelected: viewModel.isSelected(clock),
                    showSelection: isEditing
                )
                .onLongPressGesture {
                    if !isEditing {
                        withAnimation {
                            isEditing = true
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            .onDelete { indexSet in
                viewModel.deleteClocks(at: indexSet)
            }
            
            // Transparent spacer to create blank space at bottom
            Color.clear
                .frame(height: viewModel.clocks.count >= 2 ? 200 : 60)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !viewModel.selectableClocks.isEmpty {
                Button {
                    withAnimation {
                        isEditing.toggle()
                    }
                } label: {
                    if isEditing {
                        Image(systemName: "checkmark")
                            .foregroundColor(BananaTheme.Colors.bananaYellow)
                    } else {
                        Text("Edit")
                            .foregroundColor(BananaTheme.Colors.bananaYellow)
                    }
                }
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            if !isEditing {
                Button {
                    showingAddCity = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
            }
        }
    }
}

// MARK: - World Clock Row
struct WorldClockRow: View {
    let clock: WorldClock
    @ObservedObject var viewModel: WorldClockViewModel
    let onTap: () -> Void
    let isSelected: Bool
    let showSelection: Bool
    
    init(
        clock: WorldClock,
        viewModel: WorldClockViewModel,
        onTap: @escaping () -> Void = {},
        isSelected: Bool = false,
        showSelection: Bool = false
    ) {
        self.clock = clock
        self.viewModel = viewModel
        self.onTap = onTap
        self.isSelected = isSelected
        self.showSelection = showSelection
    }
    
    var body: some View {
        HStack {
            // Selection checkbox (only shown in edit mode)
            if showSelection {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? BananaTheme.Colors.bananaYellow : BananaTheme.Colors.textSecondary)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(clock.cityName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(offsetDescription)
                    .font(.caption)
                    .foregroundColor(BananaTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(timeString)
                    .font(.system(size: 32, weight: .light, design: .rounded))
                    .foregroundColor(timeColor)
                    .monospacedDigit()
                
                Text(dateString)
                    .font(.caption)
                    .foregroundColor(BananaTheme.Colors.textSecondary)
            }
        }
        .padding(.horizontal, BananaTheme.Spacing.md)
        .padding(.vertical, BananaTheme.Spacing.sm)
        .onTapGesture {
            onTap()
        }
    }
    
    private var timeString: String {
        if clock.cityName.contains("🧠") || clock.cityName.contains("💖") || clock.cityName.contains("🌍") || 
           clock.cityName.contains("🛡️") || clock.cityName.contains("👑") || clock.cityName.contains("🪐") || 
           clock.cityName.contains("🔭") || clock.cityName.contains("🌊") {
            // Planetary time with dynamic seconds
            return PlanetaryTimeCalculator.calculatePlanetaryTimeString(for: City(
                name: clock.cityName,
                country: "Solar System",
                timeZoneIdentifier: clock.timeZoneIdentifier,
                isPlanet: true
            ))
        } else {
            // Use converter time only when converter is active, otherwise current time
            let baseTime = viewModel.isConverterActive ? viewModel.converterTime : viewModel.currentTime
            let formatter = DateFormatter()
            
            // Check if this is the current timezone (user's time)
            let isCurrentTimezone = clock.timeZoneIdentifier == TimeZone.current.identifier
            
            if isCurrentTimezone {
                // Keep seconds for user's time
                formatter.timeStyle = .medium
            } else {
                // Remove seconds for additional world clocks
                formatter.timeStyle = .short
            }
            
            formatter.timeZone = clock.timeZone
            return formatter.string(from: baseTime)
        }
    }
    
    private var dateString: String {
        if clock.cityName.contains("💖") || clock.cityName.contains("🌍") || 
           clock.cityName.contains("🛡️") || clock.cityName.contains("👑") || clock.cityName.contains("🪐") || 
           clock.cityName.contains("🔭") || clock.cityName.contains("🌊") {
            // Planetary time - show "Planetary Time" instead of date
            return "Planetary Time"
        } else {
            // Use converter date only when converter is active, otherwise current date
            let baseTime = viewModel.isConverterActive ? viewModel.converterTime : viewModel.currentTime
            
            // Check for holiday when converter is active
            if viewModel.isConverterActive {
                let city = City(name: clock.cityName, country: getCountryForCity(clock.cityName), timeZoneIdentifier: clock.timeZoneIdentifier, isPlanet: false)
                if let holidayText = EnhancedHolidayDatabase.getHolidayTextForDate(for: city, date: baseTime) {
                    return holidayText
                }
            } else {
                // Check for holiday in current time (non-converter mode)
                let city = City(name: clock.cityName, country: getCountryForCity(clock.cityName), timeZoneIdentifier: clock.timeZoneIdentifier, isPlanet: false)
                if let holidayText = EnhancedHolidayDatabase.getHolidayText(for: city) {
                    return holidayText
                }
            }
            
            // Check if this is the current timezone (user's time)
            let isCurrentTimezone = clock.timeZoneIdentifier == TimeZone.current.identifier
            
            if isCurrentTimezone {
                // Keep full date for user's time
                let formatter = DateFormatter()
                formatter.dateFormat = "E, MMM d"
                formatter.timeZone = clock.timeZone
                return formatter.string(from: baseTime)
            } else {
                // Show "Today", "Tomorrow", "Yesterday", or date for additional world clocks
                let calendar = Calendar.current
                let userToday = Date() // User's current date
                let userTodayDate = calendar.startOfDay(for: userToday)
                
                // Get the actual time in the clock's timezone
                let formatter = DateFormatter()
                formatter.timeZone = clock.timeZone
                formatter.dateFormat = "yyyy-MM-dd"
                let clockTimeInClockTimezone = formatter.string(from: baseTime)
                
                // Convert that to a date in the user's timezone for comparison
                let userFormatter = DateFormatter()
                userFormatter.timeZone = TimeZone.current
                userFormatter.dateFormat = "yyyy-MM-dd"
                let clockDateInUserTimezone = userFormatter.date(from: clockTimeInClockTimezone) ?? userTodayDate
                let clockDateStartOfDay = calendar.startOfDay(for: clockDateInUserTimezone)
                
                let daysDifference = calendar.dateComponents([.day], from: userTodayDate, to: clockDateStartOfDay).day ?? 0
                
                switch daysDifference {
                case -1:
                    return "Yesterday"
                case 0:
                    return "Today"
                case 1:
                    return "Tomorrow"
                default:
                    // For dates beyond yesterday/tomorrow, show the date
                    let dateFormatter = DateFormatter()
                    
                    // Check if the date is in a different year
                    let calendar = Calendar.current
                    let currentYear = calendar.component(.year, from: Date())
                    let targetYear = calendar.component(.year, from: baseTime)
                    
                    if targetYear != currentYear {
                        // Include year when date is not in current year
                        dateFormatter.dateFormat = "E, MMM d, yyyy"
                    } else {
                        dateFormatter.dateFormat = "E, MMM d"
                    }
                    
                    dateFormatter.timeZone = clock.timeZone
                    return dateFormatter.string(from: baseTime)
                }
            }
        }
    }
    
    private func getCountryForCity(_ cityName: String) -> String {
        // Map city names to countries for holiday detection
        let cityCountryMap: [String: String] = [
            // United States
            "New York": "United States", "Boston": "United States", "Philadelphia": "United States",
            "Los Angeles": "United States", "San Francisco": "United States", "Seattle": "United States",
            "Chicago": "United States", "Houston": "United States", "Dallas": "United States",
            "Denver": "United States", "Phoenix": "United States", "Anchorage": "United States",
            "Honolulu": "United States",
            
            // United Kingdom
            "London": "United Kingdom", "Manchester": "United Kingdom", "Birmingham": "United Kingdom",
            
            // Canada
            "Toronto": "Canada", "Montreal": "Canada", "Ottawa": "Canada", "Vancouver": "Canada",
            "Calgary": "Canada", "Edmonton": "Canada",
            
            // Mexico
            "Mexico City": "Mexico", "Guadalajara": "Mexico", "Monterrey": "Mexico",
            
            // Australia
            "Sydney": "Australia", "Melbourne": "Australia", "Brisbane": "Australia",
            "Perth": "Australia", "Adelaide": "Australia", "Darwin": "Australia",
            
            // Japan
            "Tokyo": "Japan", "Osaka": "Japan", "Nagoya": "Japan",
            
            // Germany
            "Berlin": "Germany", "Munich": "Germany", "Hamburg": "Germany",
            
            // France
            "Paris": "France", "Lyon": "France", "Marseille": "France",
            
            // India
            "Mumbai": "India", "New Delhi": "India", "Kolkata": "India",
            "Chennai": "India", "Bangalore": "India", "Hyderabad": "India",
            
            // China
            "Beijing": "China", "Shanghai": "China", "Guangzhou": "China",
            "Hong Kong": "China",
            
            // Brazil
            "São Paulo": "Brazil", "Rio de Janeiro": "Brazil", "Brasília": "Brazil",
            
            // South Africa
            "Johannesburg": "South Africa", "Cape Town": "South Africa", "Durban": "South Africa",
            
            // Singapore
            "Singapore": "Singapore",
            
            // Malaysia
            "Kuala Lumpur": "Malaysia", "Penang": "Malaysia", "Johor Bahru": "Malaysia",
            
            // Saudi Arabia
            "Riyadh": "Saudi Arabia", "Jeddah": "Saudi Arabia", "Mecca": "Saudi Arabia",
            
            // UAE
            "Abu Dhabi": "UAE", "Dubai": "UAE", "Sharjah": "UAE",
            
            // Qatar
            "Doha": "Qatar",
            
            // Israel
            "Jerusalem": "Israel", "Tel Aviv": "Israel", "Haifa": "Israel",
            
            // Sri Lanka
            "Colombo": "Sri Lanka", "Kandy": "Sri Lanka", "Galle": "Sri Lanka",
            
            // Thailand
            "Bangkok": "Thailand", "Chiang Mai": "Thailand", "Phuket": "Thailand"
        ]
        
        return cityCountryMap[cityName] ?? "Unknown"
    }
    
    private var isCurrentTimezone: Bool {
        clock.timeZoneIdentifier == TimeZone.current.identifier
    }
    
    private var offsetDescription: String {
        if clock.cityName.contains("🧠") || clock.cityName.contains("💖") || clock.cityName.contains("🌍") || 
           clock.cityName.contains("🛡️") || clock.cityName.contains("👑") || clock.cityName.contains("🪐") || 
           clock.cityName.contains("🔭") || clock.cityName.contains("🌊") {
            // Planetary time - show day length
            let dayLengths: [String: String] = [
                "Mercury 🧠": "58.6 Earth days",
                "Venus 💖": "243 Earth days",
                "Earth 🌍": "24.0 hours",
                "Mars 🛡️": "24.6 hours",
                "Jupiter 👑": "9.9 hours",
                "Saturn 🪐": "10.7 hours",
                "Uranus 🔭": "17.2 hours",
                "Neptune 🌊": "16.1 hours"
            ]
            return dayLengths[clock.cityName] ?? "Planetary Time"
        } else {
            // Regular city offset - show timezone name and relative offset to user's timezone
            if clock.timeZoneIdentifier == TimeZone.current.identifier {
                let userOffset = TimeZone.current.secondsFromGMT()
                let userHours = userOffset / 3600
                let userSign = userHours >= 0 ? "+" : ""
                return "Your Time, UTC\(userSign)\(userHours)"
            } else {
                // Calculate relative offset to user's timezone
                let clockOffset = clock.timeZone.secondsFromGMT()
                let userOffset = TimeZone.current.secondsFromGMT()
                let relativeOffset = clockOffset - userOffset
                let relativeHours = relativeOffset / 3600
                
                if relativeHours == 0 {
                    return "Same time"
                } else {
                    let sign = relativeHours > 0 ? "+" : ""
                    let timezoneName = getTimezoneName(for: clock.timeZone)
                    return "\(timezoneName), \(sign)\(relativeHours) HRS"
                }
            }
        }
    }
    
    private func getTimezoneName(for timeZone: TimeZone) -> String {
        // Map common timezone identifiers to friendly names
        let timezoneNames: [String: String] = [
            "America/New_York": "Eastern Time",
            "America/Chicago": "Central Time", 
            "America/Denver": "Mountain Time",
            "America/Los_Angeles": "Pacific Time",
            "America/Phoenix": "Mountain Time",
            "America/Anchorage": "Alaska Time",
            "Pacific/Honolulu": "Hawaii Time",
            "America/Toronto": "Eastern Time",
            "America/Vancouver": "Pacific Time",
            "America/Edmonton": "Mountain Time",
            "America/Mexico_City": "Central Time",
            "America/Sao_Paulo": "Brasília Time",
            "America/Argentina/Buenos_Aires": "Argentina Time",
            "America/Santiago": "Chile Time",
            "America/Lima": "Peru Time",
            "Europe/London": "GMT",
            "Europe/Paris": "Central European Time",
            "Europe/Berlin": "Central European Time",
            "Europe/Rome": "Central European Time",
            "Europe/Madrid": "Central European Time",
            "Europe/Amsterdam": "Central European Time",
            "Europe/Brussels": "Central European Time",
            "Europe/Vienna": "Central European Time",
            "Europe/Zurich": "Central European Time",
            "Europe/Stockholm": "Central European Time",
            "Europe/Oslo": "Central European Time",
            "Europe/Copenhagen": "Central European Time",
            "Europe/Helsinki": "Eastern European Time",
            "Europe/Warsaw": "Central European Time",
            "Europe/Prague": "Central European Time",
            "Europe/Budapest": "Central European Time",
            "Europe/Bucharest": "Eastern European Time",
            "Europe/Sofia": "Eastern European Time",
            "Europe/Athens": "Eastern European Time",
            "Europe/Istanbul": "Turkey Time",
            "Europe/Moscow": "Moscow Time",
            "Asia/Tokyo": "Japan Time",
            "Asia/Shanghai": "China Time",
            "Asia/Seoul": "Korea Time",
            "Asia/Singapore": "Singapore Time",
            "Asia/Hong_Kong": "Hong Kong Time",
            "Asia/Bangkok": "Indochina Time",
            "Asia/Jakarta": "Western Indonesia Time",
            "Asia/Kolkata": "India Time",
            "Asia/Dubai": "Gulf Time",
            "Asia/Tehran": "Iran Time",
            "Asia/Jerusalem": "Israel Time",
            "Africa/Cairo": "Eastern European Time",
            "Africa/Johannesburg": "South Africa Time",
            "Africa/Lagos": "West Africa Time",
            "Australia/Sydney": "Eastern Australia Time",
            "Australia/Melbourne": "Eastern Australia Time",
            "Australia/Perth": "Western Australia Time",
            "Pacific/Auckland": "New Zealand Time",
            "UTC": "UTC"
        ]
        
        return timezoneNames[timeZone.identifier] ?? timeZone.identifier
    }
    
    private var timeColor: Color {
        // Don't color planetary times
        if clock.cityName.contains("🧠") || clock.cityName.contains("💖") || clock.cityName.contains("🌍") || 
           clock.cityName.contains("🛡️") || clock.cityName.contains("👑") || clock.cityName.contains("🪐") || 
           clock.cityName.contains("🔭") || clock.cityName.contains("🌊") {
            return .white
        }
        
        // In realtime mode: all times are white
        if !viewModel.isConverterActive {
            return .white
        }
        
        // In converter mode: color code based on meeting time acceptability
        let baseTime = viewModel.converterTime
        let formatter = DateFormatter()
        formatter.timeZone = clock.timeZone
        formatter.dateFormat = "HH"
        let hourString = formatter.string(from: baseTime)
        let hour = Int(hourString) ?? 0
        
        // Color coding based on meeting time acceptability
        switch hour {
        case 6..<8:   // 6am-8am
            return .yellow
        case 8..<17:  // 8am-5pm
            return .green
        case 17..<22: // 5pm-10pm
            return .yellow
        default:      // 10pm-6am
            return .red
        }
    }
}



// MARK: - City Picker
struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var sortMode: SortMode = .utc
    @State private var scrollTarget: String?
    @State private var lastScrollSection: String?
    let onSelect: (City) -> Void
    
    enum SortMode: String, CaseIterable {
        case utc = "UTC +/-"
        case alphabetical = "A-Z"
    }
    
    init(onSelect: @escaping (City) -> Void) {
        self.onSelect = onSelect
        // Load the last used sort mode from UserDefaults, default to alphabetical
        let savedSortMode = UserDefaults.standard.string(forKey: "CityPickerSortMode")
        if let savedSortMode = savedSortMode, let mode = SortMode(rawValue: savedSortMode) {
            self._sortMode = State(initialValue: mode)
        } else {
            // Default to alphabetical
            self._sortMode = State(initialValue: .alphabetical)
        }
        
        // Load the last scroll section
        let savedScrollSection = UserDefaults.standard.string(forKey: "CityPickerLastScrollSection")
        self._lastScrollSection = State(initialValue: savedScrollSection)
    }
    
    private func saveLastSelectedCity(_ city: City) {
        UserDefaults.standard.set(city.name, forKey: "LastSelectedCity")
    }
    
    private var filteredCities: [City] {
        let regularCities = searchText.isEmpty ? City.popularCities : City.allCities.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
        
        // Always show planets, filter by search text if provided
        let planets = City.planets.filter { planet in
            searchText.isEmpty || planet.name.localizedCaseInsensitiveContains(searchText) ||
            planet.country.localizedCaseInsensitiveContains(searchText)
        }
        
        switch sortMode {
        case .utc:
            let sortedRegularCities = regularCities.sorted { city1, city2 in
                let offset1 = city1.timeZone.secondsFromGMT() / 3600
                let offset2 = city2.timeZone.secondsFromGMT() / 3600
                return offset1 < offset2
            }
            return sortedRegularCities + planets
        case .alphabetical:
            let sortedRegularCities = regularCities.sorted { $0.name < $1.name }
            return sortedRegularCities + planets
        }
    }
    
    private var groupedCities: [(String, [City])] {
        let regularCities = filteredCities.filter { !$0.isPlanet }
        let planets = filteredCities.filter { $0.isPlanet }
        
        var groups: [(String, [City])] = []
        
        switch sortMode {
        case .utc:
            let grouped = Dictionary(grouping: regularCities) { city in
                let offset = city.timeZone.secondsFromGMT() / 3600
                let sign = offset >= 0 ? "+" : ""
                return "\(sign)\(offset)"
            }
            groups = grouped.sorted { group1, group2 in
                let offset1 = Int(group1.key.replacingOccurrences(of: "+", with: "")) ?? 0
                let offset2 = Int(group2.key.replacingOccurrences(of: "+", with: "")) ?? 0
                return offset1 < offset2
            }
        case .alphabetical:
            let grouped = Dictionary(grouping: regularCities) { city in
                String(city.name.prefix(1).uppercased())
            }
            groups = grouped.sorted { $0.key < $1.key }
        }
        
        // Add planets at the end
        if !planets.isEmpty {
            groups.append(("🪐 Planets", planets))
        }
        
        return groups
    }
    
    private var sectionIndexTitles: [String] {
        var titles: [String] = []
        
        switch sortMode {
        case .utc:
            titles = Array(-12...14).map { offset in
                let sign = offset >= 0 ? "+" : ""
                return "\(sign)\(offset)"
            }
        case .alphabetical:
            titles = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").map(String.init)
        }
        
        // Always add planets section to index since planets are always available
        titles.append("🪐")
        
        return titles
    }
    
    private func scrollToSection(_ section: String) {
        // Check if the section exists in groupedCities
        let existingSections = groupedCities.map { $0.0 }
        
        if existingSections.contains(section) {
            // Section exists, scroll to it
            scrollTarget = section
            // Save the scroll section for next time
            UserDefaults.standard.set(section, forKey: "CityPickerLastScrollSection")
            lastScrollSection = section
        } else {
            // Section doesn't exist, find the closest one
            let closestSection = findClosestSection(to: section, from: existingSections)
            scrollTarget = closestSection
            // Save the scroll section for next time
            UserDefaults.standard.set(closestSection, forKey: "CityPickerLastScrollSection")
            lastScrollSection = closestSection
        }
        
        HapticManager.shared.impact(.light)
    }
    
    private func findClosestSection(to targetSection: String, from existingSections: [String]) -> String {
        // Special handling for planets section
        if targetSection == "🪐" {
            return existingSections.contains("🪐 Planets") ? "🪐 Planets" : (existingSections.last ?? "")
        }
        
        switch sortMode {
        case .utc:
            // For UTC mode, find the closest offset
            guard let targetOffset = Int(targetSection.replacingOccurrences(of: "+", with: "")) else {
                return existingSections.first ?? ""
            }
            
            var closestSection = existingSections.first ?? ""
            var minDistance = Int.max
            
            for section in existingSections {
                if let sectionOffset = Int(section.replacingOccurrences(of: "+", with: "")) {
                    let distance = abs(sectionOffset - targetOffset)
                    if distance < minDistance {
                        minDistance = distance
                        closestSection = section
                    }
                }
            }
            
            return closestSection
            
        case .alphabetical:
            // For alphabetical mode, find the closest letter
            let targetLetter = targetSection.uppercased()
            
            // If target letter is before all existing sections, go to first
            if let firstSection = existingSections.first, targetLetter < firstSection {
                return firstSection
            }
            
            // If target letter is after all existing sections, go to last
            if let lastSection = existingSections.last, targetLetter > lastSection {
                return lastSection
            }
            
            // Find the closest letter
            var closestSection = existingSections.first ?? ""
            var minDistance = Int.max
            
            for section in existingSections {
                if let sectionChar = section.first, let targetChar = targetLetter.first {
                    let distance = abs(Int(sectionChar.asciiValue ?? 0) - Int(targetChar.asciiValue ?? 0))
                    if distance < minDistance {
                        minDistance = distance
                        closestSection = section
                    }
                }
            }
            
            return closestSection
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sort Mode Toggle
                    HStack(spacing: 0) {
                        // A-Z button (left)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sortMode = .alphabetical
                            }
                        } label: {
                            Text("A-Z")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(sortMode == .alphabetical ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(sortMode == .alphabetical ? BananaTheme.Colors.bananaYellow : Color.clear)
                                )
                        }
                        
                        // UTC +/- button (right)
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                sortMode = .utc
                            }
                        } label: {
                            Text("UTC +/-")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(sortMode == .utc ? .black : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(sortMode == .utc ? BananaTheme.Colors.bananaYellow : Color.clear)
                                )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    
                    // Cities List
                    ScrollViewReader { proxy in
                        List {
                            ForEach(groupedCities, id: \.0) { section, cities in
                                Section(header: 
                                    Text(section)
                                        .font(.headline)
                                        .foregroundColor(BananaTheme.Colors.bananaYellow)
                                        .textCase(nil)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.black)
                                        .id(section)
                                ) {
                                    ForEach(cities) { city in
                                        Button {
                                            saveLastSelectedCity(city)
                                            onSelect(city)
                                            dismiss()
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(city.name)
                                                        .font(.headline)
                                                        .foregroundColor(.white)
                                                    
                                                    Text(city.country)
                                                        .font(.caption)
                                                        .foregroundColor(BananaTheme.Colors.textSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Text(city.currentTimeString)
                                                    .font(.body)
                                                    .foregroundColor(BananaTheme.Colors.textSecondary)
                                                    .monospacedDigit()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.trailing, 40) // Add padding to avoid overlap with section index
                                        }
                                        .listRowBackground(Color.clear)
                                    }
                                }
                            }
                        }
                        .onChange(of: scrollTarget) { target in
                            if let target = target {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(target, anchor: .top)
                                }
                                scrollTarget = nil
                            }
                        }
                        .onChange(of: sortMode) { _, newValue in
                            // Clear the saved scroll position when sort mode changes
                            UserDefaults.standard.removeObject(forKey: "CityPickerLastScrollSection")
                            lastScrollSection = nil
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText, prompt: "Search cities")
                    .environment(\.defaultMinListRowHeight, 44)
                    .scrollIndicators(.hidden)
                    .overlay(
                        // Section Index
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                VStack(spacing: 2) {
                                    ForEach(sectionIndexTitles, id: \.self) { title in
                                        Button {
                                            scrollToSection(title)
                                        } label: {
                                            Text(title)
                                                .font(.caption2)
                                                .fontWeight(.medium)
                                                .foregroundColor(BananaTheme.Colors.bananaYellow)
                                                .frame(width: 20, height: 16)
                                        }
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.8))
                                )
                                .padding(.trailing, 8)
                            }
                            Spacer()
                        }
                    )
                }
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // Set navigation title color to white
                UINavigationBar.appearance().titleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 17, weight: .regular)
                ]
                
                // Scroll to last scroll section if available
                if let lastSection = lastScrollSection {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollTarget = lastSection
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
            }
            .onChange(of: sortMode) { _, newValue in
                // Save the sort mode to UserDefaults
                UserDefaults.standard.set(newValue.rawValue, forKey: "CityPickerSortMode")
            }
        }
    }
}

// MARK: - Models
struct WorldClock: Identifiable, Codable {
    let id: UUID
    let cityName: String
    let timeZoneIdentifier: String
    var displayOrder: Int
    let createdAt: Date
    
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
    
    init(city: City, displayOrder: Int) {
        self.id = UUID()
        self.cityName = city.name
        self.timeZoneIdentifier = city.timeZoneIdentifier
        self.displayOrder = displayOrder
        self.createdAt = Date()
    }
    
    // Memberwise initializer for Core Data reconstruction
    init(id: UUID, cityName: String, timeZoneIdentifier: String, displayOrder: Int, createdAt: Date) {
        self.id = id
        self.cityName = cityName
        self.timeZoneIdentifier = timeZoneIdentifier
        self.displayOrder = displayOrder
        self.createdAt = createdAt
    }
}

// MARK: - Holiday System
// Using EnhancedHolidayDatabase from holiday-database.swift

struct City: Identifiable {
    let id = UUID()
    let name: String
    let country: String
    let timeZoneIdentifier: String
    let isPlanet: Bool
    
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
    
    var currentTimeString: String {
        if isPlanet {
            return planetaryTimeString
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.timeZone = timeZone
            return formatter.string(from: Date())
        }
    }
    
    private var planetaryTimeString: String {
        return PlanetaryTimeCalculator.calculatePlanetaryTimeString(for: self)
    }
    
    static let popularCities = [
        // UTC/GMT
        City(name: "UTC", country: "UTC", timeZoneIdentifier: "UTC", isPlanet: false),
        
        // North America
        City(name: "New York", country: "United States", timeZoneIdentifier: "America/New_York", isPlanet: false),
        City(name: "Boston", country: "United States", timeZoneIdentifier: "America/New_York", isPlanet: false),
        City(name: "Philadelphia", country: "United States", timeZoneIdentifier: "America/New_York", isPlanet: false),
        City(name: "Los Angeles", country: "United States", timeZoneIdentifier: "America/Los_Angeles", isPlanet: false),
        City(name: "San Francisco", country: "United States", timeZoneIdentifier: "America/Los_Angeles", isPlanet: false),
        City(name: "Seattle", country: "United States", timeZoneIdentifier: "America/Los_Angeles", isPlanet: false),
        City(name: "Chicago", country: "United States", timeZoneIdentifier: "America/Chicago", isPlanet: false),
        City(name: "Houston", country: "United States", timeZoneIdentifier: "America/Chicago", isPlanet: false),
        City(name: "Dallas", country: "United States", timeZoneIdentifier: "America/Chicago", isPlanet: false),
        City(name: "Denver", country: "United States", timeZoneIdentifier: "America/Denver", isPlanet: false),
        City(name: "Phoenix", country: "United States", timeZoneIdentifier: "America/Phoenix", isPlanet: false),
        City(name: "Anchorage", country: "United States", timeZoneIdentifier: "America/Anchorage", isPlanet: false),
        City(name: "Honolulu", country: "United States", timeZoneIdentifier: "Pacific/Honolulu", isPlanet: false),
        City(name: "Toronto", country: "Canada", timeZoneIdentifier: "America/Toronto", isPlanet: false),
        City(name: "Montreal", country: "Canada", timeZoneIdentifier: "America/Toronto", isPlanet: false),
        City(name: "Ottawa", country: "Canada", timeZoneIdentifier: "America/Toronto", isPlanet: false),
        City(name: "Vancouver", country: "Canada", timeZoneIdentifier: "America/Vancouver", isPlanet: false),
        City(name: "Calgary", country: "Canada", timeZoneIdentifier: "America/Edmonton", isPlanet: false),
        City(name: "Edmonton", country: "Canada", timeZoneIdentifier: "America/Edmonton", isPlanet: false),
        City(name: "Mexico City", country: "Mexico", timeZoneIdentifier: "America/Mexico_City", isPlanet: false),
        City(name: "Guadalajara", country: "Mexico", timeZoneIdentifier: "America/Mexico_City", isPlanet: false),
        City(name: "Monterrey", country: "Mexico", timeZoneIdentifier: "America/Mexico_City", isPlanet: false),
        
        // South America
        City(name: "São Paulo", country: "Brazil", timeZoneIdentifier: "America/Sao_Paulo", isPlanet: false),
        City(name: "Rio de Janeiro", country: "Brazil", timeZoneIdentifier: "America/Sao_Paulo", isPlanet: false),
        City(name: "Brasília", country: "Brazil", timeZoneIdentifier: "America/Sao_Paulo", isPlanet: false),
        City(name: "Buenos Aires", country: "Argentina", timeZoneIdentifier: "America/Argentina/Buenos_Aires", isPlanet: false),
        City(name: "Córdoba", country: "Argentina", timeZoneIdentifier: "America/Argentina/Buenos_Aires", isPlanet: false),
        City(name: "Rosario", country: "Argentina", timeZoneIdentifier: "America/Argentina/Buenos_Aires", isPlanet: false),
        City(name: "Santiago", country: "Chile", timeZoneIdentifier: "America/Santiago", isPlanet: false),
        City(name: "Valparaíso", country: "Chile", timeZoneIdentifier: "America/Santiago", isPlanet: false),
        City(name: "Concepción", country: "Chile", timeZoneIdentifier: "America/Santiago", isPlanet: false),
        City(name: "Lima", country: "Peru", timeZoneIdentifier: "America/Lima", isPlanet: false),
        City(name: "Arequipa", country: "Peru", timeZoneIdentifier: "America/Lima", isPlanet: false),
        City(name: "Trujillo", country: "Peru", timeZoneIdentifier: "America/Lima", isPlanet: false),
        City(name: "Bogotá", country: "Colombia", timeZoneIdentifier: "America/Bogota", isPlanet: false),
        City(name: "Medellín", country: "Colombia", timeZoneIdentifier: "America/Bogota", isPlanet: false),
        City(name: "Cali", country: "Colombia", timeZoneIdentifier: "America/Bogota", isPlanet: false),
        City(name: "Caracas", country: "Venezuela", timeZoneIdentifier: "America/Caracas", isPlanet: false),
        City(name: "Maracaibo", country: "Venezuela", timeZoneIdentifier: "America/Caracas", isPlanet: false),
        City(name: "Valencia", country: "Venezuela", timeZoneIdentifier: "America/Caracas", isPlanet: false),
        
        // Europe
        City(name: "London", country: "United Kingdom", timeZoneIdentifier: "Europe/London", isPlanet: false),
        City(name: "Manchester", country: "United Kingdom", timeZoneIdentifier: "Europe/London", isPlanet: false),
        City(name: "Birmingham", country: "United Kingdom", timeZoneIdentifier: "Europe/London", isPlanet: false),
        City(name: "Paris", country: "France", timeZoneIdentifier: "Europe/Paris", isPlanet: false),
        City(name: "Lyon", country: "France", timeZoneIdentifier: "Europe/Paris", isPlanet: false),
        City(name: "Marseille", country: "France", timeZoneIdentifier: "Europe/Paris", isPlanet: false),
        City(name: "Berlin", country: "Germany", timeZoneIdentifier: "Europe/Berlin", isPlanet: false),
        City(name: "Munich", country: "Germany", timeZoneIdentifier: "Europe/Berlin", isPlanet: false),
        City(name: "Hamburg", country: "Germany", timeZoneIdentifier: "Europe/Berlin", isPlanet: false),
        City(name: "Rome", country: "Italy", timeZoneIdentifier: "Europe/Rome", isPlanet: false),
        City(name: "Milan", country: "Italy", timeZoneIdentifier: "Europe/Rome", isPlanet: false),
        City(name: "Naples", country: "Italy", timeZoneIdentifier: "Europe/Rome", isPlanet: false),
        City(name: "Madrid", country: "Spain", timeZoneIdentifier: "Europe/Madrid", isPlanet: false),
        City(name: "Barcelona", country: "Spain", timeZoneIdentifier: "Europe/Madrid", isPlanet: false),
        City(name: "Valencia", country: "Spain", timeZoneIdentifier: "Europe/Madrid", isPlanet: false),
        City(name: "Amsterdam", country: "Netherlands", timeZoneIdentifier: "Europe/Amsterdam", isPlanet: false),
        City(name: "Rotterdam", country: "Netherlands", timeZoneIdentifier: "Europe/Amsterdam", isPlanet: false),
        City(name: "The Hague", country: "Netherlands", timeZoneIdentifier: "Europe/Amsterdam", isPlanet: false),
        City(name: "Stockholm", country: "Sweden", timeZoneIdentifier: "Europe/Stockholm", isPlanet: false),
        City(name: "Gothenburg", country: "Sweden", timeZoneIdentifier: "Europe/Stockholm", isPlanet: false),
        City(name: "Malmö", country: "Sweden", timeZoneIdentifier: "Europe/Stockholm", isPlanet: false),
        City(name: "Oslo", country: "Norway", timeZoneIdentifier: "Europe/Oslo", isPlanet: false),
        City(name: "Bergen", country: "Norway", timeZoneIdentifier: "Europe/Oslo", isPlanet: false),
        City(name: "Trondheim", country: "Norway", timeZoneIdentifier: "Europe/Oslo", isPlanet: false),
        City(name: "Copenhagen", country: "Denmark", timeZoneIdentifier: "Europe/Copenhagen", isPlanet: false),
        City(name: "Aarhus", country: "Denmark", timeZoneIdentifier: "Europe/Copenhagen", isPlanet: false),
        City(name: "Odense", country: "Denmark", timeZoneIdentifier: "Europe/Copenhagen", isPlanet: false),
        City(name: "Helsinki", country: "Finland", timeZoneIdentifier: "Europe/Helsinki", isPlanet: false),
        City(name: "Tampere", country: "Finland", timeZoneIdentifier: "Europe/Helsinki", isPlanet: false),
        City(name: "Turku", country: "Finland", timeZoneIdentifier: "Europe/Helsinki", isPlanet: false),
        City(name: "Warsaw", country: "Poland", timeZoneIdentifier: "Europe/Warsaw", isPlanet: false),
        City(name: "Kraków", country: "Poland", timeZoneIdentifier: "Europe/Warsaw", isPlanet: false),
        City(name: "Łódź", country: "Poland", timeZoneIdentifier: "Europe/Warsaw", isPlanet: false),
        City(name: "Prague", country: "Czech Republic", timeZoneIdentifier: "Europe/Prague", isPlanet: false),
        City(name: "Brno", country: "Czech Republic", timeZoneIdentifier: "Europe/Prague", isPlanet: false),
        City(name: "Ostrava", country: "Czech Republic", timeZoneIdentifier: "Europe/Prague", isPlanet: false),
        City(name: "Vienna", country: "Austria", timeZoneIdentifier: "Europe/Vienna", isPlanet: false),
        City(name: "Graz", country: "Austria", timeZoneIdentifier: "Europe/Vienna", isPlanet: false),
        City(name: "Linz", country: "Austria", timeZoneIdentifier: "Europe/Vienna", isPlanet: false),
        City(name: "Budapest", country: "Hungary", timeZoneIdentifier: "Europe/Budapest", isPlanet: false),
        City(name: "Debrecen", country: "Hungary", timeZoneIdentifier: "Europe/Budapest", isPlanet: false),
        City(name: "Szeged", country: "Hungary", timeZoneIdentifier: "Europe/Budapest", isPlanet: false),
        City(name: "Bucharest", country: "Romania", timeZoneIdentifier: "Europe/Bucharest", isPlanet: false),
        City(name: "Cluj-Napoca", country: "Romania", timeZoneIdentifier: "Europe/Bucharest", isPlanet: false),
        City(name: "Timișoara", country: "Romania", timeZoneIdentifier: "Europe/Bucharest", isPlanet: false),
        City(name: "Sofia", country: "Bulgaria", timeZoneIdentifier: "Europe/Sofia", isPlanet: false),
        City(name: "Plovdiv", country: "Bulgaria", timeZoneIdentifier: "Europe/Sofia", isPlanet: false),
        City(name: "Varna", country: "Bulgaria", timeZoneIdentifier: "Europe/Sofia", isPlanet: false),
        City(name: "Athens", country: "Greece", timeZoneIdentifier: "Europe/Athens", isPlanet: false),
        City(name: "Thessaloniki", country: "Greece", timeZoneIdentifier: "Europe/Athens", isPlanet: false),
        City(name: "Patras", country: "Greece", timeZoneIdentifier: "Europe/Athens", isPlanet: false),
        City(name: "Istanbul", country: "Turkey", timeZoneIdentifier: "Europe/Istanbul", isPlanet: false),
        City(name: "Ankara", country: "Turkey", timeZoneIdentifier: "Europe/Istanbul", isPlanet: false),
        City(name: "İzmir", country: "Turkey", timeZoneIdentifier: "Europe/Istanbul", isPlanet: false),
        City(name: "Moscow", country: "Russia", timeZoneIdentifier: "Europe/Moscow", isPlanet: false),
        City(name: "Saint Petersburg", country: "Russia", timeZoneIdentifier: "Europe/Moscow", isPlanet: false),
        City(name: "Novosibirsk", country: "Russia", timeZoneIdentifier: "Asia/Novosibirsk", isPlanet: false),
        City(name: "Kiev", country: "Ukraine", timeZoneIdentifier: "Europe/Kiev", isPlanet: false),
        City(name: "Kharkiv", country: "Ukraine", timeZoneIdentifier: "Europe/Kiev", isPlanet: false),
        City(name: "Odessa", country: "Ukraine", timeZoneIdentifier: "Europe/Kiev", isPlanet: false),
        City(name: "Minsk", country: "Belarus", timeZoneIdentifier: "Europe/Minsk", isPlanet: false),
        City(name: "Gomel", country: "Belarus", timeZoneIdentifier: "Europe/Minsk", isPlanet: false),
        City(name: "Mogilev", country: "Belarus", timeZoneIdentifier: "Europe/Minsk", isPlanet: false),
        City(name: "Riga", country: "Latvia", timeZoneIdentifier: "Europe/Riga", isPlanet: false),
        City(name: "Daugavpils", country: "Latvia", timeZoneIdentifier: "Europe/Riga", isPlanet: false),
        City(name: "Liepāja", country: "Latvia", timeZoneIdentifier: "Europe/Riga", isPlanet: false),
        City(name: "Tallinn", country: "Estonia", timeZoneIdentifier: "Europe/Tallinn", isPlanet: false),
        City(name: "Tartu", country: "Estonia", timeZoneIdentifier: "Europe/Tallinn", isPlanet: false),
        City(name: "Narva", country: "Estonia", timeZoneIdentifier: "Europe/Tallinn", isPlanet: false),
        City(name: "Vilnius", country: "Lithuania", timeZoneIdentifier: "Europe/Vilnius", isPlanet: false),
        City(name: "Kaunas", country: "Lithuania", timeZoneIdentifier: "Europe/Vilnius", isPlanet: false),
        City(name: "Klaipėda", country: "Lithuania", timeZoneIdentifier: "Europe/Vilnius", isPlanet: false),
        
        // Africa
        City(name: "Cairo", country: "Egypt", timeZoneIdentifier: "Africa/Cairo", isPlanet: false),
        City(name: "Johannesburg", country: "South Africa", timeZoneIdentifier: "Africa/Johannesburg", isPlanet: false),
        City(name: "Cape Town", country: "South Africa", timeZoneIdentifier: "Africa/Johannesburg", isPlanet: false),
        City(name: "Durban", country: "South Africa", timeZoneIdentifier: "Africa/Johannesburg", isPlanet: false),
        City(name: "Lagos", country: "Nigeria", timeZoneIdentifier: "Africa/Lagos", isPlanet: false),
        City(name: "Nairobi", country: "Kenya", timeZoneIdentifier: "Africa/Nairobi", isPlanet: false),
        City(name: "Casablanca", country: "Morocco", timeZoneIdentifier: "Africa/Casablanca", isPlanet: false),
        City(name: "Algiers", country: "Algeria", timeZoneIdentifier: "Africa/Algiers", isPlanet: false),
        City(name: "Tunis", country: "Tunisia", timeZoneIdentifier: "Africa/Tunis", isPlanet: false),
        City(name: "Tripoli", country: "Libya", timeZoneIdentifier: "Africa/Tripoli", isPlanet: false),
        City(name: "Khartoum", country: "Sudan", timeZoneIdentifier: "Africa/Khartoum", isPlanet: false),
        City(name: "Addis Ababa", country: "Ethiopia", timeZoneIdentifier: "Africa/Addis_Ababa", isPlanet: false),
        City(name: "Dar es Salaam", country: "Tanzania", timeZoneIdentifier: "Africa/Dar_es_Salaam", isPlanet: false),
        City(name: "Kampala", country: "Uganda", timeZoneIdentifier: "Africa/Kampala", isPlanet: false),
        City(name: "Kinshasa", country: "DR Congo", timeZoneIdentifier: "Africa/Kinshasa", isPlanet: false),
        City(name: "Luanda", country: "Angola", timeZoneIdentifier: "Africa/Luanda", isPlanet: false),
        City(name: "Windhoek", country: "Namibia", timeZoneIdentifier: "Africa/Windhoek", isPlanet: false),
        City(name: "Harare", country: "Zimbabwe", timeZoneIdentifier: "Africa/Harare", isPlanet: false),
        City(name: "Lusaka", country: "Zambia", timeZoneIdentifier: "Africa/Lusaka", isPlanet: false),
        City(name: "Maputo", country: "Mozambique", timeZoneIdentifier: "Africa/Maputo", isPlanet: false),
        City(name: "Antananarivo", country: "Madagascar", timeZoneIdentifier: "Indian/Antananarivo", isPlanet: false),
        
        // Asia
        City(name: "Tokyo", country: "Japan", timeZoneIdentifier: "Asia/Tokyo", isPlanet: false),
        City(name: "Osaka", country: "Japan", timeZoneIdentifier: "Asia/Tokyo", isPlanet: false),
        City(name: "Nagoya", country: "Japan", timeZoneIdentifier: "Asia/Tokyo", isPlanet: false),
        City(name: "Beijing", country: "China", timeZoneIdentifier: "Asia/Shanghai", isPlanet: false),
        City(name: "Shanghai", country: "China", timeZoneIdentifier: "Asia/Shanghai", isPlanet: false),
        City(name: "Guangzhou", country: "China", timeZoneIdentifier: "Asia/Shanghai", isPlanet: false),
        City(name: "Hong Kong", country: "China", timeZoneIdentifier: "Asia/Hong_Kong", isPlanet: false),
        City(name: "Seoul", country: "South Korea", timeZoneIdentifier: "Asia/Seoul", isPlanet: false),
        City(name: "Busan", country: "South Korea", timeZoneIdentifier: "Asia/Seoul", isPlanet: false),
        City(name: "Incheon", country: "South Korea", timeZoneIdentifier: "Asia/Seoul", isPlanet: false),
        City(name: "Singapore", country: "Singapore", timeZoneIdentifier: "Asia/Singapore", isPlanet: false),
        City(name: "Bangkok", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", isPlanet: false),
        City(name: "Chiang Mai", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", isPlanet: false),
        City(name: "Phuket", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", isPlanet: false),
        City(name: "Jakarta", country: "Indonesia", timeZoneIdentifier: "Asia/Jakarta", isPlanet: false),
        City(name: "Surabaya", country: "Indonesia", timeZoneIdentifier: "Asia/Jakarta", isPlanet: false),
        City(name: "Bandung", country: "Indonesia", timeZoneIdentifier: "Asia/Jakarta", isPlanet: false),
        City(name: "Manila", country: "Philippines", timeZoneIdentifier: "Asia/Manila", isPlanet: false),
        City(name: "Cebu", country: "Philippines", timeZoneIdentifier: "Asia/Manila", isPlanet: false),
        City(name: "Davao", country: "Philippines", timeZoneIdentifier: "Asia/Manila", isPlanet: false),
        City(name: "Kuala Lumpur", country: "Malaysia", timeZoneIdentifier: "Asia/Kuala_Lumpur", isPlanet: false),
        City(name: "Penang", country: "Malaysia", timeZoneIdentifier: "Asia/Kuala_Lumpur", isPlanet: false),
        City(name: "Johor Bahru", country: "Malaysia", timeZoneIdentifier: "Asia/Kuala_Lumpur", isPlanet: false),
        City(name: "Hanoi", country: "Vietnam", timeZoneIdentifier: "Asia/Ho_Chi_Minh", isPlanet: false),
        City(name: "Ho Chi Minh City", country: "Vietnam", timeZoneIdentifier: "Asia/Ho_Chi_Minh", isPlanet: false),
        City(name: "Da Nang", country: "Vietnam", timeZoneIdentifier: "Asia/Ho_Chi_Minh", isPlanet: false),
        City(name: "Yangon", country: "Myanmar", timeZoneIdentifier: "Asia/Yangon", isPlanet: false),
        City(name: "Mandalay", country: "Myanmar", timeZoneIdentifier: "Asia/Yangon", isPlanet: false),
        City(name: "Naypyidaw", country: "Myanmar", timeZoneIdentifier: "Asia/Yangon", isPlanet: false),
        City(name: "Phnom Penh", country: "Cambodia", timeZoneIdentifier: "Asia/Phnom_Penh", isPlanet: false),
        City(name: "Siem Reap", country: "Cambodia", timeZoneIdentifier: "Asia/Phnom_Penh", isPlanet: false),
        City(name: "Battambang", country: "Cambodia", timeZoneIdentifier: "Asia/Phnom_Penh", isPlanet: false),
        City(name: "Vientiane", country: "Laos", timeZoneIdentifier: "Asia/Vientiane", isPlanet: false),
        City(name: "Luang Prabang", country: "Laos", timeZoneIdentifier: "Asia/Vientiane", isPlanet: false),
        City(name: "Pakse", country: "Laos", timeZoneIdentifier: "Asia/Vientiane", isPlanet: false),
        City(name: "Dhaka", country: "Bangladesh", timeZoneIdentifier: "Asia/Dhaka", isPlanet: false),
        City(name: "Chittagong", country: "Bangladesh", timeZoneIdentifier: "Asia/Dhaka", isPlanet: false),
        City(name: "Sylhet", country: "Bangladesh", timeZoneIdentifier: "Asia/Dhaka", isPlanet: false),
        City(name: "Kathmandu", country: "Nepal", timeZoneIdentifier: "Asia/Kathmandu", isPlanet: false),
        City(name: "Pokhara", country: "Nepal", timeZoneIdentifier: "Asia/Kathmandu", isPlanet: false),
        City(name: "Lalitpur", country: "Nepal", timeZoneIdentifier: "Asia/Kathmandu", isPlanet: false),
        City(name: "Colombo", country: "Sri Lanka", timeZoneIdentifier: "Asia/Colombo", isPlanet: false),
        City(name: "Kandy", country: "Sri Lanka", timeZoneIdentifier: "Asia/Colombo", isPlanet: false),
        City(name: "Galle", country: "Sri Lanka", timeZoneIdentifier: "Asia/Colombo", isPlanet: false),
        City(name: "Mumbai", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "New Delhi", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "Kolkata", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "Chennai", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "Bangalore", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "Hyderabad", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "Karachi", country: "Pakistan", timeZoneIdentifier: "Asia/Karachi", isPlanet: false),
        City(name: "Lahore", country: "Pakistan", timeZoneIdentifier: "Asia/Karachi", isPlanet: false),
        City(name: "Faisalabad", country: "Pakistan", timeZoneIdentifier: "Asia/Karachi", isPlanet: false),
        City(name: "Tashkent", country: "Uzbekistan", timeZoneIdentifier: "Asia/Tashkent", isPlanet: false),
        City(name: "Samarkand", country: "Uzbekistan", timeZoneIdentifier: "Asia/Tashkent", isPlanet: false),
        City(name: "Bukhara", country: "Uzbekistan", timeZoneIdentifier: "Asia/Tashkent", isPlanet: false),
        City(name: "Almaty", country: "Kazakhstan", timeZoneIdentifier: "Asia/Almaty", isPlanet: false),
        City(name: "Nur-Sultan", country: "Kazakhstan", timeZoneIdentifier: "Asia/Almaty", isPlanet: false),
        City(name: "Shymkent", country: "Kazakhstan", timeZoneIdentifier: "Asia/Almaty", isPlanet: false),
        City(name: "Bishkek", country: "Kyrgyzstan", timeZoneIdentifier: "Asia/Bishkek", isPlanet: false),
        City(name: "Osh", country: "Kyrgyzstan", timeZoneIdentifier: "Asia/Bishkek", isPlanet: false),
        City(name: "Jalal-Abad", country: "Kyrgyzstan", timeZoneIdentifier: "Asia/Bishkek", isPlanet: false),
        City(name: "Dushanbe", country: "Tajikistan", timeZoneIdentifier: "Asia/Dushanbe", isPlanet: false),
        City(name: "Khujand", country: "Tajikistan", timeZoneIdentifier: "Asia/Dushanbe", isPlanet: false),
        City(name: "Kulob", country: "Tajikistan", timeZoneIdentifier: "Asia/Dushanbe", isPlanet: false),
        City(name: "Ashgabat", country: "Turkmenistan", timeZoneIdentifier: "Asia/Ashgabat", isPlanet: false),
        City(name: "Türkmenabat", country: "Turkmenistan", timeZoneIdentifier: "Asia/Ashgabat", isPlanet: false),
        City(name: "Mary", country: "Turkmenistan", timeZoneIdentifier: "Asia/Ashgabat", isPlanet: false),
        City(name: "Baku", country: "Azerbaijan", timeZoneIdentifier: "Asia/Baku", isPlanet: false),
        City(name: "Ganja", country: "Azerbaijan", timeZoneIdentifier: "Asia/Baku", isPlanet: false),
        City(name: "Sumqayıt", country: "Azerbaijan", timeZoneIdentifier: "Asia/Baku", isPlanet: false),
        City(name: "Tbilisi", country: "Georgia", timeZoneIdentifier: "Asia/Tbilisi", isPlanet: false),
        City(name: "Batumi", country: "Georgia", timeZoneIdentifier: "Asia/Tbilisi", isPlanet: false),
        City(name: "Kutaisi", country: "Georgia", timeZoneIdentifier: "Asia/Tbilisi", isPlanet: false),
        City(name: "Yerevan", country: "Armenia", timeZoneIdentifier: "Asia/Yerevan", isPlanet: false),
        City(name: "Gyumri", country: "Armenia", timeZoneIdentifier: "Asia/Yerevan", isPlanet: false),
        City(name: "Vanadzor", country: "Armenia", timeZoneIdentifier: "Asia/Yerevan", isPlanet: false),
        City(name: "Tehran", country: "Iran", timeZoneIdentifier: "Asia/Tehran", isPlanet: false),
        City(name: "Baghdad", country: "Iraq", timeZoneIdentifier: "Asia/Baghdad", isPlanet: false),
        City(name: "Riyadh", country: "Saudi Arabia", timeZoneIdentifier: "Asia/Riyadh", isPlanet: false),
        City(name: "Jeddah", country: "Saudi Arabia", timeZoneIdentifier: "Asia/Riyadh", isPlanet: false),
        City(name: "Mecca", country: "Saudi Arabia", timeZoneIdentifier: "Asia/Riyadh", isPlanet: false),
        City(name: "Kuwait City", country: "Kuwait", timeZoneIdentifier: "Asia/Kuwait", isPlanet: false),
        City(name: "Doha", country: "Qatar", timeZoneIdentifier: "Asia/Qatar", isPlanet: false),
        City(name: "Abu Dhabi", country: "UAE", timeZoneIdentifier: "Asia/Dubai", isPlanet: false),
        City(name: "Dubai", country: "UAE", timeZoneIdentifier: "Asia/Dubai", isPlanet: false),
        City(name: "Sharjah", country: "UAE", timeZoneIdentifier: "Asia/Dubai", isPlanet: false),
        City(name: "Muscat", country: "Oman", timeZoneIdentifier: "Asia/Muscat", isPlanet: false),
        City(name: "Sana'a", country: "Yemen", timeZoneIdentifier: "Asia/Aden", isPlanet: false),
        City(name: "Amman", country: "Jordan", timeZoneIdentifier: "Asia/Amman", isPlanet: false),
        City(name: "Beirut", country: "Lebanon", timeZoneIdentifier: "Asia/Beirut", isPlanet: false),
        City(name: "Damascus", country: "Syria", timeZoneIdentifier: "Asia/Damascus", isPlanet: false),
        City(name: "Jerusalem", country: "Israel", timeZoneIdentifier: "Asia/Jerusalem", isPlanet: false),
        City(name: "Tel Aviv", country: "Israel", timeZoneIdentifier: "Asia/Jerusalem", isPlanet: false),
        City(name: "Haifa", country: "Israel", timeZoneIdentifier: "Asia/Jerusalem", isPlanet: false),
        City(name: "Nicosia", country: "Cyprus", timeZoneIdentifier: "Asia/Nicosia", isPlanet: false),
        City(name: "Yekaterinburg", country: "Russia", timeZoneIdentifier: "Asia/Yekaterinburg", isPlanet: false),
        City(name: "Krasnoyarsk", country: "Russia", timeZoneIdentifier: "Asia/Krasnoyarsk", isPlanet: false),
        City(name: "Irkutsk", country: "Russia", timeZoneIdentifier: "Asia/Irkutsk", isPlanet: false),
        City(name: "Yakutsk", country: "Russia", timeZoneIdentifier: "Asia/Yakutsk", isPlanet: false),
        City(name: "Vladivostok", country: "Russia", timeZoneIdentifier: "Asia/Vladivostok", isPlanet: false),
        City(name: "Magadan", country: "Russia", timeZoneIdentifier: "Asia/Magadan", isPlanet: false),
        City(name: "Kamchatka", country: "Russia", timeZoneIdentifier: "Asia/Kamchatka", isPlanet: false),
        
        // Oceania
        City(name: "Sydney", country: "Australia", timeZoneIdentifier: "Australia/Sydney", isPlanet: false),
        City(name: "Melbourne", country: "Australia", timeZoneIdentifier: "Australia/Melbourne", isPlanet: false),
        City(name: "Brisbane", country: "Australia", timeZoneIdentifier: "Australia/Brisbane", isPlanet: false),
        City(name: "Perth", country: "Australia", timeZoneIdentifier: "Australia/Perth", isPlanet: false),
        City(name: "Adelaide", country: "Australia", timeZoneIdentifier: "Australia/Adelaide", isPlanet: false),
        City(name: "Darwin", country: "Australia", timeZoneIdentifier: "Australia/Darwin", isPlanet: false),
        City(name: "Auckland", country: "New Zealand", timeZoneIdentifier: "Pacific/Auckland", isPlanet: false),
        City(name: "Wellington", country: "New Zealand", timeZoneIdentifier: "Pacific/Auckland", isPlanet: false),
        City(name: "Port Moresby", country: "Papua New Guinea", timeZoneIdentifier: "Pacific/Port_Moresby", isPlanet: false),
        City(name: "Fiji", country: "Fiji", timeZoneIdentifier: "Pacific/Fiji", isPlanet: false),
        City(name: "Noumea", country: "New Caledonia", timeZoneIdentifier: "Pacific/Noumea", isPlanet: false),
        City(name: "Port Vila", country: "Vanuatu", timeZoneIdentifier: "Pacific/Efate", isPlanet: false),
        City(name: "Honiara", country: "Solomon Islands", timeZoneIdentifier: "Pacific/Guadalcanal", isPlanet: false),
        City(name: "Palikir", country: "Micronesia", timeZoneIdentifier: "Pacific/Pohnpei", isPlanet: false),
        City(name: "Majuro", country: "Marshall Islands", timeZoneIdentifier: "Pacific/Majuro", isPlanet: false),
        City(name: "Tarawa", country: "Kiribati", timeZoneIdentifier: "Pacific/Tarawa", isPlanet: false),
        City(name: "Funafuti", country: "Tuvalu", timeZoneIdentifier: "Pacific/Funafuti", isPlanet: false),
        City(name: "Apia", country: "Samoa", timeZoneIdentifier: "Pacific/Apia", isPlanet: false),
        City(name: "Nuku'alofa", country: "Tonga", timeZoneIdentifier: "Pacific/Tongatapu", isPlanet: false),
        City(name: "Papeete", country: "French Polynesia", timeZoneIdentifier: "Pacific/Tahiti", isPlanet: false),
        
        // Atlantic Islands
        City(name: "Reykjavik", country: "Iceland", timeZoneIdentifier: "Atlantic/Reykjavik", isPlanet: false),
        City(name: "Azores", country: "Portugal", timeZoneIdentifier: "Atlantic/Azores", isPlanet: false),
        City(name: "Cape Verde", country: "Cape Verde", timeZoneIdentifier: "Atlantic/Cape_Verde", isPlanet: false),
        City(name: "Canary Islands", country: "Spain", timeZoneIdentifier: "Atlantic/Canary", isPlanet: false),
        City(name: "Madeira", country: "Portugal", timeZoneIdentifier: "Atlantic/Madeira", isPlanet: false),
        City(name: "St. Helena", country: "St. Helena", timeZoneIdentifier: "Atlantic/St_Helena", isPlanet: false),
        City(name: "South Georgia", country: "South Georgia", timeZoneIdentifier: "Atlantic/South_Georgia", isPlanet: false),
        City(name: "Falkland Islands", country: "Falkland Islands", timeZoneIdentifier: "Atlantic/Stanley", isPlanet: false),
        
        // Indian Ocean
        City(name: "Mauritius", country: "Mauritius", timeZoneIdentifier: "Indian/Mauritius", isPlanet: false),
        City(name: "Seychelles", country: "Seychelles", timeZoneIdentifier: "Indian/Mahe", isPlanet: false),
        City(name: "Comoros", country: "Comoros", timeZoneIdentifier: "Indian/Comoro", isPlanet: false),
        City(name: "Mayotte", country: "Mayotte", timeZoneIdentifier: "Indian/Mayotte", isPlanet: false),
        City(name: "Reunion", country: "Reunion", timeZoneIdentifier: "Indian/Reunion", isPlanet: false),
        City(name: "Chagos", country: "British Indian Ocean Territory", timeZoneIdentifier: "Indian/Chagos", isPlanet: false),
        City(name: "Maldives", country: "Maldives", timeZoneIdentifier: "Indian/Maldives", isPlanet: false),
        City(name: "Cocos Islands", country: "Cocos Islands", timeZoneIdentifier: "Indian/Cocos", isPlanet: false),
        City(name: "Christmas Island", country: "Christmas Island", timeZoneIdentifier: "Indian/Christmas", isPlanet: false)
    ]
    
    static let planets = [
        City(name: "Mercury 🧠", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true),
        City(name: "Venus 💖", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true),
        City(name: "Earth 🌍", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true),
        City(name: "Mars 🛡️", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true),
        City(name: "Jupiter 👑", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true),
        City(name: "Saturn 🪐", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true),
        City(name: "Uranus 🔭", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true),
        City(name: "Neptune 🌊", country: "Solar System", timeZoneIdentifier: "UTC", isPlanet: true)
    ]
    
    static let allCities = popularCities + planets
}

// MARK: - Planetary Time Calculator
struct PlanetaryTimeCalculator {
    // Realistic day lengths in Earth hours
    private static let dayLengths: [String: Double] = [
        "Mercury 🧠": 1408.0,    // 58.6 Earth days
        "Venus 💖": 5832.0,      // 243 Earth days (retrograde)
        "Earth 🌍": 24.0,        // 24h 0m 0s
        "Mars 🛡️": 24.6,        // 24h 37m 22s
        "Jupiter 👑": 9.9,       // 9h 56m
        "Saturn 🪐": 10.7,       // 10h 34m
        "Uranus 🔭": 17.2,       // 17h 14m
        "Neptune 🌊": 16.1       // 16h 6m
    ]
    
    static func calculateTime(for city: City) -> Date {
        guard city.isPlanet else {
            return Date()
        }
        
        let dayLength = dayLengths[city.name] ?? 24.0
        let earthSeconds = Date().timeIntervalSince1970
        
        // Convert Earth time to planetary time
        // Each planet has a different "speed" relative to Earth
        let planetSeconds = earthSeconds * (24.0 / dayLength)
        
        // Return the actual planetary time (not converted back to Earth format)
        return Date(timeIntervalSince1970: planetSeconds)
    }
    
    static func calculatePlanetaryTimeString(for city: City) -> String {
        guard city.isPlanet else {
            return ""
        }
        
        let dayLength = dayLengths[city.name] ?? 24.0
        let earthSeconds = Date().timeIntervalSince1970
        
        // Calculate planetary time with different second speeds
        let planetSeconds = earthSeconds * (24.0 / dayLength)
        
        // Convert to hours, minutes, seconds in planetary time
        let totalPlanetarySeconds = Int(planetSeconds) % (24 * 3600) // 24 hours in seconds
        let hours = totalPlanetarySeconds / 3600
        let minutes = (totalPlanetarySeconds % 3600) / 60
        let seconds = totalPlanetarySeconds % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - World Clock Preset
struct WorldClockPreset {
    let label: String
    let city: City
    
    static let defaults = [
        WorldClockPreset(label: "NYC", city: City(name: "New York", country: "United States", timeZoneIdentifier: "America/New_York", isPlanet: false)),
        WorldClockPreset(label: "UTC", city: City(name: "UTC", country: "UTC", timeZoneIdentifier: "UTC", isPlanet: false)),
        WorldClockPreset(label: "Beijing", city: City(name: "Beijing", country: "China", timeZoneIdentifier: "Asia/Shanghai", isPlanet: false))
    ]
}

// MARK: - View Model
@MainActor
class WorldClockViewModel: ObservableObject {
    @Published var clocks: [WorldClock] = []
    @Published var currentTime = Date()
    @Published var selectedDate = Date()
    @Published var timeSliderValue: Double = 0.0
    @Published var isConverterActive = false
    @Published var countdownSeconds = 0
    @Published var selectedClocks: Set<UUID> = []
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "worldClocks"
    private var timer: Foundation.Timer?
    private var converterTimer: Foundation.Timer?
    private var countdownTimer: Foundation.Timer?
    let aiService = AITimezoneService()
    private var hasTriggeredAIForCurrentSession = false
    
    // Computed properties for current timezone and other clocks
    var currentTimezoneClock: WorldClock? {
        let currentTimeZoneId = TimeZone.current.identifier
        return clocks.first { $0.timeZoneIdentifier == currentTimeZoneId }
    }
    
    var otherClocks: [WorldClock] {
        let currentTimeZoneId = TimeZone.current.identifier
        return clocks.filter { $0.timeZoneIdentifier != currentTimeZoneId }
    }
    
    // Computed properties for selection mode
    var isSelectionMode: Bool {
        !selectedClocks.isEmpty
    }
    
    var selectedClocksCount: Int {
        selectedClocks.count
    }
    
    var selectableClocks: [WorldClock] {
        otherClocks // Only other clocks can be selected (not current timezone)
    }
    
    var selectedTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.timeZone = TimeZone.current
        
        return formatter.string(from: converterTime)
    }
    
    var converterTime: Date {
        // Create a date with the selected date and time from slider
        let calendar = Calendar.current
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Convert slider value (0-1) to 15-minute intervals
        // 96 steps = 24 hours * 4 intervals per hour
        let stepIndex = round(timeSliderValue * 96)
        let clampedStepIndex = max(0, min(95, stepIndex)) // Ensure we stay within bounds
        
        let totalMinutes = Int(clampedStepIndex) * 15 // Each step is 15 minutes
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        var timeComponents = DateComponents()
        timeComponents.year = selectedDateComponents.year
        timeComponents.month = selectedDateComponents.month
        timeComponents.day = selectedDateComponents.day
        timeComponents.hour = hours
        timeComponents.minute = minutes
        timeComponents.second = 0
        
        return calendar.date(from: timeComponents) ?? Date()
    }
    
    var countdownProgress: Double {
        return Double(10 - countdownSeconds) / 10.0
    }
    
    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDate(selectedDate, inSameDayAs: Date())
    }
    
    var navigationTitle: String {
        let allClocks = [currentTimezoneClock].compactMap { $0 } + otherClocks
        let hasPlanet = allClocks.contains { clock in
            clock.cityName.contains("🧠") || clock.cityName.contains("💖") || clock.cityName.contains("🌍") || 
            clock.cityName.contains("🛡️") || clock.cityName.contains("👑") || clock.cityName.contains("🪐") || 
            clock.cityName.contains("🔭") || clock.cityName.contains("🌊")
        }
        return hasPlanet ? "🪐🕰️ Planetary Clock" : "🌍🕒 World Clock"
    }
    
    var aiRecommendation: String {
        return aiService.currentRecommendation
    }
    
    private func triggerAIRecommendation() {
        print("🍌 Trigger: isConverterActive=\(isConverterActive), clocks.count=\(clocks.count), hasTriggered=\(hasTriggeredAIForCurrentSession)")
        print("🍌 Trigger: Current clocks:")
        for (index, clock) in clocks.enumerated() {
            print("🍌 Trigger:   [\(index)] \(clock.cityName) (\(clock.timeZoneIdentifier))")
        }
        
        // Only trigger if converter is active, we have multiple timezones, and we haven't triggered yet this session
        if isConverterActive && clocks.count >= 2 && !hasTriggeredAIForCurrentSession {
            print("🍌 Trigger: Calling AI service")
            hasTriggeredAIForCurrentSession = true
            Task {
                await aiService.getRecommendation(for: clocks, selectedDate: selectedDate)
            }
        } else {
            print("🍌 Trigger: Skipping - converter not active, insufficient clocks, or already triggered")
            print("🍌 Trigger:   isConverterActive=\(isConverterActive)")
            print("🍌 Trigger:   clocks.count >= 2 = \(clocks.count >= 2)")
            print("🍌 Trigger:   !hasTriggeredAIForCurrentSession = \(!hasTriggeredAIForCurrentSession)")
        }
    }
    
    // MARK: - Meeting Time Suggestions
    
    var meetingTimeSuggestion: MeetingSuggestion {
        guard isConverterActive && !otherClocks.isEmpty else { 
            return MeetingSuggestion(type: .none, message: "", suggestedTimes: [])
        }
        
        let regularClocks = otherClocks.filter { clock in
            !clock.cityName.contains("🧠") && !clock.cityName.contains("💖") && !clock.cityName.contains("🌍") && 
            !clock.cityName.contains("🛡️") && !clock.cityName.contains("👑") && !clock.cityName.contains("🪐") && 
            !clock.cityName.contains("🔭") && !clock.cityName.contains("🌊")
        }
        
        guard !regularClocks.isEmpty else { 
            return MeetingSuggestion(type: .none, message: "", suggestedTimes: [])
        }
        
        return generateMeetingSuggestions(for: regularClocks)
    }
    
    struct MeetingSuggestion {
        enum SuggestionType {
            case excellent, challenging, incompatible, none
        }
        
        let type: SuggestionType
        let message: String
        let suggestedTimes: [String]
    }
    
    private func generateMeetingSuggestions(for clocks: [WorldClock]) -> MeetingSuggestion {
        // Analyze current time
        let currentAnalysis = analyzeCurrentTime(for: clocks)
        
        // Generate suggested times for different scenarios
        let suggestedTimes = generateSuggestedTimes(for: clocks)
        
        switch currentAnalysis.quality {
        case .excellent:
            return MeetingSuggestion(
                type: .excellent,
                message: "These timezones work well together!",
                suggestedTimes: suggestedTimes
            )
        case .good:
            return MeetingSuggestion(
                type: .excellent,
                message: "These timezones work well together!",
                suggestedTimes: suggestedTimes
            )
        case .fair:
            return MeetingSuggestion(
                type: .challenging,
                message: "These timezones are tough, but these times might be best:",
                suggestedTimes: suggestedTimes
            )
        case .poor:
            return MeetingSuggestion(
                type: .incompatible,
                message: "These times aren't compatible. Someone needs to wake up.",
                suggestedTimes: suggestedTimes
            )
        }
    }
    
    private struct TimeAnalysis {
        enum Quality {
            case excellent, good, fair, poor
        }
        
        let quality: Quality
        let goodCount: Int
        let fairCount: Int
        let totalCount: Int
    }
    
    private func analyzeCurrentTime(for clocks: [WorldClock]) -> TimeAnalysis {
        var excellentCount = 0
        var goodCount = 0
        var fairCount = 0
        
        for clock in clocks {
            let baseTime = converterTime
            let formatter = DateFormatter()
            formatter.timeZone = clock.timeZone
            formatter.dateFormat = "HH"
            let hourString = formatter.string(from: baseTime)
            let hour = Int(hourString) ?? 0
            
            switch hour {
            case 9..<17:  // 9am-5pm - excellent business hours
                excellentCount += 1
            case 8..<18:  // 8am-6pm - good business hours
                goodCount += 1
            case 7..<20:  // 7am-8pm - fair hours
                fairCount += 1
            default:      // outside fair hours
                break
            }
        }
        
        let totalCount = clocks.count
        let excellentPercentage = Double(excellentCount) / Double(totalCount)
        let goodPercentage = Double(goodCount) / Double(totalCount)
        let fairPercentage = Double(fairCount) / Double(totalCount)
        
        // More lenient thresholds
        if excellentPercentage >= 0.6 {
            return TimeAnalysis(quality: .excellent, goodCount: excellentCount, fairCount: goodCount, totalCount: totalCount)
        } else if goodPercentage >= 0.5 {
            return TimeAnalysis(quality: .good, goodCount: goodCount, fairCount: fairCount, totalCount: totalCount)
        } else if fairPercentage >= 0.3 {
            return TimeAnalysis(quality: .fair, goodCount: fairCount, fairCount: fairCount, totalCount: totalCount)
        } else {
            return TimeAnalysis(quality: .poor, goodCount: 0, fairCount: fairCount, totalCount: totalCount)
        }
    }
    
    private func generateSuggestedTimes(for clocks: [WorldClock]) -> [String] {
        let calendar = Calendar.current
        let selectedDateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        
        // Generate time blocks throughout the day to find optimal meeting windows
        var suggestedTimes: [String] = []
        var blockScores: [(startHour: Int, endHour: Int, score: Int)] = []
        
        // Test time blocks from 6am to 10pm
        for startHour in 6...20 {
            for duration in [1, 2, 3] { // 1, 2, or 3 hour blocks
                let endHour = startHour + duration
                guard endHour <= 22 else { continue }
                
                var blockScore = 0
                var totalTests = 0
                
                // Test every 30 minutes within this block
                for testHour in startHour..<endHour {
                    for minute in [0, 30] {
                        var timeComponents = DateComponents()
                        timeComponents.year = selectedDateComponents.year
                        timeComponents.month = selectedDateComponents.month
                        timeComponents.day = selectedDateComponents.day
                        timeComponents.hour = testHour
                        timeComponents.minute = minute
                        timeComponents.second = 0
                        
                        guard let testTime = calendar.date(from: timeComponents) else { continue }
                        totalTests += 1
                        
                        // Score this time based on how well it works for all timezones
                        for clock in clocks {
                            let formatter = DateFormatter()
                            formatter.timeZone = clock.timeZone
                            formatter.dateFormat = "HH"
                            let hourString = formatter.string(from: testTime)
                            let hour = Int(hourString) ?? 0
                            
                            switch hour {
                            case 9..<17:  // 9am-5pm - excellent
                                blockScore += 3
                            case 8..<18:  // 8am-6pm - good
                                blockScore += 2
                            case 7..<20:  // 7am-8pm - fair
                                blockScore += 1
                            default:      // outside fair hours
                                blockScore += 0
                            }
                        }
                    }
                }
                
                // Average score for this block
                let averageScore = totalTests > 0 ? blockScore / totalTests : 0
                blockScores.append((startHour: startHour, endHour: endHour, score: averageScore))
            }
        }
        
        // Sort by score and take top blocks (usually just 1, max 2)
        let topBlocks = blockScores.sorted { $0.score > $1.score }.prefix(2)
        
        for block in topBlocks {
            let startFormatter = DateFormatter()
            startFormatter.timeZone = TimeZone.current
            startFormatter.dateFormat = "h:mm a"
            
            let endFormatter = DateFormatter()
            endFormatter.timeZone = TimeZone.current
            endFormatter.dateFormat = "h:mm a"
            
            var startComponents = DateComponents()
            startComponents.year = selectedDateComponents.year
            startComponents.month = selectedDateComponents.month
            startComponents.day = selectedDateComponents.day
            startComponents.hour = block.startHour
            startComponents.minute = 0
            startComponents.second = 0
            
            var endComponents = DateComponents()
            endComponents.year = selectedDateComponents.year
            endComponents.month = selectedDateComponents.month
            endComponents.day = selectedDateComponents.day
            endComponents.hour = block.endHour
            endComponents.minute = 0
            endComponents.second = 0
            
            guard let startTime = calendar.date(from: startComponents),
                  let endTime = calendar.date(from: endComponents) else { continue }
            
            let startString = startFormatter.string(from: startTime)
            let endString = endFormatter.string(from: endTime)
            
            // Add context about how many timezones this works for
            let workingCount = block.score / 3 // Rough estimate of working timezones
            let totalCount = clocks.count
            
            let context = workingCount >= totalCount * 3 / 4 ? " (works for \(workingCount)/\(totalCount))" : ""
            suggestedTimes.append("\(startString) - \(endString)\(context)")
        }
        
        return suggestedTimes
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(for clock: WorldClock) {
        if selectedClocks.contains(clock.id) {
            selectedClocks.remove(clock.id)
        } else {
            selectedClocks.insert(clock.id)
        }
    }
    
    func selectAll() {
        selectedClocks = Set(selectableClocks.map { $0.id })
    }
    
    func deselectAll() {
        selectedClocks.removeAll()
    }
    
    func isSelected(_ clock: WorldClock) -> Bool {
        selectedClocks.contains(clock.id)
    }
    
    // MARK: - Bulk Operations
    
    func deleteSelectedClocks() {
        let clocksToDelete = clocks.filter { selectedClocks.contains($0.id) }
        
        for clockToDelete in clocksToDelete {
            if let index = clocks.firstIndex(where: { $0.id == clockToDelete.id }) {
                clocks.remove(at: index)
            }
        }
        
        selectedClocks.removeAll() // Clear selection after deletion
        updateDisplayOrder()
        saveClocks()
        HapticManager.shared.impact(.light)
        
        // Trigger AI recommendation if converter is active
        if isConverterActive {
            Task {
                await aiService.getRecommendation(for: clocks, selectedDate: selectedDate)
            }
        }
    }
    
    func handleSliderEditing(_ editing: Bool) {
        if editing {
            // User started touching the slider
            let wasConverterActive = isConverterActive
            isConverterActive = true
            countdownSeconds = 0
            converterTimer?.invalidate()
            countdownTimer?.invalidate()
            
            // Only trigger AI recommendation when converter first becomes active (not on every slider move)
            if !wasConverterActive {
                triggerAIRecommendation()
            }
        } else {
            // User stopped touching the slider
            HapticManager.shared.impact(.light)
            
            // Start countdown
            countdownSeconds = 10
            startCountdown()
            
            // Start 10-second timer to deactivate converter
            converterTimer?.invalidate()
            converterTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                DispatchQueue.main.async {
                    self.isConverterActive = false
                    self.countdownSeconds = 0
                    self.hasTriggeredAIForCurrentSession = false
                }
            }
        }
    }
    
    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                if self.countdownSeconds > 0 {
                    self.countdownSeconds -= 1
                } else {
                    self.countdownTimer?.invalidate()
                }
            }
        }
    }
    
    func endConverterMode() {
        // Immediately end converter mode
        isConverterActive = false
        countdownSeconds = 0
        hasTriggeredAIForCurrentSession = false
        
        // Cancel all timers
        converterTimer?.invalidate()
        countdownTimer?.invalidate()
        
        // Provide haptic feedback
        HapticManager.shared.impact(.medium)
    }
    
    init() {
        loadClocks()
        ensureCurrentTimezoneExists()
        startTimer()
        
        // Initialize time slider to current time
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let secondsSinceMidnight = Double(hour * 3600 + minute * 60)
        timeSliderValue = secondsSinceMidnight / (24 * 3600)
    }
    
    deinit {
        timer?.invalidate()
        converterTimer?.invalidate()
        countdownTimer?.invalidate()
    }
    
    private func ensureCurrentTimezoneExists() {
        let currentTimeZone = TimeZone.current
        let currentTimeZoneId = currentTimeZone.identifier
        
        // Check if current timezone already exists
        if !clocks.contains(where: { $0.timeZoneIdentifier == currentTimeZoneId }) {
            let currentCity = City(
                name: currentTimeZone.localizedName(for: .generic, locale: .current) ?? "Current",
                country: "Local",
                timeZoneIdentifier: currentTimeZoneId,
                isPlanet: false
            )
            let currentClock = WorldClock(city: currentCity, displayOrder: 0)
            clocks.insert(currentClock, at: 0)
            updateDisplayOrder()
            saveClocks()
        }
    }
    
    func addClock(for city: City) {
        // Check if a clock with the same timezone already exists
        if clocks.contains(where: { $0.timeZoneIdentifier == city.timeZoneIdentifier }) {
            // City already exists, don't add duplicate
            HapticManager.shared.impact(.medium)
            return
        }
        
        let clock = WorldClock(city: city, displayOrder: clocks.count)
        clocks.append(clock)
        updateDisplayOrder()
        saveClocks()
        HapticManager.shared.impact(.light)
        
        // Reset AI trigger flag since timezones changed
        hasTriggeredAIForCurrentSession = false
        // Trigger AI recommendation if converter is active and we have multiple timezones
        if isConverterActive && clocks.count >= 2 {
            triggerAIRecommendation()
        }
    }
    
    func deleteClocks(at offsets: IndexSet) {
        // Only delete from other clocks (not current timezone)
        let otherClocksArray = otherClocks
        let clocksToDelete = offsets.map { otherClocksArray[$0] }
        
        for clockToDelete in clocksToDelete {
            if let index = clocks.firstIndex(where: { $0.id == clockToDelete.id }) {
                clocks.remove(at: index)
            }
        }
        
        updateDisplayOrder()
        saveClocks()
        HapticManager.shared.impact(.light)
        
        // Reset AI trigger flag since timezones changed
        hasTriggeredAIForCurrentSession = false
        // Trigger AI recommendation if converter is active and we have multiple timezones
        if isConverterActive && clocks.count >= 2 {
            triggerAIRecommendation()
        }
    }
    
    func deleteCity(_ city: WorldClock) {
        if let index = clocks.firstIndex(where: { $0.id == city.id }) {
            clocks.remove(at: index)
            updateDisplayOrder()
            saveClocks()
            HapticManager.shared.impact(.light)
        }
    }
    
    func moveClocks(from source: IndexSet, to destination: Int) {
        // Only move other clocks (not current timezone)
        let otherClocksArray = otherClocks
        let clocksToMove = source.map { otherClocksArray[$0] }
        
        // Remove clocks from their current positions
        for clockToMove in clocksToMove {
            if let index = clocks.firstIndex(where: { $0.id == clockToMove.id }) {
                clocks.remove(at: index)
            }
        }
        
        // Calculate new position (accounting for current timezone at index 0)
        let newPosition = destination + 1
        
        // Insert clocks at new position
        for (index, clockToMove) in clocksToMove.enumerated() {
            let insertIndex = min(newPosition + index, clocks.count)
            clocks.insert(clockToMove, at: insertIndex)
        }
        
        updateDisplayOrder()
        saveClocks()
        HapticManager.shared.impact(.light)
    }
    
    private func updateDisplayOrder() {
        for (index, _) in clocks.enumerated() {
            clocks[index].displayOrder = index
        }
    }
    
    private func loadClocks() {
        guard let data = userDefaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WorldClock].self, from: data) else {
            return
        }
        clocks = decoded.sorted { $0.displayOrder < $1.displayOrder }
    }
    
    private func saveClocks() {
        guard let encoded = try? JSONEncoder().encode(clocks) else { return }
        userDefaults.set(encoded, forKey: storageKey)
    }
    
    private func startTimer() {
        timer = Foundation.Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            DispatchQueue.main.async {
                self.currentTime = Date()
            }
        }
    }
}

// MARK: - Native Calendar View
struct NativeCalendarView: UIViewRepresentable {
    @Binding var selectedDate: Date
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.availableDateRange = DateInterval(start: Date.distantPast, end: Date.distantFuture)
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: context.coordinator)
        calendarView.fontDesign = .rounded
        calendarView.tintColor = UIColor(BananaTheme.Colors.bananaYellow)
        
        // Configure for compact display
        calendarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        calendarView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        // Update selection if needed
        if let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
            selection.setSelected(components, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {
        var parent: NativeCalendarView
        
        init(_ parent: NativeCalendarView) {
            self.parent = parent
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            if let dateComponents = dateComponents,
               let date = Calendar.current.date(from: dateComponents) {
                parent.selectedDate = date
            }
        }
        
        func dateSelection(_ selection: UICalendarSelectionSingleDate, didDeselectDate dateComponents: DateComponents?) {
            // Handle deselection if needed
        }
    }
}

// MARK: - Custom Date Picker
struct CustomDatePicker: View {
    @Binding var selectedDate: Date
    @Binding var showingCalendar: Bool
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    private var selectedDateString: String {
        if isToday(selectedDate) {
            return "Today"
        } else {
            dateFormatter.dateFormat = "MMM d, yyyy"
            return dateFormatter.string(from: selectedDate)
        }
    }
    

    

    
    var body: some View {
        VStack(spacing: 0) {
            // Collapsed view (always visible) - compact and left-aligned
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingCalendar.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .foregroundColor(showingCalendar ? BananaTheme.Colors.bananaYellow : BananaTheme.Colors.bananaYellow)
                            .font(.body)
                        
                        Text(selectedDateString)
                            .font(.body)
                            .foregroundColor(showingCalendar ? BananaTheme.Colors.bananaYellow : .white)
                        
                        Image(systemName: showingCalendar ? "xmark" : "chevron.down")
                            .foregroundColor(BananaTheme.Colors.bananaYellow)
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Today button - only show when not today
                if !isToday(selectedDate) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = Date()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Today")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.bananaYellow)
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundColor(BananaTheme.Colors.bananaYellow)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    

    

    

    

    
    // MARK: - Helper Methods
    

    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
    

}

// MARK: - Preference Key for Scroll Tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

