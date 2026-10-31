import SwiftUI

struct OnboardingInterestsView: View {
    @State private var showContent = false
    @State private var bio: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var customTag: String = ""
    @State private var showCustomTagField = false
    
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    let predefinedTags = [
        "Mysterious", "Always Lit", "Party Animal", "Dancefloor Demon",
        "Wild Card", "Life of Party", "Vibe Curator", "Talkative AF",
        "Flirty Energy", "Lowkey Cool", "Champagne Only", "Cocktail King"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Black background
                Color.black
                    .ignoresSafeArea()
                
                // Back Button Overlay - Positioned to match other screens
                Button(action: {
                    NotificationCenter.default.post(name: .onboardingBackTapped, object: nil)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                }
                
                VStack(spacing: 0) {
                    // Header section matching other onboarding screens
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome to")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(showContent ? 1 : 0)
                                .offset(x: showContent ? 0 : -50)
                            
                            Text("KiccBacc")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(themeColor)
                                .opacity(showContent ? 1 : 0)
                                .offset(x: showContent ? 0 : -50)
                        }
                        
                        Text("Final Step!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -30)
                        
                        // Progress Bar (100%)
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                            Rectangle()
                                .fill(themeColor)
                                .frame(width: geometry.size.width - 48, height: 4)
                                .cornerRadius(2)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    // Description text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Let People know your party energy.")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -30)
                        
                        Text("Pick some tags or write your own.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // Bio and Tags in the same pink rectangle
                    VStack(alignment: .leading, spacing: 20) {
                        // Bio text field
                        TextField("Bio", text: $bio, prompt: Text("Bio").foregroundColor(.white.opacity(0.7)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .autocapitalization(.sentences)
                        
                        // Divider line
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        
                        // Tags section - SCROLLABLE
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                // Predefined tags
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 100), spacing: 8)
                                ], spacing: 8) {
                                    ForEach(predefinedTags, id: \.self) { tag in
                                        TagButton(
                                            tag: tag,
                                            isSelected: selectedTags.contains(tag),
                                            action: {
                                                if selectedTags.contains(tag) {
                                                    selectedTags.remove(tag)
                                                } else {
                                                    selectedTags.insert(tag)
                                                }
                                            }
                                        )
                                    }
                                    
                                    // Show selected custom tags as black buttons
                                    ForEach(Array(selectedTags.filter { !predefinedTags.contains($0) }), id: \.self) { customTag in
                                        TagButton(
                                            tag: customTag,
                                            isSelected: true,
                                            action: {
                                                selectedTags.remove(customTag)
                                            }
                                        )
                                    }
                                    
                                    // Create your own tag button
                                    Button(action: {
                                        showCustomTagField.toggle()
                                    }) {
                                        HStack {
                                            Image(systemName: "plus")
                                                .font(.system(size: 12, weight: .bold))
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
                                        TextField("Enter custom tag", text: $customTag, prompt: Text("Enter custom tag").foregroundColor(.white.opacity(0.6)))
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
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        .frame(maxHeight: 300) // Fixed height for scrollable area
                        .clipped()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeColor.opacity(0.8))
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 30)
                    .animation(.easeOut(duration: 0.8).delay(0.5), value: showContent)
                    
                    Spacer(minLength: 100)
                }
                
                // Continue button fixed at bottom
                VStack {
                    Spacer()
                    Button(action: {
                        // Save bio and selected tags
                        UserDefaults.standard.set(bio, forKey: "onboarding_bio")
                        UserDefaults.standard.set(Array(selectedTags), forKey: "onboarding_tags")
                        NotificationCenter.default.post(name: .interestsCompleted, object: nil)
                    }) {
                        Text("Continue")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(height: 60)
                            .frame(maxWidth: .infinity)
                            .background(themeColor)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.8), value: showContent)
                }
            }
        }
        .ignoresSafeArea(.keyboard) // Prevent keyboard from moving the screen
        .onAppear {
            // Load saved data when returning to this screen
            if let savedBio = UserDefaults.standard.string(forKey: "onboarding_bio") {
                bio = savedBio
            }
            if let savedTags = UserDefaults.standard.array(forKey: "onboarding_tags") as? [String] {
                selectedTags = Set(savedTags)
            }
            
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

// Tag Button Component
struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? themeColor : Color.black.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(isSelected ? themeColor : Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct OnboardingInterestsView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingInterestsView()
    }
}
