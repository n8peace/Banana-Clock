//
//  WidgetTheme.swift
//  BananaClockWidgets
//
//  Theme definitions for Widget Extension - duplicated from main app for access
//

import SwiftUI

// MARK: - Color Extensions for Widget Extension

extension Color {
    static let bananaYellow = Color(red: 253/255, green: 224/255, blue: 67/255)
    static let bananaYellowDark = Color(red: 245/255, green: 208/255, blue: 32/255)
    
    // Background colors
    static let backgroundPrimary = Color.black
    static let backgroundSecondary = Color(white: 0.1)
    static let backgroundTertiary = Color(white: 0.15)
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.7)
    static let textTertiary = Color(white: 0.5)
    static let textDisabled = Color(white: 0.3)
    
    // System colors
    static let divider = Color(white: 0.2)
    static let overlay = Color.black.opacity(0.5)
    
    // Semantic colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
}

// MARK: - Spacing Constants for Widget Extension

enum WidgetSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Layout Constants for Widget Extension

enum WidgetLayout {
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let minimumTapTarget: CGFloat = 44
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 8
    static let largeCornerRadius: CGFloat = 20
}

// MARK: - Animation Constants for Widget Extension

enum WidgetAnimation {
    static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
    static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
    static let smooth = SwiftUI.Animation.easeInOut(duration: 0.35)
    static let bounce = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
}