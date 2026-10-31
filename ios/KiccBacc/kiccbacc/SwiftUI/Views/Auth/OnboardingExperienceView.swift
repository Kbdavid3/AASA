import SwiftUI

struct OnboardingExperienceView: View {
    @State private var showContent = false
    @State private var selectedExperience: ExperienceType?
    @State private var showContinueButton = false

    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255) // #F26C92
    let cardHeight: CGFloat = 120
    let buttonHeight: CGFloat = 60

    enum ExperienceType: String, CaseIterable {
        case host = "Host Events"
        case join = "Join Events"

        var description: String {
            switch self {
            case .host: return "Organize your own events and bring people together."
            case .join: return "Explore trending events and meet new faces."
            }
        }

        var icon: String {
            switch self {
            case .host: return "🪩"
            case .join: return "🎟️"
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background Image
                Image("party")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.6)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // HEADER + PROGRESS
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

                        Text("Choose your experience for Events")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -30)

                        // Progress Bar
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(themeColor)
                                .frame(width: geo.size.width * 0.2, height: 4)
                                .cornerRadius(2)

                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(2)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)

                    Spacer(minLength: 30)

                    // CARDS - dynamically center between header and footer
                    VStack(spacing: 20) {
                        ForEach(ExperienceType.allCases, id: \.self) { experience in
                            ExperienceCard(
                                experience: experience,
                                isSelected: selectedExperience == experience,
                                showCard: showContent,
                                themeColor: themeColor,
                                height: cardHeight
                            ) {
                                selectedExperience = experience
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showContinueButton = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 30)

                    // FOOTER
                    VStack(spacing: 12) {
                        Text("Not Sure? You can change it anytime later")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(showContinueButton ? 1 : 0)
                            .offset(y: showContinueButton ? 0 : 20)

                        Button(action: {
                            if let experience = selectedExperience {
                                // Save the experience selection
                                UserDefaults.standard.set(experience.rawValue, forKey: "onboarding_experience")
                                NotificationCenter.default.post(
                                    name: .experienceSelected,
                                    object: experience
                                )
                            }
                        }) {
                            Text("Continue")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(height: buttonHeight)
                                .frame(maxWidth: .infinity)
                                .background(
                                    selectedExperience != nil ? themeColor : Color.gray.opacity(0.5)
                                )
                                .cornerRadius(14)
                        }
                        .disabled(selectedExperience == nil)
                        .opacity(showContinueButton ? 1 : 0)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear {
            // Load saved experience selection when returning to this screen
            if let savedExperience = UserDefaults.standard.string(forKey: "onboarding_experience") {
                selectedExperience = ExperienceType(rawValue: savedExperience)
                showContinueButton = selectedExperience != nil
            }
            
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }

    struct ExperienceCard: View {
        let experience: ExperienceType
        let isSelected: Bool
        let showCard: Bool
        let themeColor: Color
        let height: CGFloat
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                HStack(spacing: 16) {
                    Text(experience.icon)
                        .font(.system(size: 44))
                        .opacity(showCard ? 1 : 0)
                        .offset(x: showCard ? 0 : -20)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(experience.rawValue)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text(experience.description)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding(24)
                .frame(height: height)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(themeColor.opacity(isSelected ? 0.8 : 0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? themeColor : Color.clear, lineWidth: 3)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(showCard ? 1 : 0)
            .offset(y: showCard ? 0 : 30)
            .animation(.easeOut(duration: 0.6).delay(0.2), value: showCard)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }

    struct OnboardingExperienceView_Previews: PreviewProvider {
        static var previews: some View {
            OnboardingExperienceView()
        }
    }
}
