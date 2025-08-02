//
//  TimersView.swift
//  BananaClock
//
//  Timers feature with enhanced UI and integrated timer creation
//

import SwiftUI
import Foundation

struct TimersView: View {
    @StateObject private var viewModel = TimersViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var liveActivityService: LiveActivityService
    @State private var showingAddTimer = false

    @State private var isEditing = false
    @State private var glowAnimation = false
    
    // MARK: - Views
    
    private var timersList: some View {
        List {
            // Active timers
            if !viewModel.activeTimers.isEmpty {
                ForEach(viewModel.activeTimers) { timer in
                    TimerRow(
                        timer: timer, 
                        viewModel: viewModel,
                        isSelected: viewModel.isSelected(timer),
                        showSelection: isEditing,
                        onTap: {
                            if isEditing {
                                viewModel.toggleSelection(for: timer)
                            }
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowSpacing(0)
                }
                .onDelete { indexSet in
                    let timersToDelete = indexSet.map { viewModel.activeTimers[$0] }
                    for timer in timersToDelete {
                        viewModel.cancelTimer(timer)
                    }
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
                        isSelected: viewModel.isSelected(timer),
                        showSelection: isEditing,
                        onTap: {
                            if isEditing {
                                viewModel.toggleSelection(for: timer)
                            }
                        }
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
    
    var body: some View {
        ZStack {
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
                                                soundIdentifier: "timer_complete"
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
                .navigationTitle("⏲️ Timers")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
            
            // Bottom floating action bar for selection mode - positioned absolutely
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
            glowAnimation = true
        }
        .onChange(of: isEditing) { _, newValue in
            if !newValue {
                // Clear selection when exiting edit mode
                viewModel.deselectAll()
            }
        }
    }
}
}

// MARK: - Timer Row
struct TimerRow: View {
    let timer: BananaTimer
    @ObservedObject var viewModel: TimersViewModel
    let isSelected: Bool
    let showSelection: Bool
    let onTap: () -> Void
    
    init(
        timer: BananaTimer,
        viewModel: TimersViewModel,
        isSelected: Bool = false,
        showSelection: Bool = false,
        onTap: @escaping () -> Void = {}
    ) {
        self.timer = timer
        self.viewModel = viewModel
        self.isSelected = isSelected
        self.showSelection = showSelection
        self.onTap = onTap
    }
    
    var body: some View {
        HStack(spacing: BananaTheme.Spacing.md) {
            // Selection checkbox zone - only in edit mode
            if showSelection {
                CheckboxButton(isSelected: isSelected) {
                    onTap()
                }
            }
            
            // Timer info zone - no interactions
            TimerInfoSection(timer: timer)
            
            Spacer()
            
            // Buttons zone - only in normal mode
            if !showSelection {
                TimerControlButtons(
                    timer: timer,
                    viewModel: viewModel
                )
            }
        }
        .padding(.vertical, BananaTheme.Spacing.sm)
        .padding(.horizontal, BananaTheme.Spacing.md)
        .opacity(timer.state == .finished ? 0.7 : 1)
        .animation(.easeInOut(duration: 0.3), value: timer.state)
        // No tap gestures on the main HStack!
    }
}

// MARK: - Checkbox Button
struct CheckboxButton: View {
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? BananaTheme.Colors.bananaYellow : BananaTheme.Colors.textSecondary)
                .frame(width: 44, height: 44) // Larger tap target
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Timer Info Section
struct TimerInfoSection: View {
    let timer: BananaTimer
    
    private var endTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var timeDisplay: String {
        timer.state == .finished || timer.state == .ready ? timer.formattedDuration : timer.formattedRemainingTime
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
            // Time display
            HStack(alignment: .firstTextBaseline, spacing: BananaTheme.Spacing.xs) {
                Text(timeDisplay)
                    .font(.largeTitle)
                    .monospacedDigit()
                
                if timer.state == .running, let endTime = timer.endTime {
                    EndTimeDisplay(endTime: endTime, formatter: endTimeFormatter)
                }
            }
            
            // Timer label
            Text(timer.label)
                .font(.caption)
                .foregroundColor(BananaTheme.Colors.textSecondary)
        }
        // No gestures here - purely display
    }
}

// MARK: - End Time Display
struct EndTimeDisplay: View {
    let endTime: Date
    let formatter: DateFormatter
    
    var body: some View {
        HStack(spacing: BananaTheme.Spacing.xxs) {
            Image(systemName: "alarm")
                .font(.system(size: 12))
                .foregroundColor(BananaTheme.Colors.textSecondary)
            
            Text(formatter.string(from: endTime))
                .font(.system(size: 14))
                .foregroundColor(BananaTheme.Colors.textSecondary)
        }
    }
}

// MARK: - Timer Control Buttons
struct TimerControlButtons: View {
    let timer: BananaTimer
    @ObservedObject var viewModel: TimersViewModel
    @State private var isButtonEnabled = true
    
    var body: some View {
        HStack(spacing: BananaTheme.Spacing.md) {
            // Progress ring with cancel button (for running/paused)
            if timer.state == .running || timer.state == .paused {
                ProgressCancelButton(
                    progress: timer.progress,
                    isEnabled: isButtonEnabled,
                    action: {
                        performAction {
                            viewModel.cancelTimer(timer)
                        }
                    }
                )
            }
            
            // Main action button
            ActionButton(
                icon: buttonIcon,
                isEnabled: isButtonEnabled,
                action: {
                    performAction {
                        handleMainAction()
                    }
                }
            )
        }
    }
    
    private func performAction(_ action: () -> Void) {
        guard isButtonEnabled else { return }
        isButtonEnabled = false
        action()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isButtonEnabled = true
        }
    }
    
    private func handleMainAction() {
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

// MARK: - Progress Cancel Button
struct ProgressCancelButton: View {
    let progress: Double
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        ZStack {
            CircularProgressView(
                progress: progress,
                lineWidth: 4,
                size: 60
            )
            
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }
            .disabled(!isEnabled)
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.black)
                .frame(width: 60, height: 60)
                .background(BananaTheme.Colors.bananaYellow)
                .clipShape(Circle())
        }
        .disabled(!isEnabled)
        .buttonStyle(PlainButtonStyle())
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

// MARK: - Timer Creation View
struct TimerCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    @State private var label = ""
    @State private var selectedSound = "timer_complete" // Default timer sound
    
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
                                    let soundName = AlarmSound.allCases.first(where: { $0.rawValue == selectedSound })?.displayName ?? "Timer Complete"
                                    Text(soundName)
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

// MARK: - Sound Manager
// Note: AudioService is defined in audio-service.swift
// AlarmSound enum is expected to be defined in Core/Models/alarm-model.swift