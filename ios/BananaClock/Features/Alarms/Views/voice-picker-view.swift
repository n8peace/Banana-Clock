//
//  VoicePickerView.swift
//  BananaClock
//
//  Voice personality picker view for AI wake-up
//

import SwiftUI

struct VoicePickerView: View {
    @Binding var selectedVoice: AIVoiceOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(AIVoiceOption.allCases, id: \.self) { voice in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(voice.displayName)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        if selectedVoice == voice {
                            Image(systemName: "checkmark")
                                .foregroundColor(.bananaYellow)
                        }
                    }
                    
                    Text(voice.description)
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedVoice = voice
                    HapticManager.shared.impact(.light)
                }
                .listRowBackground(Color.backgroundSecondary)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Voice Personality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
        }
    }
}

#Preview {
    VoicePickerView(selectedVoice: .constant(.voice1))
} 