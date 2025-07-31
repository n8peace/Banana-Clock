//
//  AudioBarsView.swift
//  BananaClock
//
//  Animated audio bars for music visualization
//

import SwiftUI

struct AudioBarsView: View {
    let isPlaying: Bool
    let barCount: Int
    @State private var barHeights: [CGFloat]
    @StateObject private var audioAnalyzer = AudioAnalyzer()
    
    init(isPlaying: Bool, barCount: Int = 5) {
        self.isPlaying = isPlaying
        self.barCount = barCount
        self._barHeights = State(initialValue: Array(repeating: 0.1, count: barCount))
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.bananaYellow)
                    .frame(width: 3, height: 20 * barHeights[index])
                    .animation(.easeInOut(duration: 0.1), value: barHeights[index])
            }
        }
        .onAppear {
            updateBarHeights()
        }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                audioAnalyzer.startAnalyzing()
            } else {
                audioAnalyzer.stopAnalyzing()
            }
            updateBarHeights()
        }
        .onReceive(audioAnalyzer.$audioLevels) { levels in
            if isPlaying {
                barHeights = levels.map { CGFloat($0) }
            }
        }
    }
    
    private func updateBarHeights() {
        if isPlaying {
            // Use audio analyzer levels or fallback to random heights
            if audioAnalyzer.isAnalyzing {
                barHeights = audioAnalyzer.audioLevels.map { CGFloat($0) }
            } else {
                barHeights = (0..<barCount).map { _ in
                    CGFloat.random(in: 0.3...1.0)
                }
            }
        } else {
            // Reset to low heights when not playing
            barHeights = Array(repeating: 0.1, count: barCount)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioBarsView(isPlaying: true)
        AudioBarsView(isPlaying: false)
    }
    .padding()
    .background(Color.black)
} 