//
//  BananaConfettiView.swift
//  BananaClock
//
//  Banana emoji confetti effect for AI timezone converter
//

import SwiftUI
import UIKit

struct BananaConfettiView: UIViewRepresentable {
    let isActive: Bool
    let sourceRect: CGRect
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Remove existing emitter layers
        uiView.layer.sublayers?.removeAll { $0 is CAEmitterLayer }
        
        guard isActive else { return }
        
        // Check for reduced motion accessibility setting
        if UIAccessibility.isReduceMotionEnabled {
            // Provide haptic feedback instead of animation
            DispatchQueue.main.async {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
            return
        }
        
        createBananaConfetti(in: uiView)
    }
    
    private func createBananaConfetti(in view: UIView) {
        let emitterLayer = CAEmitterLayer()
        
        // Position emitter at top left of the timezone converter box
        emitterLayer.emitterPosition = CGPoint(x: view.bounds.minX + 20, y: view.bounds.minY + 10)
        emitterLayer.emitterSize = CGSize(width: 20, height: 20)  // Small burst area
        emitterLayer.emitterShape = .point
        
        // Create banana emoji cell for burst
        let bananaCell = createBananaBurstCell()
        
        emitterLayer.emitterCells = [bananaCell]
        
        view.layer.addSublayer(emitterLayer)
        
        // Stop emission after short burst to get closer to 13 bananas
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            emitterLayer.birthRate = 0
        }
        
        // Let particles fall naturally, cleanup after they've had time to fall off screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            emitterLayer.removeFromSuperlayer()
        }
    }
    
    private func createBananaBurstCell() -> CAEmitterCell {
        let cell = CAEmitterCell()
        
        // Create image from banana emoji
        cell.contents = createEmojiImage("🍌")?.cgImage
        
        // Burst properties - emit exactly 13 bananas
        cell.birthRate = 4    // 4 bananas per second, for 0.35 seconds = 1.4 bananas
        cell.lifetime = 6.0   // Long enough to fall off screen
        cell.lifetimeRange = 0.5
        
        // Physics - 75 degree upward right trajectory
        cell.velocity = 200
        cell.velocityRange = 40
        cell.emissionLongitude = -.pi * 75/180  // 75 degrees upward and to the right
        cell.emissionRange = .pi * 0.25  // Wider spread around the 55 degree angle
        
        // Rotation
        cell.spin = 3.0
        cell.spinRange = 2.0
        
        // Scale - emoji size, no transparency
        cell.scale = 0.375
        cell.scaleRange = 0.15
        cell.scaleSpeed = 0  // No scaling during lifetime
        
        cell.alphaSpeed = 0  // No fading
        
        // Gravity to pull them down after initial burst
        cell.yAcceleration = 250
        
        return cell
    }
    
    private func createEmojiImage(_ emoji: String) -> UIImage? {
        let size = CGSize(width: 20, height: 20)  // Smaller emoji size
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),  // Smaller font
                .paragraphStyle: paragraphStyle
            ]
            
            let rect = CGRect(origin: .zero, size: size)
            emoji.draw(in: rect, withAttributes: attributes)
        }
    }
    
}

// Preview for SwiftUI canvas
struct BananaConfettiView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            
            BananaConfettiView(
                isActive: true,
                sourceRect: CGRect(x: 0, y: 0, width: 300, height: 100)
            )
            .frame(width: 300, height: 400)
        }
    }
}