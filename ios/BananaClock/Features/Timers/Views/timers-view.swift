//
//  TimersView.swift
//  BananaClock
//
//  Timers feature
//

import SwiftUI
import Foundation

struct TimersView: View {
    @StateObject private var viewModel = TimersViewModel()
    @EnvironmentObject var appState: AppState
    @State private var showingAddTimer = false

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
                    if viewModel.timers.isEmpty {
                        // Updated empty state to match World Clock style
                        VStack(spacing: BananaTheme.Spacing.lg) {
                            Image(systemName: "timer")
                                .font(.system(size: 64))
                                .foregroundColor(BananaTheme.Colors.textTertiary)
                            
                            Text("No Timers")
                                .font(.title2)
                                .foregroundColor(BananaTheme.Colors.textPrimary)
                            
                            Text("Create timers for cooking, workouts, eating bananas, and more.")
                                .font(.body)
                                .foregroundColor(BananaTheme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            // Quick presets
                            VStack(spacing: BananaTheme.Spacing.md) {
                                HStack(spacing: BananaTheme.Spacing.md) {
                                    ForEach(TimerPreset.defaults, id: \.duration) { preset in
                                        Button {
                                            viewModel.startTimer(
                                                duration: preset.duration,
                                                label: preset.defaultLabel,
                                                soundIdentifier: "radar"
                                            )
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
                            
                            BananaButton("Create Timer", icon: "plus") {
                                showingAddTimer = true
                            }
                            .frame(width: 200)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(.horizontal, BSpacing.lg)
                        .padding(.top, BSpacing.lg)
                    } else {
                        timersList
                    }
                }
                .navigationTitle("Banana Clock")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                
                // Bottom floating action bar for selection mode
                if isEditing && !viewModel.selectableTimers.isEmpty {
                    VStack {
                        Spacer()
                        
                        HStack(spacing: 16) {
                            Button {
                                if viewModel.selectedTimersCount == viewModel.selectableTimers.count {
                                    viewModel.deselectAll()
                                } else {
                                    viewModel.selectAll()
                                }
                            } label: {
                                Text(viewModel.selectedTimersCount == viewModel.selectableTimers.count ? "Deselect All" : "Select All")
                                    .font(.body.weight(.medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(BananaTheme.Colors.backgroundSecondary)
                                    .cornerRadius(BananaTheme.Layout.cornerRadius)
                            }
                            
                            if viewModel.selectedTimersCount > 0 {
                                Button {
                                    viewModel.deleteSelectedTimers()
                                } label: {
                                    Text("Delete Selected (\(viewModel.selectedTimersCount))")
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
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.9))
                                .ignoresSafeArea()
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTimer) {
            TimerCreationView { duration, label, soundIdentifier in
                viewModel.startTimer(duration: duration, label: label, soundIdentifier: soundIdentifier)
            }
        }

        .onAppear {
            viewModel.cleanupOldTimers()
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                // Clear selection when exiting edit mode
                viewModel.deselectAll()
            }
        }
    }
    
    // MARK: - Views
    
    private var timersList: some View {
        List {
            // Active timers
            if !viewModel.activeTimers.isEmpty {
                ForEach(viewModel.activeTimers) { timer in
                    TimerRow(
                        timer: timer, 
                        viewModel: viewModel,
                        onTap: {
                            if isEditing {
                                // In edit mode, toggle selection instead of doing nothing
                                viewModel.toggleSelection(for: timer)
                            }
                        },
                        isSelected: viewModel.isSelected(timer),
                        showSelection: isEditing
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSpacing(0)
                }
                .onDelete { indexSet in
                    viewModel.deleteTimers(at: indexSet, from: viewModel.activeTimers)
                }
            }
            
            // Recents header
            if !viewModel.recentTimers.isEmpty {
                HStack {
                    Text("Recents")
                        .font(BananaTheme.Typography.title3)
                        .foregroundColor(BananaTheme.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, BananaTheme.Spacing.sm)
                .padding(.horizontal, BananaTheme.Spacing.md)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            
            // Recents timers
            if !viewModel.recentTimers.isEmpty {
                ForEach(viewModel.recentTimers) { timer in
                    TimerRow(
                        timer: timer, 
                        viewModel: viewModel,
                        onTap: {
                            if isEditing {
                                // In edit mode, toggle selection instead of doing nothing
                                viewModel.toggleSelection(for: timer)
                            }
                        },
                        isSelected: viewModel.isSelected(timer),
                        showSelection: isEditing
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSpacing(0)
                }
                .onDelete { indexSet in
                    viewModel.deleteTimers(at: indexSet, from: viewModel.recentTimers)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !viewModel.selectableTimers.isEmpty {
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
                    showingAddTimer = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
            }
        }
    }
}

// MARK: - Timer Row
struct TimerRow: View {
    let timer: BananaTimer
    @ObservedObject var viewModel: TimersViewModel
    @State private var isButtonEnabled = true
    let onTap: () -> Void
    let isSelected: Bool
    let showSelection: Bool
    
    init(
        timer: BananaTimer,
        viewModel: TimersViewModel,
        onTap: @escaping () -> Void = {},
        isSelected: Bool = false,
        showSelection: Bool = false
    ) {
        self.timer = timer
        self.viewModel = viewModel
        self.onTap = onTap
        self.isSelected = isSelected
        self.showSelection = showSelection
    }
    
    private var endTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
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
            
            // Left side - Time display
            VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: BananaTheme.Spacing.xs) {
                    Text(timer.state == .finished || timer.state == .ready ? timer.formattedDuration : timer.formattedRemainingTime)
                        .font(.largeTitle)
                        .monospacedDigit()
                    
                    if timer.state == .running, let endTime = timer.endTime {
                        HStack(spacing: BananaTheme.Spacing.xxs) {
                            Image(systemName: "alarm")
                                .font(.system(size: 12))
                                .foregroundColor(BananaTheme.Colors.textSecondary)
                            
                            Text(endTimeFormatter.string(from: endTime))
                                .font(.system(size: 14))
                                .foregroundColor(BananaTheme.Colors.textSecondary)
                        }
                    }
                }
                
                Text(timer.label)
                    .font(.caption)
                    .foregroundColor(BananaTheme.Colors.textSecondary)
            }
            .allowsHitTesting(false)
            
            Spacer()
            
            // Right side - Controls (only show when not in selection mode)
            if !showSelection {
                HStack(spacing: BananaTheme.Spacing.md) {
                    // Progress ring (only for running/paused timers)
                    if timer.state == .running || timer.state == .paused {
                        ZStack {
                            CircularProgressView(
                                progress: timer.progress,
                                lineWidth: 4,
                                size: 60
                            )
                            
                            // Cancel button
                            Button {
                                guard isButtonEnabled else { return }
                                isButtonEnabled = false
                                viewModel.cancelTimer(timer)
                                
                                // Re-enable after a short delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isButtonEnabled = true
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.gray)
                                    .frame(width: 32, height: 32)
                                    .background(Color.black.opacity(0.7))
                                    .clipShape(Circle())
                            }
                            .allowsHitTesting(true)
                            .disabled(!isButtonEnabled)
                        }
                    }
                    
                    // Play/Pause/Repeat button
                    Button {
                        guard isButtonEnabled else { return }
                        isButtonEnabled = false
                        
                        switch timer.state {
                        case .ready:
                            viewModel.startTimer(timer)
                        case .running:
                            viewModel.pauseTimer(timer)
                        case .paused:
                            viewModel.resumeTimer(timer)
                        case .finished:
                            viewModel.repeatTimer(timer)
                        }
                        
                        // Re-enable after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isButtonEnabled = true
                        }
                    } label: {
                        Image(systemName: buttonIcon)
                            .font(.title3)
                            .foregroundColor(.black)
                            .frame(width: 60, height: 60)
                            .background(BananaTheme.Colors.bananaYellow)
                            .clipShape(Circle())
                    }
                    .allowsHitTesting(true)
                    .disabled(!isButtonEnabled)
                }
            }
        }
        .padding(.vertical, BananaTheme.Spacing.sm)
        .padding(.horizontal, BananaTheme.Spacing.md)
        .opacity(timer.state == .finished ? 0.7 : 1)
        .scaleEffect(timer.state == .finished ? 0.95 : 1)
        .animation(.easeInOut(duration: 0.3), value: timer.state)
        .onTapGesture {
            onTap()
        }
    }
    
    private var buttonIcon: String {
        switch timer.state {
        case .ready: return "play.fill"
        case .running: return "pause.fill"
        case .paused: return "play.fill"
        case .finished: return "arrow.clockwise"
        }
    }
}

// MARK: - Timer Creation View
struct TimerCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var label = ""
    @State private var selectedSound = "radar" // Default timer sound
    
    let onCreate: (TimeInterval, String, String) -> Void
    
    private var duration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
    
    private var isValid: Bool {
        duration > 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: BananaTheme.Spacing.xl) {
                    // Label input
                    VStack(alignment: .leading, spacing: BananaTheme.Spacing.xs) {
                        Text("Timer Name")
                            .font(.caption)
                            .foregroundColor(BananaTheme.Colors.textSecondary)
                        
                        TextField("Cooking, Workout, etc.", text: $label)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding()
                            .background(BananaTheme.Colors.backgroundSecondary)
                            .cornerRadius(BananaTheme.Layout.cornerRadius)
                    }
                    
                    // Time picker
                    HStack {
                        // Hours
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)h")
                                    .tag(hour)
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        
                        // Minutes
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)m")
                                    .tag(minute)
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        
                        // Seconds
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second)s")
                                    .tag(second)
                                    .foregroundColor(.white)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                    }
                    .frame(height: 200)
                    
                    // Sound selection
                    VStack(alignment: .leading, spacing: BananaTheme.Spacing.xs) {
                        Text("Timer Sound")
                            .font(.caption)
                            .foregroundColor(BananaTheme.Colors.textSecondary)
                        
                        BananaCard {
                            NavigationLink {
                                SoundSelectionView(selectedSound: $selectedSound)
                            } label: {
                                HStack {
                                    Text(AlarmSound.allCases.first(where: { $0.rawValue == selectedSound })?.displayName ?? "Radar")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(BananaTheme.Colors.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Quick presets
                    VStack(alignment: .leading, spacing: BananaTheme.Spacing.xs) {
                        Text("Quick Presets")
                            .font(.caption)
                            .foregroundColor(BananaTheme.Colors.textSecondary)
                        
                        HStack(spacing: BananaTheme.Spacing.md) {
                            ForEach(TimerPreset.defaults, id: \.duration) { preset in
                                Button {
                                    applyPreset(preset)
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
                    
                    Spacer()
                }
                .padding()
                .padding(.top, 24)
            }
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // Set navigation title color to white
                UINavigationBar.appearance().titleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 17, weight: .regular)
                ]
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Start") {
                        let timerLabel = label.isEmpty ? "Timer" : label
                        onCreate(duration, timerLabel, selectedSound)
                        dismiss()
                    }
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private func applyPreset(_ preset: TimerPreset) {
        let totalSeconds = Int(preset.duration)
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
        label = preset.defaultLabel
    }
}

// MARK: - Sound Selection View
struct SoundSelectionView: View {
    @Binding var selectedSound: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            List(AlarmSound.allCases, id: \.rawValue) { sound in
                Button {
                    selectedSound = sound.rawValue
                    AudioService.shared.playSound(sound.rawValue)
                    dismiss()
                } label: {
                    HStack {
                        Text(sound.displayName)
                            .foregroundColor(.white)
                        Spacer()
                        if selectedSound == sound.rawValue {
                            Image(systemName: "checkmark")
                                .foregroundColor(BananaTheme.Colors.bananaYellow)
                        }
                    }
                }
                .listRowBackground(BananaTheme.Colors.backgroundSecondary)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Timer Sound")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(BananaTheme.Colors.backgroundSecondary, lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    BananaTheme.Colors.bananaYellow,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Timer Model
struct BananaTimer: Identifiable, Codable {
    let id: UUID
    let label: String
    let duration: TimeInterval
    var remainingTime: TimeInterval
    var state: Timer.TimerState
    var startedAt: Date?
    var pausedAt: Date?
    var lastUsedAt: Date
    let soundIdentifier: String
    
    init(
        id: UUID = UUID(),
        label: String,
        duration: TimeInterval,
        remainingTime: TimeInterval? = nil,
        state: Timer.TimerState = .ready,
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        lastUsedAt: Date = Date(),
        soundIdentifier: String = "radar"
    ) {
        self.id = id
        self.label = label
        self.duration = duration
        self.remainingTime = remainingTime ?? duration
        self.state = state
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.lastUsedAt = lastUsedAt
        self.soundIdentifier = soundIdentifier
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return max(0, min(1, (duration - remainingTime) / duration))
    }
    
    var formattedRemainingTime: String {
        let totalSeconds = Int(remainingTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var endTime: Date? {
        guard state == .running, remainingTime > 0 else { return nil }
        return Date().addingTimeInterval(remainingTime)
    }
}

// MARK: - Timer Preset
struct TimerPreset {
    let label: String
    let duration: TimeInterval
    let defaultLabel: String
    
    static let defaults = [
        TimerPreset(label: "1 min", duration: 60, defaultLabel: "1 Min Timer"),
        TimerPreset(label: "5 min", duration: 300, defaultLabel: "5 Min Timer"),
        TimerPreset(label: "10 min", duration: 600, defaultLabel: "10 Min Timer")
    ]
}

// MARK: - View Model
@MainActor
class TimersViewModel: ObservableObject {
    @Published var timers: [BananaTimer] = []
    @Published var selectedTimers: Set<UUID> = []
    private var timerTasks: [UUID: Task<Void, Never>] = [:]
    
    private let timersKey = "SavedTimers"
    
    var navigationTitle: String { "Timers" }
    
    var activeTimers: [BananaTimer] {
        timers.filter { $0.state == .running || $0.state == .paused }
            .sorted { timer1, timer2 in
                // First sort by end time (running timers first, then paused)
                let timer1EndTime = timer1.state == .running ? (timer1.endTime ?? Date.distantFuture) : Date.distantFuture
                let timer2EndTime = timer2.state == .running ? (timer2.endTime ?? Date.distantFuture) : Date.distantFuture
                
                if timer1EndTime != timer2EndTime {
                    return timer1EndTime < timer2EndTime
                }
                
                // If end times are the same (both paused), sort by remaining time
                return timer1.remainingTime < timer2.remainingTime
            }
    }
    
    var recentTimers: [BananaTimer] {
        let inactiveTimers = timers.filter { $0.state == .finished || $0.state == .ready }
        
        // Group by duration and label, keeping only the most recent one
        var uniqueTimers: [BananaTimer] = []
        var seenCombinations: Set<String> = []
        
        // Sort by lastUsedAt descending to process most recent first
        let sortedTimers = inactiveTimers.sorted { $0.lastUsedAt > $1.lastUsedAt }
        
        for timer in sortedTimers {
            let combination = "\(timer.duration)_\(timer.label)"
            if !seenCombinations.contains(combination) {
                seenCombinations.insert(combination)
                uniqueTimers.append(timer)
            }
        }
        
        return uniqueTimers
    }
    
    // Computed properties for selection mode
    var isSelectionMode: Bool {
        !selectedTimers.isEmpty
    }
    
    var selectedTimersCount: Int {
        selectedTimers.count
    }
    
    var selectableTimers: [BananaTimer] {
        timers // All timers can be selected
    }
    
    init() {
        loadTimers()
    }
    
    func canAddTimer(isPremium: Bool) -> Bool {
        return true
    }
    
    func startTimer(duration: TimeInterval, label: String, soundIdentifier: String) {
        let timer = BananaTimer(
            label: label,
            duration: duration,
            state: .running,
            startedAt: Date(),
            lastUsedAt: Date(),
            soundIdentifier: soundIdentifier
        )
        timers.append(timer)
        startTimerTask(for: timer)
        saveTimers()
        HapticManager.shared.impact(.medium)
    }
    
    func startTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        // Only start if timer is in ready state
        guard timers[index].state == .ready else { return }
        
        timers[index].state = .running
        timers[index].startedAt = Date()
        timers[index].lastUsedAt = Date()
        
        startTimerTask(for: timers[index])
        saveTimers()
        HapticManager.shared.impact(.medium)
    }
    
    func pauseTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        // Only pause if timer is running
        guard timers[index].state == .running else { return }
        
        timers[index].state = .paused
        timers[index].pausedAt = Date()
        
        cancelTimerTask(for: timer.id)
        saveTimers()
        HapticManager.shared.impact(.light)
    }
    
    func resumeTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        // Only resume if timer is paused
        guard timers[index].state == .paused else { return }
        
        timers[index].state = .running
        timers[index].startedAt = Date()
        timers[index].pausedAt = nil
        timers[index].lastUsedAt = Date()
        
        startTimerTask(for: timers[index])
        saveTimers()
        HapticManager.shared.impact(.light)
    }
    
    func repeatTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        timers[index].state = .running
        timers[index].remainingTime = timer.duration
        timers[index].startedAt = Date()
        timers[index].pausedAt = nil
        timers[index].lastUsedAt = Date()
        
        startTimerTask(for: timers[index])
        saveTimers()
        HapticManager.shared.impact(.medium)
    }
    
    func cancelTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        cancelTimerTask(for: timer.id)
        timers[index].state = .finished
        timers[index].remainingTime = timer.duration
        timers[index].lastUsedAt = Date()
        saveTimers()
        HapticManager.shared.impact(.light)
        
        // Force UI update
        objectWillChange.send()
    }
    
    func deleteTimers(at offsets: IndexSet, from sourceArray: [BananaTimer]) {
        for index in offsets {
            let timer = sourceArray[index]
            cancelTimerTask(for: timer.id)
            timers.removeAll { $0.id == timer.id }
        }
        saveTimers()
        HapticManager.shared.impact(.light)
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(for timer: BananaTimer) {
        if selectedTimers.contains(timer.id) {
            selectedTimers.remove(timer.id)
        } else {
            selectedTimers.insert(timer.id)
        }
    }
    
    func selectAll() {
        selectedTimers = Set(selectableTimers.map { $0.id })
    }
    
    func deselectAll() {
        selectedTimers.removeAll()
    }
    
    func isSelected(_ timer: BananaTimer) -> Bool {
        selectedTimers.contains(timer.id)
    }
    
    // MARK: - Bulk Operations
    
    func deleteSelectedTimers() {
        let timersToDelete = timers.filter { selectedTimers.contains($0.id) }
        
        for timer in timersToDelete {
            cancelTimerTask(for: timer.id)
            timers.removeAll { $0.id == timer.id }
        }
        
        selectedTimers.removeAll() // Clear selection after deletion
        saveTimers()
        HapticManager.shared.impact(.light)
    }
    
    func cleanupOldTimers() {
        let oneWeekAgo = Date().addingTimeInterval(-10 * 24 * 60 * 60)
        let oldTimerCount = timers.count
        
        timers.removeAll { timer in
            timer.lastUsedAt < oneWeekAgo && 
            (timer.state == .finished || timer.state == .ready)
        }
        
        if timers.count != oldTimerCount {
            saveTimers()
        }
    }
    
    private func startTimerTask(for timer: BananaTimer) {
        cancelTimerTask(for: timer.id)
        
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
                await MainActor.run {
                    self?.updateTimer(timer.id)
                }
            }
        }
        
        timerTasks[timer.id] = task
    }
    
    private func cancelTimerTask(for timerId: UUID) {
        timerTasks[timerId]?.cancel()
        timerTasks[timerId] = nil
    }
    
    private func updateTimer(_ timerId: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == timerId }),
              timers[index].state == .running else { return }
        
        timers[index].remainingTime -= 0.1
        
        if timers[index].remainingTime <= 0 {
            timers[index].remainingTime = 0
            timers[index].state = .finished
            cancelTimerTask(for: timerId)
            
            // Play sound and haptic
            AudioService.shared.playSound(timers[index].soundIdentifier)
            HapticManager.shared.notification(.success)
            
            saveTimers()
        }
    }
    
    // MARK: - Persistence
    private func saveTimers() {
        // Clean up duplicate inactive timers before saving
        cleanupDuplicateInactiveTimers()
        
        if let encoded = try? JSONEncoder().encode(timers) {
            UserDefaults.standard.set(encoded, forKey: timersKey)
        }
    }
    
    private func cleanupDuplicateInactiveTimers() {
        let inactiveTimers = timers.filter { $0.state == .finished || $0.state == .ready }
        let activeTimers = timers.filter { $0.state == .running || $0.state == .paused }
        
        // Group inactive timers by duration and label, keeping only the most recent one
        var uniqueInactiveTimers: [BananaTimer] = []
        var seenCombinations: Set<String> = []
        
        // Sort by lastUsedAt descending to process most recent first
        let sortedInactiveTimers = inactiveTimers.sorted { $0.lastUsedAt > $1.lastUsedAt }
        
        for timer in sortedInactiveTimers {
            let combination = "\(timer.duration)_\(timer.label)"
            if !seenCombinations.contains(combination) {
                seenCombinations.insert(combination)
                uniqueInactiveTimers.append(timer)
            }
        }
        
        // Reconstruct timers array with active timers + deduplicated inactive timers
        timers = activeTimers + uniqueInactiveTimers
    }
    
    private func loadTimers() {
        guard let data = UserDefaults.standard.data(forKey: timersKey),
              let decoded = try? JSONDecoder().decode([BananaTimer].self, from: data) else {
            return
        }
        
        timers = decoded
        
        // Restart any running timers
        for timer in timers where timer.state == .running {
            startTimerTask(for: timer)
        }
        
        // Clean up old timers on load
        cleanupOldTimers()
    }
    
    deinit {
        // Cancel all timer tasks
        for task in timerTasks.values {
            task.cancel()
        }
    }
}



// MARK: - Sound Manager
// Note: AudioService is defined in audio-service.swift
// AlarmSound enum is expected to be defined in Core/Models/alarm-model.swift