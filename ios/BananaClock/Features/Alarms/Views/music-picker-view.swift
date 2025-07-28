//
//  MusicPickerView.swift
//  BananaClock
//
//  Background music picker view for AI wake-up
//

import SwiftUI

struct MusicPickerView: View {
    @Binding var selectedMusic: MusicOption
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List(MusicOption.allCases, id: \.self) { music in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(music.displayName)
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                        
                        if selectedMusic == music {
                            Image(systemName: "checkmark")
                                .foregroundColor(.bananaYellow)
                        }
                    }
                    
                    Text(music.description)
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedMusic = music
                    HapticManager.shared.impact(.light)
                }
                .listRowBackground(Color.backgroundSecondary)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Background Music")
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

// #Preview {
//     MusicPickerView(selectedMusic: .constant(.chillVibes))
// } 