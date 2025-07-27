//
//  BananaTheme.swift
//  BananaClock
//
//  Design system and theme constants
//

import SwiftUI
import Foundation

enum BananaTheme {
    // MARK: - Colors
    enum Colors {
        static let bananaYellow = Color(hex: "#FDE043")
        static let bananaYellowDark = Color(hex: "#F5D020")
        
        // Backgrounds
        static let backgroundPrimary = Color.black
        static let backgroundSecondary = Color(white: 0.1)
        static let backgroundTertiary = Color(white: 0.15)
        
        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(white: 0.7)
        static let textTertiary = Color(white: 0.5)
        static let textDisabled = Color(white: 0.3)
        
        // System
        static let divider = Color(white: 0.2)
        static let overlay = Color.black.opacity(0.5)
        
        // Semantic
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
    }
    
    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Layout
    enum Layout {
        static let screenPadding: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let minimumTapTarget: CGFloat = 44
        static let tabBarHeight: CGFloat = 49
        static let navigationBarHeight: CGFloat = 44
        static let cornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 20
    }
    
    // MARK: - Animation
    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
        static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
    }
    
    // MARK: - Typography
    enum Typography {
        // Display
        static let displayLarge = Font.system(size: 80, weight: .thin, design: .rounded)
        static let displayMedium = Font.system(size: 60, weight: .thin, design: .rounded)
        static let displaySmall = Font.system(size: 48, weight: .light, design: .rounded)
        
        // Titles
        static let title1 = Font.system(size: 34, weight: .bold)
        static let title2 = Font.system(size: 28, weight: .semibold)
        static let title3 = Font.system(size: 22, weight: .semibold)
        
        // Body
        static let bodyLarge = Font.system(size: 19, weight: .regular)
        static let body = Font.system(size: 17, weight: .regular)
        static let bodySmall = Font.system(size: 15, weight: .regular)
        
        // UI Elements
        static let button = Font.system(size: 17, weight: .semibold)
        static let caption = Font.system(size: 13, weight: .regular)
        static let footnote = Font.system(size: 12, weight: .regular)
        
        // Special
        static let alarmTime = Font.system(size: 80, weight: .thin, design: .rounded)
        static let timerDisplay = Font.system(size: 70, weight: .ultraLight, design: .monospaced)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func bananaCard() -> some View {
        self
            .padding(BananaTheme.Layout.cardPadding)
            .background(BananaTheme.Colors.backgroundTertiary)
            .cornerRadius(BananaTheme.Layout.cornerRadius)
    }
    
    func bananaShadow() -> some View {
        self
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

// MARK: - Convenience Extensions
typealias BSpacing = BananaTheme.Spacing

extension Color {
    static let backgroundPrimary = BananaTheme.Colors.backgroundPrimary
    static let backgroundSecondary = BananaTheme.Colors.backgroundSecondary
    static let backgroundTertiary = BananaTheme.Colors.backgroundTertiary
    static let textPrimary = BananaTheme.Colors.textPrimary
    static let textSecondary = BananaTheme.Colors.textSecondary
    static let textTertiary = BananaTheme.Colors.textTertiary
    static let textDisabled = BananaTheme.Colors.textDisabled
    static let divider = BananaTheme.Colors.divider
    static let overlay = BananaTheme.Colors.overlay
    static let success = BananaTheme.Colors.success
    static let warning = BananaTheme.Colors.warning
    static let error = BananaTheme.Colors.error
    static let info = BananaTheme.Colors.info
    static let bananaYellow = BananaTheme.Colors.bananaYellow
    static let bananaYellowDark = BananaTheme.Colors.bananaYellowDark
}