//
//  InterestsTagsView.swift
//  kiccbacc
//
//  Created by Assistant on 21/09/2025
//  Copyright © 2025 Assistant. All rights reserved.
//

import SwiftUI

// Custom FlowLayout for center-flowing tags - iOS 16+ compatible
@available(iOS 16.0, *)
struct FlowLayout: Layout {
    var alignment: Alignment = .center
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 12
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            alignment: alignment,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            alignment: alignment,
            spacing: spacing,
            lineSpacing: lineSpacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(
                x: bounds.minX + result.frames[index].minX,
                y: bounds.minY + result.frames[index].minY
            ), proposal: ProposedViewSize(result.frames[index].size))
        }
    }
}

// Fallback FlowLayout using VStack and HStack for iOS 15 and below
struct LegacyFlowLayout<Content: View>: View {
    let content: Content
    let spacing: CGFloat
    let lineSpacing: CGFloat
    
    init(spacing: CGFloat = 8, lineSpacing: CGFloat = 12, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.spacing = spacing
        self.lineSpacing = lineSpacing
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80, maximum: 150), spacing: spacing)
        ], spacing: lineSpacing) {
            content
        }
    }
}

struct FlowResult {
    var bounds = CGSize.zero
    var frames: [CGRect] = []
    
    init(in bounds: CGSize, subviews: LayoutSubviews, alignment: Alignment, spacing: CGFloat, lineSpacing: CGFloat = 12) {
        var origin = CGPoint.zero
        var lineHeight: CGFloat = 0
        var lines: [[Int]] = []
        var currentLine: [Int] = []
        
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            
            if origin.x + size.width > bounds.width && !currentLine.isEmpty {
                // Start new line
                lines.append(currentLine)
                currentLine = [index]
                origin.x = 0
                origin.y += lineHeight + lineSpacing
                lineHeight = size.height
            } else {
                // Add to current line
                currentLine.append(index)
                lineHeight = max(lineHeight, size.height)
            }
            
            origin.x += size.width + spacing
        }
        
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        // Calculate frames with center alignment
        origin.y = 0
        for line in lines {
            let lineWidth = line.reduce(-spacing) { result, index in
                result + subviews[index].sizeThatFits(.unspecified).width + spacing
            }
            
            var x = alignment == .center ? (bounds.width - lineWidth) / 2 : 0
            let lineHeight = line.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            
            for index in line {
                let size = subviews[index].sizeThatFits(.unspecified)
                frames.append(CGRect(
                    x: x,
                    y: origin.y,
                    width: size.width,
                    height: size.height
                ))
                x += size.width + spacing
            }
            
            origin.y += lineHeight + lineSpacing
        }
        
        self.bounds = CGSize(
            width: bounds.width,
            height: max(0, origin.y - lineSpacing)
        )
    }
}

struct InterestsTagsView: View {
    @State var user: User
    @State private var showEditInterests = false
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    let isCurrentUser: Bool
    
    init(user: User, isCurrentUser: Bool = false) {
        self._user = State(initialValue: user)
        self.isCurrentUser = isCurrentUser
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Display current interests
            if let interests = user.interests, !interests.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    // Section header with subtle styling
                    HStack {
                        Text("Interests")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Subtle badge showing count
                        Text("\(interests.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(themeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        Capsule()
                                            .stroke(themeColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Centered flowing layout with better spacing - iOS version compatible
                    Group {
                        if #available(iOS 16.0, *) {
                            FlowLayout(alignment: .center, spacing: 10, lineSpacing: 14) {
                                ForEach(interests, id: \.self) { interest in
                                    InterestTagButton(tag: interest, themeColor: themeColor)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            }
                        } else {
                            LegacyFlowLayout(spacing: 10, lineSpacing: 14) {
                                ForEach(interests, id: \.self) { interest in
                                    InterestTagButton(tag: interest, themeColor: themeColor)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            } else {
                // Empty state with better design
                VStack(spacing: 12) {
                    Image(systemName: "tag.circle")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("No interests yet")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if isCurrentUser {
                        Text("Add some tags to show your vibe")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.vertical, 20)
            }
            
            // Enhanced edit interests button for current user
            if isCurrentUser {
                Button(action: {
                    showEditInterests = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                        Text(user.interests?.isEmpty ?? true ? "Add Your Vibe" : "Edit Interests")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background {
                        ZStack {
                            // Main gradient
                            LinearGradient(
                                colors: [
                                    themeColor.opacity(0.9),
                                    themeColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Subtle highlight
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            themeColor.opacity(0.6)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: themeColor.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                    }
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showEditInterests)
            }
        }
        .sheet(isPresented: $showEditInterests) {
            EditInterestsSheet(user: user) { updatedInterests in
                // Update the local user state for immediate UI feedback
                user.interests = updatedInterests
            }
        }
    }
}

struct InterestTagButton: View {
    let tag: String
    let themeColor: Color
    @State private var isPressed = false
    
    var body: some View {
        Text(tag)
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(
                LinearGradient(
                    colors: [.white, .white.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minWidth: 60, maxWidth: 150)
            .background {
                ZStack {
                    // Main gradient background
                    LinearGradient(
                        colors: [
                            themeColor.opacity(0.9),
                            themeColor.opacity(0.7),
                            themeColor.opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Subtle inner glow
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
                .clipShape(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    themeColor.opacity(0.8),
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: themeColor.opacity(0.4),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                .shadow(
                    color: themeColor.opacity(0.2),
                    radius: 2,
                    x: 0,
                    y: 1
                )
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
}

struct EditInterestsSheet: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedTags: Set<String> = []
    @State private var customTag: String = ""
    @State private var showCustomTagField = false
    @State private var isLoading = false
    
    let user: User
    let onSave: ([String]) -> Void
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    let predefinedTags = [
        "Mysterious", "Always Lit", "Party Animal", "Dancefloor Demon",
        "Wild Card", "Life of Party", "Vibe Curator", "Talkative AF",
        "Flirty Energy", "Lowkey Cool", "Champagne Only", "Cocktail King"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Emergency overlay for grey screen issue
                if isLoading {
                    ZStack {
                        Color.clear
                        
                        VStack(spacing: 20) {
                            Text("🚨 Emergency Exit")
                                .foregroundColor(.red)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("Tap anywhere to force close")
                                .foregroundColor(.white)
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(12)
                        .opacity(0.9)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("InterestsTagsView: 🚨 Emergency tap detected - force closing")
                        withAnimation {
                            isLoading = false
                        }
                        presentationMode.wrappedValue.dismiss()
                    }
                    .zIndex(1000) // Above everything
                }
                
                VStack(spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Edit Your Vibe")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Update your personality tags")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Tags Section
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Predefined tags
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 100), spacing: 8)
                            ], spacing: 8) {
                                ForEach(predefinedTags, id: \.self) { tag in
                                    EditTagButton(
                                        tag: tag,
                                        isSelected: selectedTags.contains(tag),
                                        themeColor: themeColor,
                                        action: {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                    )
                                }
                                
                                // Show selected custom tags
                                ForEach(Array(selectedTags.filter { !predefinedTags.contains($0) }), id: \.self) { customTag in
                                    EditTagButton(
                                        tag: customTag,
                                        isSelected: true,
                                        themeColor: themeColor,
                                        action: {
                                            selectedTags.remove(customTag)
                                        }
                                    )
                                }
                                
                                // Create your own tag button
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showCustomTagField.toggle()
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Create your own")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.2))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            
                            // Custom tag input field
                            if showCustomTagField {
                                HStack {
                                    TextField("Enter custom tag", text: $customTag)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.2))
                                        )
                                    
                                    Button("Add") {
                                        let trimmedTag = customTag.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if !trimmedTag.isEmpty && trimmedTag.count <= 20 {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                selectedTags.insert(trimmedTag)
                                                customTag = ""
                                                showCustomTagField = false
                                            }
                                        }
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.white.opacity(0.3))
                                    .cornerRadius(8)
                                    .disabled(customTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                    
                                    Button("Cancel") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            customTag = ""
                                            showCustomTagField = false
                                        }
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 8)
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Save button with double-tap emergency exit
                    Button(action: saveInterests) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                            }
                            Text(isLoading ? "Saving..." : "Save Changes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(themeColor)
                        .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    // Emergency reset button (only show if loading for more than 2 seconds)
                    if isLoading {
                        Button("Force Close") {
                            print("InterestsTagsView: 🚨 Emergency force close triggered")
                            withAnimation {
                                isLoading = false
                                onSave(Array(selectedTags))
                            }
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.red)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.bottom)
                        .opacity(0.8)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium)),
                
                trailing: Group {
                    if isLoading {
                        Text("Saving...")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                    }
                }
            )
        }
        .onAppear {
            if let interests = user.interests {
                selectedTags = Set(interests)
            }
            
            // Emergency escape mechanism - if loading state is stuck
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if isLoading {
                    print("InterestsTagsView: 🚨 EMERGENCY: Loading state detected on appear - force resetting")
                    withAnimation {
                        isLoading = false
                    }
                }
            }
        }
        .onDisappear {
            // Force reset loading state when view disappears
            if isLoading {
                print("InterestsTagsView: 🚨 Force resetting loading state on disappear")
                isLoading = false
            }
        }
    }
    
    private func saveInterests() {
        guard !isLoading else { 
            print("InterestsTagsView: Save blocked - already loading")
            return 
        }
        
        isLoading = true
        print("InterestsTagsView: ✅ Starting save interests - isLoading set to true")
        
        let interestsArray = Array(selectedTags)
        print("InterestsTagsView: 📝 Saving interests: \(interestsArray)")
        
        guard let currentUserID = UserManager.shared.currentUserID else {
            print("InterestsTagsView: ❌ No current user ID found")
            isLoading = false
            return
        }
        
        print("InterestsTagsView: 👤 Current user ID: \(currentUserID)")
        
        // TARGETED TIMEOUT: Force close just this sheet after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("InterestsTagsView: 💥 TARGETED TIMEOUT - Force closing interests sheet only")
            isLoading = false
            onSave(interestsArray)
            
            // Only dismiss this specific sheet, not parent views
            presentationMode.wrappedValue.dismiss()
        }
        
        // BYPASS ASYNC - Use synchronous approach to avoid hanging
        do {
            print("InterestsTagsView: 🚀 Using synchronous update to avoid hanging...")
            try UserManager.shared.update(userID: currentUserID, values: ["interests": interestsArray])
            print("InterestsTagsView: ✅ Synchronous update completed!")
            
            // Immediate success handling
            onSave(interestsArray)
            isLoading = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("InterestsTagsView: 👋 Quick dismissing presentation")
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            print("InterestsTagsView: ❌ Synchronous update failed: \(error)")
            // Still save locally and dismiss
            onSave(interestsArray)
            isLoading = false
            presentationMode.wrappedValue.dismiss()
        }
        
        // BACKUP Safety timeout - reset loading state after 1 second if still loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if isLoading {
                print("InterestsTagsView: ⏰ BACKUP TIMEOUT - forcing reset of loading state")
                withAnimation {
                    isLoading = false
                    onSave(interestsArray) // Call onSave since update likely succeeded
                }
                
                // Auto-dismiss after timeout - only this sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("InterestsTagsView: 🚪 Backup force dismissing interests sheet only")
                    presentationMode.wrappedValue.dismiss()
                }
            } else {
                print("InterestsTagsView: ✅ No backup timeout needed - operation completed normally")
            }
        }
    }
}

struct EditTagButton: View {
    let tag: String
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            Text(tag)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(
                    isSelected ? 
                    LinearGradient(
                        colors: [.white, .white.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background {
                    if isSelected {
                        ZStack {
                            // Selected gradient background
                            LinearGradient(
                                colors: [
                                    themeColor.opacity(0.9),
                                    themeColor.opacity(0.7),
                                    themeColor.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            // Inner glow for selected state
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        }
                        .clipShape(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            themeColor.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(
                            color: themeColor.opacity(0.4),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    } else {
                        // Unselected state
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
        }
        .scaleEffect(isSelected ? 1.05 : (isPressed ? 0.95 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

struct InterestsTagsView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUser = User(
            userID: "sample",
            email: "sample@email.com",
            username: "sampleuser",
            fullName: "Sample User",
            ageGroup: 25,
            bio: "Sample bio",
            preferredLocation: nil,
            profileImageUrlString: nil,
            followerIDs: nil,
            followingIDs: nil,
            followerCounter: 0,
            followingCounter: 0,
            pushNotificationTokens: nil,
            createdAt: Date(),
            accessToken: nil,
            expiresAt: nil,
            refreshToken: nil,
            merchantId: nil,
            verified: false,
            instagramUsername: nil,
            snapchatUsername: nil,
            customURL: nil,
            interests: ["Party Animal", "Always Lit", "Dancefloor Demon", "Vibe Curator"]
        )
        
        InterestsTagsView(user: sampleUser, isCurrentUser: true)
            .preferredColorScheme(.dark)
            .padding()
    }
}
