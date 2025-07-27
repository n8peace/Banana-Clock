//
//  BananaButton.swift
//  BananaClock
//
//  Primary button component
//

import SwiftUI
import Foundation

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
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: BananaTheme.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.semibold))
                }
                Text(title)
                    .font(BananaTheme.Typography.button)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(backgroundColor)
            .cornerRadius(BananaTheme.Layout.cornerRadius)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(BananaTheme.Animation.quick) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return isPressed ? BananaTheme.Colors.bananaYellowDark : BananaTheme.Colors.bananaYellow
        case .secondary:
            return BananaTheme.Colors.backgroundSecondary
        case .tertiary:
            return .clear
        case .destructive:
            return BananaTheme.Colors.error
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .black
        case .secondary, .tertiary:
            return BananaTheme.Colors.textPrimary
        case .destructive:
            return .white
        }
    }
}

// MARK: - Toggle Component
struct BananaToggle: View {
    @Binding var isOn: Bool
    var label: String? = nil
    
    var body: some View {
        Toggle(isOn: $isOn) {
            if let label = label {
                Text(label)
                    .font(BananaTheme.Typography.body)
                    .foregroundColor(BananaTheme.Colors.textPrimary)
            }
        }
        .toggleStyle(SwitchToggleStyle(tint: BananaTheme.Colors.bananaYellow))
        .onChange(of: isOn) { _, _ in
            HapticManager.shared.selection()
        }
    }
}

// MARK: - Card Component
struct BananaCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = BananaTheme.Layout.cardPadding
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(BananaTheme.Colors.backgroundTertiary)
            .cornerRadius(BananaTheme.Layout.largeCornerRadius)
            .bananaShadow()
    }
}

// MARK: - Time Display
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
            HStack(alignment: .firstTextBaseline, spacing: BananaTheme.Spacing.xs) {
                Text(formatter.string(from: time))
                    .font(BananaTheme.Typography.alarmTime)
                Text(periodFormatter.string(from: time))
                    .font(BananaTheme.Typography.title1)
                    .foregroundColor(BananaTheme.Colors.textSecondary)
            }
        case .timer:
            Text(formatter.string(from: time))
                .font(BananaTheme.Typography.timerDisplay)
                .monospacedDigit()
        case .worldClock:
            Text(formatter.string(from: time))
                .font(BananaTheme.Typography.title2)
        }
    }
}

// Note: HapticManager is defined in Core/Services/haptic-manager.swift