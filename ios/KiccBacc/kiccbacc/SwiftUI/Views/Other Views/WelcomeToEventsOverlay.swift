//
//  WelcomeToEventsOverlay.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 21/09/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct WelcomeToEventsOverlay: View {
    
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    
    // Animation states
    @State private var confettiScale: CGFloat = 0
    @State private var titleOpacity: Double = 0
    @State private var congratsOpacity: Double = 0
    @State private var notDoneOpacity: Double = 0
    @State private var addStoryOpacity: Double = 0
    @State private var hintOpacity: Double = 0
    @State private var storyCircleScale: CGFloat = 0
    @State private var storyTextOpacity: Double = 0
    @State private var storySubtextOpacity: Double = 0
    @State private var scenesCircleScale: CGFloat = 0
    @State private var scenesTextOpacity: Double = 0
    @State private var scenesSubtextOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    
    // Theme color
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay that allows background to show through
            Color.black
                .opacity(0.5)
                .ignoresSafeArea(.all)
            
            // Centered modal overlay
            VStack(spacing: 0) {
                Spacer()
                
                // Main modal container
                VStack(spacing: 24) {
                    // Confetti icon with stunning effects
                    ZStack {
                        // Outer glow ring
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        themeColor.opacity(0.4),
                                        themeColor.opacity(0.1),
                                        Color.clear
                                    ]),
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 50
                                )
                            )
                            .frame(width: 100, height: 100)
                            .scaleEffect(confettiScale * 1.2)
                        
                        // Main circle with gradient
                        Circle()
                            .fill(
                                RadialGradient(
                                    gradient: Gradient(colors: [
                                        themeColor,
                                        themeColor.opacity(0.8)
                                    ]),
                                    center: .topLeading,
                                    startRadius: 10,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.3),
                                                Color.clear
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                        
                        Image(systemName: "party.popper.fill")
                            .font(.system(size: 35, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                    .scaleEffect(confettiScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: confettiScale)
                    
                    // Title with stunning styling
                    Text("Welcome to Events!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .opacity(titleOpacity)
                        .animation(.easeInOut(duration: 0.8), value: titleOpacity)
                    
                    // Main messages
                    VStack(spacing: 12) {
                        Text("🎉 Congrats on joining your first event!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(congratsOpacity)
                            .animation(.easeInOut(duration: 0.8), value: congratsOpacity)
                        
                        Text("It's not done yet though...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(notDoneOpacity)
                            .animation(.easeInOut(duration: 0.8), value: notDoneOpacity)
                        
                        Text("Add a story to share the moment!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(addStoryOpacity)
                            .animation(.easeInOut(duration: 0.8), value: addStoryOpacity)
                        
                        Text("Add a story using the + button")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                            .opacity(hintOpacity)
                            .animation(.easeInOut(duration: 0.8), value: hintOpacity)
                    }
                    
                    // Story section with enhanced styling
                    HStack(spacing: 16) {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            themeColor.opacity(0.3),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 15,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .scaleEffect(storyCircleScale * 1.3)
                            
                            // Main circle with gradient
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            themeColor,
                                            themeColor.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                        .scaleEffect(storyCircleScale)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: storyCircleScale)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Story")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(storyTextOpacity)
                                .animation(.easeInOut(duration: 0.8), value: storyTextOpacity)
                            
                            Text("Create stunning visual stories")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(storySubtextOpacity)
                                .animation(.easeInOut(duration: 0.8), value: storySubtextOpacity)
                        }
                        
                        Spacer()
                    }
                    
                    // Scenes section with enhanced styling
                    HStack(spacing: 16) {
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            themeColor.opacity(0.3),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 15,
                                        endRadius: 30
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .scaleEffect(scenesCircleScale * 1.3)
                            
                            // Main circle with gradient
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            themeColor,
                                            themeColor.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                        }
                        .scaleEffect(scenesCircleScale)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: scenesCircleScale)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scenes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(scenesTextOpacity)
                                .animation(.easeInOut(duration: 0.8), value: scenesTextOpacity)
                            
                            Text("Scenes are blueprints")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                                .opacity(scenesSubtextOpacity)
                                .animation(.easeInOut(duration: 0.8), value: scenesSubtextOpacity)
                        }
                        
                        Spacer()
                    }
                    
                    // Action button with stunning styling
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isPresented = false
                        }
                        
                        // Small delay before calling onDismiss to allow animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    }) {
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 24, height: 24)
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Getting Ready?")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 18)
                        .padding(.horizontal, 28)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    themeColor,
                                    themeColor.opacity(0.9)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: themeColor.opacity(0.4), radius: 15, x: 0, y: 8)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                    }
                    .opacity(buttonOpacity)
                    .scaleEffect(buttonScale)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: buttonScale)
                    .animation(.easeInOut(duration: 0.8), value: buttonOpacity)
                }
                .padding(28)
                .background(
                    ZStack {
                        // Solid background to block content behind
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.black)
                        
                        // Gradient overlay for visual appeal
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.black.opacity(0.8),
                                        Color.gray.opacity(0.2)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            themeColor.opacity(0.3),
                                            themeColor.opacity(0.1),
                                            Color.clear
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .shadow(color: themeColor.opacity(0.2), radius: 20, x: 0, y: 10)
                        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                )
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimationSequence()
        }
    }
    
    private func startAnimationSequence() {
        // Confetti appears first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            confettiScale = 1.0
        }
        
        // Title appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            titleOpacity = 1.0
        }
        
        // Congratulations text
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            congratsOpacity = 1.0
        }
        
        // Not done yet text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            notDoneOpacity = 1.0
        }
        
        // Add story text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            addStoryOpacity = 1.0
        }
        
        // Hint text
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            hintOpacity = 1.0
        }
        
        // Story section
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            storyCircleScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
            storyTextOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            storySubtextOpacity = 1.0
        }
        
        // Scenes section
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            scenesCircleScale = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            scenesTextOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            scenesSubtextOpacity = 1.0
        }
        
        // Button appears last
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            buttonOpacity = 1.0
            buttonScale = 1.0
        }
    }
}

#Preview {
    WelcomeToEventsOverlay(isPresented: .constant(true)) {
        print("Overlay dismissed")
    }
}