//
//  AudioAnalyzer.swift
//  BananaClock
//
//  Simulated audio analysis for visualization
//

import Foundation
import Combine

class AudioAnalyzer: ObservableObject {
    @Published var audioLevels: [Float] = Array(repeating: 0.0, count: 5)
    @Published var isAnalyzing = false
    
    private var updateTask: Task<Void, Never>?
    
    func startAnalyzing() {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        
        // Start async task for simulated animation
        updateTask = Task {
            while isAnalyzing {
                await MainActor.run {
                    audioLevels = (0..<5).map { _ in
                        Float.random(in: 0.2...0.8)
                    }
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        }
    }
    
    func stopAnalyzing() {
        isAnalyzing = false
        
        updateTask?.cancel()
        updateTask = nil
        
        // Reset levels
        audioLevels = Array(repeating: 0.0, count: 5)
    }
} 