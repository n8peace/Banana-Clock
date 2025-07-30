//
//  GoldenGlowModifier.swift
//  BananaClock
//
//  Golden glow effect for timezone converter when AI responds
//

import SwiftUI

struct GoldenGlowModifier: ViewModifier {
    let isActive: Bool
    @State private var glowOpacity: Double = 0.0
    
    func body(content: Content) -> some View {
        content
            .background {
                if isActive {
                    goldenGlowBackground
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    startGlowAnimation()
                } else {
                    stopGlowAnimation()
                }
            }
    }
    
    private var goldenGlowBackground: some View {
        RoundedRectangle(cornerRadius: BananaTheme.Layout.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.yellow.opacity(0.3),
                        Color.orange.opacity(0.2),
                        Color.yellow.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(glowOpacity)
            .blur(radius: 2)
    }
    
    private func startGlowAnimation() {
        // Reset to ensure clean start
        glowOpacity = 0.0
        
        // Animate in with gentle pulse
        withAnimation(.easeInOut(duration: 0.8)) {
            glowOpacity = 1.0
        }
        
        // Start pulsing animation
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatCount(2, autoreverses: true)
        ) {
            glowOpacity = 0.6
        }
        
        // Fade out after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.8)) {
                glowOpacity = 0.0
            }
        }
    }
    
    private func stopGlowAnimation() {
        withAnimation(.easeOut(duration: 0.5)) {
            glowOpacity = 0.0
        }
    }
}

// View extension for easy use
extension View {
    func goldenGlow(isActive: Bool) -> some View {
        modifier(GoldenGlowModifier(isActive: isActive))
    }
}

// Preview for SwiftUI canvas
struct GoldenGlowModifier_Previews: PreviewProvider {
    @State static var isActive = false
    
    static var previews: some View {
        VStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 300, height: 100)
                .cornerRadius(12)
                .goldenGlow(isActive: isActive)
                .padding()
            
            Button("Toggle Glow") {
                isActive.toggle()
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}