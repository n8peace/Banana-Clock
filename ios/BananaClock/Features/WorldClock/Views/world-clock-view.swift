//
//  WorldClockView.swift
//  BananaClock
//
//  World clock feature
//

import SwiftUI
import Foundation
import Combine

struct WorldClockView: View {
    @StateObject private var viewModel = WorldClockViewModel()
    @State private var showingAddCity = false
    @State private var isEditing = false
    

    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page title - positioned at top of screen
                Text(viewModel.navigationTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, BSpacing.md)
                    .padding(.top, BSpacing.sm)
                    .padding(.bottom, BSpacing.lg)
                
                NavigationStack {
                    VStack(spacing: 0) {
                        // Current timezone always at top
                        if let currentClock = viewModel.currentTimezoneClock {
                            WorldClockRow(clock: currentClock, viewModel: viewModel)
                        }
                        
                        // Empty state or other clocks
                        if viewModel.otherClocks.isEmpty {
                            ScrollView {
                                emptyStateView()
                                    .frame(maxWidth: .infinity, minHeight: 400)
                            }
                        } else {
                            clocksList
                        }
                    }
                }
                .navigationTitle("BANANA")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
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
        }
    }
    
    // MARK: - Views
    
    private var timezoneConverterView: some View {
        VStack(spacing: BananaTheme.Spacing.md) {
            // Timezone Converter Label - centered
            Text("Timezone Converter")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, BananaTheme.Spacing.md)
            
            // Converter Box
            VStack(spacing: 8) {
                // Top row with date picker and time display
                HStack {
                    // Date Picker in top left
                    VStack(alignment: .leading, spacing: 4) {
                        DatePicker(
                            "Select Date",
                            selection: $viewModel.selectedDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .accentColor(viewModel.isConverterActive ? BananaTheme.Colors.bananaYellow : .gray)
                        
                        // Reset button - only show when date isn't today
                        if !viewModel.isToday {
                            Button {
                                viewModel.selectedDate = Date()
                                HapticManager.shared.impact(.light)
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: "gobackward")
                                        .font(.caption2)
                                    Text("Today")
                                        .font(.caption2)
                                }
                                .foregroundColor(viewModel.isConverterActive ? BananaTheme.Colors.bananaYellow : .gray)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Time display with countdown
                    HStack {
                        Text(viewModel.selectedTimeString)
                            .font(.title2.weight(.medium))
                            .foregroundColor(viewModel.isConverterActive ? BananaTheme.Colors.bananaYellow : .gray)
                            .monospacedDigit()
                        
                        // Countdown circle
                        if viewModel.isConverterActive && viewModel.countdownSeconds > 0 {
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
                    }
                }
                
                // Slider
                Slider(
                    value: $viewModel.timeSliderValue,
                    in: 0...1,
                    step: 1.0/96 // 15-minute intervals (24 hours * 4 intervals per hour)
                ) { editing in
                    viewModel.handleSliderEditing(editing)
                }
                .accentColor(viewModel.isConverterActive ? BananaTheme.Colors.bananaYellow : .gray)
                
                // Time range labels
                HStack {
                    Text("00:00")
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("23:59")
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                }
                .padding(.horizontal, BananaTheme.Spacing.sm)
            }
            .padding(.horizontal, BananaTheme.Spacing.md)
            .padding(.vertical, BananaTheme.Spacing.sm)
            .background(BananaTheme.Colors.backgroundSecondary)
            .cornerRadius(BananaTheme.Layout.cornerRadius)
            .padding(.horizontal, BananaTheme.Spacing.md)
        }
        .padding(.vertical, BananaTheme.Spacing.md)
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
                WorldClockRow(clock: clock, viewModel: viewModel)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
            .onDelete { indexSet in
                viewModel.deleteClocks(at: indexSet)
            }
            .onMove { source, destination in
                viewModel.moveClocks(from: source, to: destination)
            }
            
            // Timezone Converter (shows when additional timezones exist) - after last timezone
            if !viewModel.otherClocks.isEmpty {
                timezoneConverterView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, isEditing ? .constant(.active) : .constant(.inactive))
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !viewModel.otherClocks.isEmpty {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
                .foregroundColor(BananaTheme.Colors.bananaYellow)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingAddCity = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
            }
        }
    }
}

// MARK: - World Clock Row
struct WorldClockRow: View {
    let clock: WorldClock
    @ObservedObject var viewModel: WorldClockViewModel
    
    var body: some View {
        HStack {
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
            formatter.timeStyle = .medium
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
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d"
            formatter.timeZone = clock.timeZone
            return formatter.string(from: baseTime)
        }
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
            // Regular city offset
            let offset = clock.timeZone.secondsFromGMT() - TimeZone.current.secondsFromGMT()
            let hours = offset / 3600
            
            if hours == 0 {
                return "Your Time"
            } else {
                let sign = hours > 0 ? "+" : ""
                return "\(sign)\(hours) hours"
            }
        }
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
    let onSelect: (City) -> Void
    
    enum SortMode: String, CaseIterable {
        case utc = "UTC +/-"
        case alphabetical = "A-Z"
    }
    
    private var filteredCities: [City] {
        let regularCities = searchText.isEmpty ? City.popularCities : City.allCities.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.country.localizedCaseInsensitiveContains(searchText)
        }
        
        let planets = City.planets
        
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
        
        // Add planets section to index
        titles.append("🪐")
        
        return titles
    }
    
    private func scrollToSection(_ section: String) {
        scrollTarget = section
        HapticManager.shared.impact(.light)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sort Mode Toggle
                    HStack(spacing: 0) {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    sortMode = mode
                                }
                            } label: {
                                Text(mode.rawValue)
                                    .font(.headline)
                                    .fontWeight(.medium)
                                    .foregroundColor(sortMode == mode ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(sortMode == mode ? BananaTheme.Colors.bananaYellow : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
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
                                        .id(section)
                                ) {
                                    ForEach(cities) { city in
                                        Button {
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
                                .padding(.trailing, 8)
                            }
                            Spacer()
                        }
                    )
                }
            }
            .navigationTitle("Add City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
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
        City(name: "Los Angeles", country: "United States", timeZoneIdentifier: "America/Los_Angeles", isPlanet: false),
        City(name: "Chicago", country: "United States", timeZoneIdentifier: "America/Chicago", isPlanet: false),
        City(name: "Denver", country: "United States", timeZoneIdentifier: "America/Denver", isPlanet: false),
        City(name: "Phoenix", country: "United States", timeZoneIdentifier: "America/Phoenix", isPlanet: false),
        City(name: "Anchorage", country: "United States", timeZoneIdentifier: "America/Anchorage", isPlanet: false),
        City(name: "Honolulu", country: "United States", timeZoneIdentifier: "Pacific/Honolulu", isPlanet: false),
        City(name: "Toronto", country: "Canada", timeZoneIdentifier: "America/Toronto", isPlanet: false),
        City(name: "Vancouver", country: "Canada", timeZoneIdentifier: "America/Vancouver", isPlanet: false),
        City(name: "Mexico City", country: "Mexico", timeZoneIdentifier: "America/Mexico_City", isPlanet: false),
        
        // South America
        City(name: "São Paulo", country: "Brazil", timeZoneIdentifier: "America/Sao_Paulo", isPlanet: false),
        City(name: "Buenos Aires", country: "Argentina", timeZoneIdentifier: "America/Argentina/Buenos_Aires", isPlanet: false),
        City(name: "Santiago", country: "Chile", timeZoneIdentifier: "America/Santiago", isPlanet: false),
        City(name: "Lima", country: "Peru", timeZoneIdentifier: "America/Lima", isPlanet: false),
        City(name: "Bogotá", country: "Colombia", timeZoneIdentifier: "America/Bogota", isPlanet: false),
        City(name: "Caracas", country: "Venezuela", timeZoneIdentifier: "America/Caracas", isPlanet: false),
        
        // Europe
        City(name: "London", country: "United Kingdom", timeZoneIdentifier: "Europe/London", isPlanet: false),
        City(name: "Paris", country: "France", timeZoneIdentifier: "Europe/Paris", isPlanet: false),
        City(name: "Berlin", country: "Germany", timeZoneIdentifier: "Europe/Berlin", isPlanet: false),
        City(name: "Rome", country: "Italy", timeZoneIdentifier: "Europe/Rome", isPlanet: false),
        City(name: "Madrid", country: "Spain", timeZoneIdentifier: "Europe/Madrid", isPlanet: false),
        City(name: "Amsterdam", country: "Netherlands", timeZoneIdentifier: "Europe/Amsterdam", isPlanet: false),
        City(name: "Stockholm", country: "Sweden", timeZoneIdentifier: "Europe/Stockholm", isPlanet: false),
        City(name: "Oslo", country: "Norway", timeZoneIdentifier: "Europe/Oslo", isPlanet: false),
        City(name: "Copenhagen", country: "Denmark", timeZoneIdentifier: "Europe/Copenhagen", isPlanet: false),
        City(name: "Helsinki", country: "Finland", timeZoneIdentifier: "Europe/Helsinki", isPlanet: false),
        City(name: "Warsaw", country: "Poland", timeZoneIdentifier: "Europe/Warsaw", isPlanet: false),
        City(name: "Prague", country: "Czech Republic", timeZoneIdentifier: "Europe/Prague", isPlanet: false),
        City(name: "Vienna", country: "Austria", timeZoneIdentifier: "Europe/Vienna", isPlanet: false),
        City(name: "Budapest", country: "Hungary", timeZoneIdentifier: "Europe/Budapest", isPlanet: false),
        City(name: "Bucharest", country: "Romania", timeZoneIdentifier: "Europe/Bucharest", isPlanet: false),
        City(name: "Sofia", country: "Bulgaria", timeZoneIdentifier: "Europe/Sofia", isPlanet: false),
        City(name: "Athens", country: "Greece", timeZoneIdentifier: "Europe/Athens", isPlanet: false),
        City(name: "Istanbul", country: "Turkey", timeZoneIdentifier: "Europe/Istanbul", isPlanet: false),
        City(name: "Moscow", country: "Russia", timeZoneIdentifier: "Europe/Moscow", isPlanet: false),
        City(name: "Kiev", country: "Ukraine", timeZoneIdentifier: "Europe/Kiev", isPlanet: false),
        City(name: "Minsk", country: "Belarus", timeZoneIdentifier: "Europe/Minsk", isPlanet: false),
        City(name: "Riga", country: "Latvia", timeZoneIdentifier: "Europe/Riga", isPlanet: false),
        City(name: "Tallinn", country: "Estonia", timeZoneIdentifier: "Europe/Tallinn", isPlanet: false),
        City(name: "Vilnius", country: "Lithuania", timeZoneIdentifier: "Europe/Vilnius", isPlanet: false),
        
        // Africa
        City(name: "Cairo", country: "Egypt", timeZoneIdentifier: "Africa/Cairo", isPlanet: false),
        City(name: "Johannesburg", country: "South Africa", timeZoneIdentifier: "Africa/Johannesburg", isPlanet: false),
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
        City(name: "Beijing", country: "China", timeZoneIdentifier: "Asia/Shanghai", isPlanet: false),
        City(name: "Hong Kong", country: "China", timeZoneIdentifier: "Asia/Hong_Kong", isPlanet: false),
        City(name: "Seoul", country: "South Korea", timeZoneIdentifier: "Asia/Seoul", isPlanet: false),
        City(name: "Singapore", country: "Singapore", timeZoneIdentifier: "Asia/Singapore", isPlanet: false),
        City(name: "Bangkok", country: "Thailand", timeZoneIdentifier: "Asia/Bangkok", isPlanet: false),
        City(name: "Jakarta", country: "Indonesia", timeZoneIdentifier: "Asia/Jakarta", isPlanet: false),
        City(name: "Manila", country: "Philippines", timeZoneIdentifier: "Asia/Manila", isPlanet: false),
        City(name: "Kuala Lumpur", country: "Malaysia", timeZoneIdentifier: "Asia/Kuala_Lumpur", isPlanet: false),
        City(name: "Hanoi", country: "Vietnam", timeZoneIdentifier: "Asia/Ho_Chi_Minh", isPlanet: false),
        City(name: "Yangon", country: "Myanmar", timeZoneIdentifier: "Asia/Yangon", isPlanet: false),
        City(name: "Phnom Penh", country: "Cambodia", timeZoneIdentifier: "Asia/Phnom_Penh", isPlanet: false),
        City(name: "Vientiane", country: "Laos", timeZoneIdentifier: "Asia/Vientiane", isPlanet: false),
        City(name: "Dhaka", country: "Bangladesh", timeZoneIdentifier: "Asia/Dhaka", isPlanet: false),
        City(name: "Kathmandu", country: "Nepal", timeZoneIdentifier: "Asia/Kathmandu", isPlanet: false),
        City(name: "Colombo", country: "Sri Lanka", timeZoneIdentifier: "Asia/Colombo", isPlanet: false),
        City(name: "Mumbai", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "New Delhi", country: "India", timeZoneIdentifier: "Asia/Kolkata", isPlanet: false),
        City(name: "Karachi", country: "Pakistan", timeZoneIdentifier: "Asia/Karachi", isPlanet: false),
        City(name: "Tashkent", country: "Uzbekistan", timeZoneIdentifier: "Asia/Tashkent", isPlanet: false),
        City(name: "Almaty", country: "Kazakhstan", timeZoneIdentifier: "Asia/Almaty", isPlanet: false),
        City(name: "Bishkek", country: "Kyrgyzstan", timeZoneIdentifier: "Asia/Bishkek", isPlanet: false),
        City(name: "Dushanbe", country: "Tajikistan", timeZoneIdentifier: "Asia/Dushanbe", isPlanet: false),
        City(name: "Ashgabat", country: "Turkmenistan", timeZoneIdentifier: "Asia/Ashgabat", isPlanet: false),
        City(name: "Baku", country: "Azerbaijan", timeZoneIdentifier: "Asia/Baku", isPlanet: false),
        City(name: "Tbilisi", country: "Georgia", timeZoneIdentifier: "Asia/Tbilisi", isPlanet: false),
        City(name: "Yerevan", country: "Armenia", timeZoneIdentifier: "Asia/Yerevan", isPlanet: false),
        City(name: "Tehran", country: "Iran", timeZoneIdentifier: "Asia/Tehran", isPlanet: false),
        City(name: "Baghdad", country: "Iraq", timeZoneIdentifier: "Asia/Baghdad", isPlanet: false),
        City(name: "Riyadh", country: "Saudi Arabia", timeZoneIdentifier: "Asia/Riyadh", isPlanet: false),
        City(name: "Kuwait City", country: "Kuwait", timeZoneIdentifier: "Asia/Kuwait", isPlanet: false),
        City(name: "Doha", country: "Qatar", timeZoneIdentifier: "Asia/Qatar", isPlanet: false),
        City(name: "Abu Dhabi", country: "UAE", timeZoneIdentifier: "Asia/Dubai", isPlanet: false),
        City(name: "Muscat", country: "Oman", timeZoneIdentifier: "Asia/Muscat", isPlanet: false),
        City(name: "Sana'a", country: "Yemen", timeZoneIdentifier: "Asia/Aden", isPlanet: false),
        City(name: "Amman", country: "Jordan", timeZoneIdentifier: "Asia/Amman", isPlanet: false),
        City(name: "Beirut", country: "Lebanon", timeZoneIdentifier: "Asia/Beirut", isPlanet: false),
        City(name: "Damascus", country: "Syria", timeZoneIdentifier: "Asia/Damascus", isPlanet: false),
        City(name: "Jerusalem", country: "Israel", timeZoneIdentifier: "Asia/Jerusalem", isPlanet: false),
        City(name: "Nicosia", country: "Cyprus", timeZoneIdentifier: "Asia/Nicosia", isPlanet: false),
        City(name: "Yekaterinburg", country: "Russia", timeZoneIdentifier: "Asia/Yekaterinburg", isPlanet: false),
        City(name: "Novosibirsk", country: "Russia", timeZoneIdentifier: "Asia/Novosibirsk", isPlanet: false),
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
        City(name: "Honolulu", country: "United States", timeZoneIdentifier: "Pacific/Honolulu", isPlanet: false),
        City(name: "Anchorage", country: "United States", timeZoneIdentifier: "America/Anchorage", isPlanet: false),
        
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
    
    private let userDefaults = UserDefaults.standard
    private let storageKey = "worldClocks"
    private var timer: Foundation.Timer?
    private var converterTimer: Foundation.Timer?
    private var countdownTimer: Foundation.Timer?
    
    // Computed properties for current timezone and other clocks
    var currentTimezoneClock: WorldClock? {
        let currentTimeZoneId = TimeZone.current.identifier
        return clocks.first { $0.timeZoneIdentifier == currentTimeZoneId }
    }
    
    var otherClocks: [WorldClock] {
        let currentTimeZoneId = TimeZone.current.identifier
        return clocks.filter { $0.timeZoneIdentifier != currentTimeZoneId }
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
        return Double(3 - countdownSeconds) / 3.0
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
        return hasPlanet ? "🪐 Planetary Clock" : "World Clock"
    }
    
    func handleSliderEditing(_ editing: Bool) {
        if editing {
            // User started touching the slider
            isConverterActive = true
            countdownSeconds = 0
            converterTimer?.invalidate()
            countdownTimer?.invalidate()
        } else {
            // User stopped touching the slider
            HapticManager.shared.impact(.light)
            
            // Start countdown
            countdownSeconds = 3
            startCountdown()
            
            // Start 3-second timer to deactivate converter
            converterTimer?.invalidate()
            converterTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                DispatchQueue.main.async {
                    self.isConverterActive = false
                    self.countdownSeconds = 0
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