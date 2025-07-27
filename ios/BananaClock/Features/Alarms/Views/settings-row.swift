import SwiftUI

struct SettingsRow: View {
    let title: String
    let value: String?
    let action: (() -> Void)?
    let showChevron: Bool
    let content: AnyView?
    
    // Button-style initializer
    init(title: String, value: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.action = action
        self.showChevron = true
        self.content = nil
    }
    
    // Content-style initializer
    init<Content: View>(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.value = nil
        self.action = nil
        self.showChevron = false
        self.content = AnyView(content())
    }
    
    var body: some View {
        if let content = content {
            // Content-style usage
            HStack {
                Text(title)
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                content
            }
            .padding(.vertical, BSpacing.sm)
        } else {
            // Button-style usage
            Button {
                action?()
                HapticManager.shared.impact(.light)
            } label: {
                HStack {
                    Text(title)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    if let value = value {
                        Text(value)
                            .foregroundColor(.textSecondary)
                    }
                    
                    if showChevron {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                }
                .padding(.vertical, BSpacing.sm)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    VStack {
        SettingsRow(title: "Sound", value: "Radar") {}
        SettingsRow(title: "Snooze", value: "9 minutes") {}
        SettingsRow(title: "Label") {
            TextField("Alarm", text: .constant(""))
                .multilineTextAlignment(.trailing)
                .foregroundColor(.white)
        }
    }
    .padding()
    .background(Color.backgroundPrimary)
}
