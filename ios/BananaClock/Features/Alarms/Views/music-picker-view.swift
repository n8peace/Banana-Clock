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
    @StateObject private var audioService = AudioService.shared
    @State private var originalSelection: MusicOption
    
    init(selectedMusic: Binding<MusicOption>) {
        self._selectedMusic = selectedMusic
        self._originalSelection = State(initialValue: selectedMusic.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            List(MusicOption.allCases, id: \.self) { music in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(music.displayName)
                            .foregroundColor(selectedMusic == music ? .black : .textPrimary)
                        
                        Spacer()
                        
                        if selectedMusic == music {
                            if audioService.isPlayingPreview && audioService.currentPreviewMusic == music {
                                AudioBarsView(isPlaying: true)
                                    .frame(width: 30, height: 20)
                            } else {
                                AudioBarsView(isPlaying: false)
                                    .frame(width: 30, height: 20)
                            }
                        }
                    }
                    
                    Text(music.description)
                        .font(.caption)
                        .foregroundColor(selectedMusic == music ? .black.opacity(0.7) : BananaTheme.Colors.textSecondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedMusic == music {
                        // Toggle preview if tapping same selection
                        if audioService.isPlayingPreview && audioService.currentPreviewMusic == music {
                            audioService.stopMusicPreview()
                        } else {
                            audioService.playMusicPreview(music)
                        }
                    } else {
                        // Select new music and start preview
                        selectedMusic = music
                        audioService.playMusicPreview(music)
                    }
                    HapticManager.shared.impact(.light)
                }
                .listRowBackground(selectedMusic == music ? Color.bananaYellow : Color.backgroundSecondary)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Background Music")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)

            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        selectedMusic = originalSelection
                        audioService.stopMusicPreview()
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        audioService.stopMusicPreview()
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
            .onDisappear {
                audioService.stopMusicPreview()
            }
        }
    }
}

// #Preview {
//     MusicPickerView(selectedMusic: .constant(.chillVibes))
// } 