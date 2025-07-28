import SwiftUI
import AVFoundation

struct SoundPickerView: View {
    @Binding var selectedSound: AlarmSound
    @Environment(\.dismiss) private var dismiss
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationStack {
            List(AlarmSound.allCases, id: \.self) { sound in
                HStack {
                    Text(sound.displayName)
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                    
                    if selectedSound == sound {
                        Image(systemName: "checkmark")
                            .foregroundColor(.bananaYellow)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSound = sound
                    playPreview(sound)
                    HapticManager.shared.impact(.light)
                }
                .listRowBackground(Color.backgroundSecondary)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.backgroundPrimary)
            .navigationTitle("Sound")
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
        .onDisappear {
            audioPlayer?.stop()
        }
    }
    
    private func playPreview(_ sound: AlarmSound) {
        audioPlayer?.stop()
        
        guard let url = sound.url else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play sound preview: \(error)")
        }
    }
}

// #Preview {
//     SoundPickerView(selectedSound: .constant(.default))
// }
