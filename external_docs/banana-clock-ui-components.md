# Banana Clock - UI Component Library & Design System

## 🎨 Design Philosophy
Native iOS feel with subtle Banana personality. Every component should feel like it belongs in iOS while maintaining our unique identity through color, motion, and micro-interactions.

---

## 🎨 Color System

### Core Palette
```swift
// BrandColors.swift
extension Color {
    // Primary
    static let bananaYellow = Color(hex: "#FDE043")
    static let bananaYellowDark = Color(hex: "#F5D020") // For pressed states
    
    // Backgrounds
    static let backgroundPrimary = Color.black
    static let backgroundSecondary = Color(white: 0.1) // Elevated surfaces
    static let backgroundTertiary = Color(white: 0.15) // Cards
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.5)
    static let textDisabled = Color(white: 0.3)
    
    // System
    static let systemGray = Color(white: 0.5)
    static let divider = Color(white: 0.2)
    static let overlay = Color.black.opacity(0.5)
    
    // Semantic
    static let success = Color.systemGreen
    static let warning = Color.systemOrange
    static let error = Color.systemRed
    static let info = Color.systemBlue
}

// Dark Mode Support
struct BananaColorScheme: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(.dark) // Always dark for v1
    }
}
```

### Usage Guidelines
- **Banana Yellow**: Primary actions, selected states, accents
- **White**: Primary text, icons
- **Grays**: Secondary elements, disabled states
- **System Colors**: Status indicators only

---

## 📐 Spacing System

```swift
// Spacing.swift
enum BSpacing {
    /// 4pt
    static let xxs: CGFloat = 4
    /// 8pt
    static let xs: CGFloat = 8
    /// 12pt
    static let sm: CGFloat = 12
    /// 16pt
    static let md: CGFloat = 16
    /// 24pt
    static let lg: CGFloat = 24
    /// 32pt
    static let xl: CGFloat = 32
    /// 48pt
    static let xxl: CGFloat = 48
    /// 64pt
    static let xxxl: CGFloat = 64
}

// Layout Guides
enum BLayout {
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let minimumTapTarget: CGFloat = 44
    static let tabBarHeight: CGFloat = 49
    static let navigationBarHeight: CGFloat = 44
}
```

---

## 🔤 Typography

```swift
// Typography.swift
extension Font {
    // Display
    static let displayLarge = Font.system(size: 80, weight: .thin, design: .rounded)
    static let displayMedium = Font.system(size: 60, weight: .thin, design: .rounded)
    static let displaySmall = Font.system(size: 48, weight: .light, design: .rounded)
    
    // Titles
    static let title1 = Font.system(size: 34, weight: .bold, design: .default)
    static let title2 = Font.system(size: 28, weight: .semibold, design: .default)
    static let title3 = Font.system(size: 22, weight: .semibold, design: .default)
    
    // Body
    static let bodyLarge = Font.system(size: 19, weight: .regular, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 15, weight: .regular, design: .default)
    
    // UI Elements
    static let button = Font.system(size: 17, weight: .semibold, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let footnote = Font.system(size: 12, weight: .regular, design: .default)
    
    // Special
    static let alarmTime = Font.system(size: 80, weight: .thin, design: .rounded)
    static let timerDisplay = Font.system(size: 70, weight: .ultraLight, design: .monospaced)
}

// Text Styles
struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .foregroundColor(.textPrimary)
    }
}

struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(.textPrimary)
            .lineSpacing(4)
    }
}

struct CaptionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(.textSecondary)
    }
}
```

---

## 🎭 Animation System

```swift
// Animations.swift
extension Animation {
    static let bananaBounce = Animation.spring(
        response: 0.4,
        dampingFraction: 0.6,
        blendDuration: 0
    )
    
    static let bananaSmooth = Animation.easeInOut(duration: 0.3)
    static let bananaQuick = Animation.easeOut(duration: 0.2)
    static let bananaSubtle = Animation.easeInOut(duration: 0.15)
}

// Haptic Feedback
enum BananaHaptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
```

---

## 🧩 Core Components

### 1. BananaButton
```swift
// Primary action button with banana personality
struct BananaButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let style: ButtonStyle
    
    @State private var isPressed = false
    
    enum ButtonStyle {
        case primary, secondary, tertiary, destructive
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            BananaHaptics.impact(.light)
            action()
        }) {
            HStack(spacing: BSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(.button)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.bananaQuick) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? .bananaYellowDark : .bananaYellow
        case .secondary:
            return .backgroundSecondary
        case .tertiary:
            return .clear
        case .destructive:
            return .error
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .black
        case .secondary, .tertiary:
            return .textPrimary
        case .destructive:
            return .white
        }
    }
}

// Usage
BananaButton("Set Alarm", icon: "alarm") {
    // Action
}
```

### 2. BananaCard
```swift
struct BananaCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = BLayout.cardPadding
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.backgroundTertiary)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

// Usage
BananaCard {
    VStack(alignment: .leading, spacing: BSpacing.sm) {
        Text("Next Alarm")
            .font(.caption)
            .foregroundColor(.textSecondary)
        Text("6:30 AM")
            .font(.title1)
            .foregroundColor(.textPrimary)
    }
}
```

### 3. BananaToggle
```swift
struct BananaToggle: View {
    @Binding var isOn: Bool
    let label: String?
    
    var body: some View {
        Toggle(isOn: $isOn) {
            if let label = label {
                Text(label)
                    .font(.body)
                    .foregroundColor(.textPrimary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: .bananaYellow))
        .onChange(of: isOn) { _ in
            BananaHaptics.selection()
        }
    }
}
```

### 4. TimeDisplay
```swift
struct TimeDisplay: View {
    let time: Date
    let style: DisplayStyle
    
    enum DisplayStyle {
        case alarm, timer, worldClock
    }
    
    private var formatter: DateFormatter {
        let formatter = DateFormatter()
        switch style {
        case .alarm:
            formatter.dateFormat = "h:mm"
        case .timer:
            formatter.dateFormat = "mm:ss"
        case .worldClock:
            formatter.dateFormat = "h:mm a"
        }
        return formatter
    }
    
    private var periodFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter
    }
    
    var body: some View {
        switch style {
        case .alarm:
            HStack(alignment: .firstTextBaseline, spacing: BSpacing.xs) {
                Text(formatter.string(from: time))
                    .font(.alarmTime)
                Text(periodFormatter.string(from: time))
                    .font(.title1)
                    .foregroundColor(.textSecondary)
            }
        case .timer:
            Text(formatter.string(from: time))
                .font(.timerDisplay)
                .monospacedDigit()
        case .worldClock:
            Text(formatter.string(from: time))
                .font(.title2)
        }
    }
}
```

### 5. AlarmRow
```swift
struct AlarmRow: View {
    let alarm: Alarm
    @Binding var isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: BSpacing.xxs) {
                    TimeDisplay(time: alarm.time, style: .alarm)
                    
                    HStack(spacing: BSpacing.xs) {
                        if alarm.isAIEnabled {
                            Label("AI", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundColor(.bananaYellow)
                        }
                        
                        Text(alarm.label)
                            .font(.bodySmall)
                            .foregroundColor(.textSecondary)
                    }
                    
                    if !alarm.repeatDays.isEmpty {
                        Text(alarm.repeatDescription)
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                }
                
                Spacer()
                
                BananaToggle(isOn: $isEnabled, label: nil)
            }
            .padding(.vertical, BSpacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### 6. CircularProgress
```swift
struct CircularProgress: View {
    let progress: Double
    let lineWidth: CGFloat = 8
    let size: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.backgroundSecondary, lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.bananaYellow,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.bananaSmooth, value: progress)
        }
        .frame(width: size, height: size)
    }
}
```

### 7. BananaTabBar
```swift
struct BananaTabBar: View {
    @Binding var selectedTab: Tab
    
    enum Tab: CaseIterable {
        case worldClock, alarms, stopwatch, timers
        
        var title: String {
            switch self {
            case .worldClock: return "World Clock"
            case .alarms: return "Alarms"
            case .stopwatch: return "Stopwatch"
            case .timers: return "Timers"
            }
        }
        
        var navigationTitle: String {
            switch self {
            case .worldClock: return "🌍🕒 World Clock"
            case .alarms: return "⏰ Alarms"
            case .stopwatch: return "⏱️ Stopwatch"
            case .timers: return "⏲️ Timers"
            }
        }
        
        var icon: String {
            switch self {
            case .worldClock: return "globe"
            case .alarms: return "alarm"
            case .stopwatch: return "stopwatch"
            case .timers: return "timer"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.bananaSmooth) {
                        selectedTab = tab
                    }
                    BananaHaptics.selection()
                }
            }
        }
        .frame(height: BLayout.tabBarHeight)
        .background(Color.backgroundPrimary)
        .overlay(
            Divider()
                .background(Color.divider),
            alignment: .top
        )
    }
}

private struct TabBarItem: View {
    let tab: BananaTabBar.Tab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 24))
                Text(tab.title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .bananaYellow : .systemGray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### 8. FloatingActionButton
```swift
struct FloatingActionButton: View {
    let icon: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            BananaHaptics.impact(.medium)
            action()
        }) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundColor(.black)
                .frame(width: 64, height: 64)
                .background(Color.bananaYellow)
                .clipShape(Circle())
                .shadow(
                    color: .bananaYellow.opacity(0.3),
                    radius: 10,
                    y: 5
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.bananaQuick) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}
```

### 9. SegmentedPicker
```swift
struct BananaSegmentedPicker<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [(value: SelectionValue, label: String)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.value) { option in
                Button {
                    withAnimation(.bananaSmooth) {
                        selection = option.value
                        BananaHaptics.selection()
                    }
                } label: {
                    Text(option.label)
                        .font(.button)
                        .foregroundColor(
                            selection == option.value ? .black : .textPrimary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BSpacing.sm)
                        .background(
                            selection == option.value ? Color.bananaYellow : Color.clear
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
    }
}
```

### 10. EmptyStateView
```swift
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: BSpacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.textTertiary)
            
            VStack(spacing: BSpacing.sm) {
                Text(title)
                    .font(.title2)
                    .foregroundColor(.textPrimary)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                BananaButton(actionTitle, style: .primary, action: action)
                    .frame(width: 200)
            }
        }
        .padding(BSpacing.xl)
    }
}
```

---

## 🧭 Navigation Standards

### Navigation Bar Styling
```swift
// Standard Navigation Bar Configuration
.navigationTitle("Screen Title")
.navigationBarTitleDisplayMode(.inline)
.toolbarBackground(.visible, for: .navigationBar)
.toolbarColorScheme(.dark, for: .navigationBar)
.onAppear {
    // Set navigation title color to white and unbolded
    UINavigationBar.appearance().titleTextAttributes = [
        .foregroundColor: UIColor.white,
        .font: UIFont.systemFont(ofSize: 17, weight: .regular)
    ]
}
```

### Navigation Button Patterns

#### Edit/Creation Screens
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        Button("Cancel") {
            dismiss()
        }
        .foregroundColor(.white)
    }
    
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Save") {
            saveAction()
        }
        .foregroundColor(.bananaYellow)
        .disabled(!isValid) // Optional validation
    }
}
```

#### Detail/View Screens
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Done") {
            dismiss()
        }
        .foregroundColor(.bananaYellow)
    }
}
```

#### List Screens with Actions
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) {
        if hasSelectableItems {
            Button(isEditing ? "Done" : "Edit") {
                isEditing.toggle()
            }
            .foregroundColor(.bananaYellow)
        }
    }
    
    ToolbarItem(placement: .navigationBarTrailing) {
        if !isEditing {
            Button {
                addAction()
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.bananaYellow)
            }
        }
    }
}
```

### Navigation Guidelines
- **Titles**: Always white, unbolded, regular weight (17pt)
- **Cancel buttons**: White text, left side
- **Save/Done buttons**: Banana yellow, right side
- **Action buttons**: Banana yellow with appropriate icons
- **Background**: Always visible, dark theme
- **Consistent spacing**: Use standard toolbar item placement

---

## 🎯 Usage Examples

### Alarm List Screen
```swift
struct AlarmsView: View {
    @StateObject private var viewModel = AlarmsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPrimary
                    .ignoresSafeArea()
                
                if viewModel.alarms.isEmpty {
                    EmptyStateView(
                        icon: "alarm",
                        title: "No Alarms",
                        message: "Start your day right with a Banana Clock alarm",
                        actionTitle: "Add Alarm"
                    ) {
                        viewModel.showAddAlarm()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.alarms) { alarm in
                                AlarmRow(
                                    alarm: alarm,
                                    isEnabled: .constant(alarm.isEnabled)
                                ) {
                                    viewModel.editAlarm(alarm)
                                }
                                
                                if alarm != viewModel.alarms.last {
                                    Divider()
                                        .background(Color.divider)
                                        .padding(.horizontal, BSpacing.md)
                                }
                            }
                        }
                        .padding(.vertical, BSpacing.md)
                    }
                }
            }
            .navigationTitle("Alarms")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showAddAlarm()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.bananaYellow)
                    }
                }
            }
        }
    }
}
```

### Timer Creation Sheet
```swift
struct TimerCreationSheet: View {
    @Binding var isPresented: Bool
    @State private var hours = 0
    @State private var minutes = 5
    @State private var seconds = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: BSpacing.xl) {
                BananaCard {
                    HStack {
                        Picker("Hours", selection: $hours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour) hr")
                                    .tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        
                        Picker("Minutes", selection: $minutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute) min")
                                    .tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        
                        Picker("Seconds", selection: $seconds) {
                            ForEach(0..<60) { second in
                                Text("\(second) sec")
                                    .tag(second)
                            }
                        }
                        .pickerStyle(.wheel)
                    }
                    .frame(height: 200)
                }
                
                VStack(spacing: BSpacing.md) {
                    BananaButton("Start Timer", icon: "play.fill") {
                        // Start timer
                        isPresented = false
                    }
                    
                    BananaButton("Cancel", style: .tertiary) {
                        isPresented = false
                    }
                }
                
                Spacer()
            }
            .padding(BSpacing.lg)
            .background(Color.backgroundPrimary)
            .navigationTitle("New Timer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

---

## 🚀 Component Guidelines

### Best Practices
1. **Always use semantic colors** - Never hardcode hex values
2. **Respect the spacing system** - Use BSpacing tokens
3. **Include haptic feedback** - For all interactive elements
4. **Support Dynamic Type** - Test with various text sizes
5. **Maintain 44pt tap targets** - Accessibility requirement
6. **Use consistent animations** - Stick to defined presets
7. **Test in both orientations** - Even though we're iPhone-only

### Performance Tips
- Use `LazyVStack` for long lists
- Implement proper view recycling
- Avoid unnecessary re-renders with `@StateObject`
- Profile with Instruments regularly
- Keep view hierarchies shallow

### Accessibility Checklist
- [ ] All interactive elements have labels
- [ ] Colors meet WCAG contrast requirements
- [ ] VoiceOver navigation flows logically
- [ ] Reduce Motion is respected
- [ ] Dynamic Type scales appropriately

---

## 🎨 Figma Handoff Guide

When receiving designs from Figma:
1. Map Figma colors to our semantic color system
2. Convert pixel values to our spacing tokens
3. Ensure typography matches our scale
4. Verify minimum tap targets (44x44pt)
5. Check corner radius consistency
6. Validate animation timings

---

## 📱 Platform Adaptations

### iPhone Size Classes
```swift
extension View {
    func adaptiveLayout() -> some View {
        self.modifier(AdaptiveLayout())
    }
}

struct AdaptiveLayout: ViewModifier {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
    }
    
    private var horizontalPadding: CGFloat {
        switch sizeClass {
        case .compact:
            return BSpacing.md
        case .regular:
            return BSpacing.xl
        default:
            return BSpacing.md
        }
    }
}
```

---

This component library provides a solid foundation for building Banana Clock with consistent, high-quality UI components that feel native to iOS while maintaining the unique Banana personality.