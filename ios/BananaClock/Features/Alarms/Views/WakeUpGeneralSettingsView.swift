//
//  WakeUpGeneralSettingsView.swift
//  BananaClock
//
//  General alarm settings for wake-up alarms (sound, snooze, volume)
//

import SwiftUI

struct WakeUpGeneralSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSound: AlarmSound
    @Binding var snoozeLength: Int?
    @Binding var volume: Float
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // General Alarm Settings Section
                        VStack(spacing: 0) {
                            // Sound
                            NavigationLink {
                                SoundPickerView(selectedSound: $selectedSound)
                            } label: {
                                HStack {
                                    Text("Sound")
                                        .font(BananaTheme.Typography.body)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text(selectedSound.displayName)
                                        .font(BananaTheme.Typography.body)
                                        .foregroundColor(.textSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(BananaTheme.Colors.textTertiary)
                                }
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                                .padding(.vertical, BananaTheme.Spacing.sm)
                            }
                            
                            Divider().background(BananaTheme.Colors.divider)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
                            // Snooze
                            HStack {
                                Text("Snooze")
                                    .font(BananaTheme.Typography.body)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Picker("", selection: $snoozeLength) {
                                    Text("Off").tag(nil as Int?)
                                    ForEach(1...15, id: \.self) { minutes in
                                        Text("\(minutes) min").tag(minutes as Int?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(BananaTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            .padding(.vertical, BananaTheme.Spacing.sm)
                            
                            Divider().background(BananaTheme.Colors.divider)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
                            // Volume
                            VStack(spacing: BananaTheme.Spacing.sm) {
                                HStack {
                                    Text("Volume")
                                        .font(BananaTheme.Typography.body)
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                    Text("\(Int(volume * 100))%")
                                        .font(BananaTheme.Typography.body)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Slider(value: $volume, in: 0...1, step: 0.05)
                                    .accentColor(BananaTheme.Colors.bananaYellow)
                            }
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            .padding(.vertical, BananaTheme.Spacing.sm)
                        }
                        .bananaCard()
                        .padding()
                    }
                }
            }
            .navigationTitle("General Alarm Settings")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
        }
    }
}

#Preview {
    WakeUpGeneralSettingsView(
        selectedSound: .constant(.dreamExit),
        snoozeLength: .constant(9),
        volume: .constant(0.7)
    )
} 