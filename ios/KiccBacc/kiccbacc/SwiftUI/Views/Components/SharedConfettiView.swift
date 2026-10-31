//
//  SharedConfettiView.swift
//  KiccBacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct SharedConfettiAnimationView: View {
    @Binding var isShowing: Bool
    @State private var isAnimating = false
    @State private var particles: [SharedConfettiParticle] = []
    
    let colors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]
    
    var body: some View {
        if isShowing {
            ZStack {
                ForEach(particles) { particle in
                    SharedConfettiParticleView(particle: particle, isAnimating: isAnimating)
                }
            }
            .allowsHitTesting(false)
            .onAppear {
                createParticles()
                startAnimation()
                // Don't auto-hide confetti - let it stay until view dismisses
                // This prevents state changes that might trigger unwanted behaviors
                // DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                //     isShowing = false
                // }
            }
        }
    }
    
    private func createParticles() {
        particles = (0..<50).map { _ in
            SharedConfettiParticle(
                id: UUID(),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 5...15),
                startPosition: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: UIScreen.main.bounds.height + 50
                ),
                endPosition: CGPoint(
                    x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                    y: -50
                ),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5)
            )
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeOut(duration: 3.0)) {
            isAnimating = true
        }
    }
}

struct SharedConfettiParticle: Identifiable {
    let id: UUID
    let color: Color
    let size: CGFloat
    let startPosition: CGPoint
    let endPosition: CGPoint
    let rotation: Double
    let delay: Double
}

struct SharedConfettiParticleView: View {
    let particle: SharedConfettiParticle
    let isAnimating: Bool
    
    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .position(
                x: isAnimating ? particle.endPosition.x : particle.startPosition.x,
                y: isAnimating ? particle.endPosition.y : particle.startPosition.y
            )
            .rotationEffect(.degrees(isAnimating ? particle.rotation + 360 : particle.rotation))
            .opacity(isAnimating ? 0 : 1)
            .animation(
                .easeOut(duration: 3.0)
                .delay(particle.delay),
                value: isAnimating
            )
    }
}

// Preview
struct SharedConfettiAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        SharedConfettiAnimationView(isShowing: .constant(true))
    }
}
