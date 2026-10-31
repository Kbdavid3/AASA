import SwiftUI

// MARK: - Onboarding Step Enum
enum OnboardingStep: Int, CaseIterable {
    case experience = 1
    case hostEvent
    case joinEvent
    case personalInfo
    case profilePicture
    case storyUsername
    case interests
    case syncContacts
    case location
    case final

    var title: String {
        switch self {
        case .experience: return "Choose Experience"
        case .hostEvent: return "Create Event"
        case .joinEvent: return "Join Event"
        case .personalInfo: return "Personal Info"
        case .profilePicture: return "Profile Picture"
        case .storyUsername: return "Story Username"
        case .interests: return "Interests"
        case .syncContacts: return "Sync Contacts"
        case .location: return "Location"
        case .final: return "Complete"
        }
    }
}

struct OnboardingCoordinatorView: View {
    @State private var currentStep: OnboardingStep = .experience
    @State private var userExperience: OnboardingExperienceView.ExperienceType?
    @State private var viewItem: ViewItem?
    
    private func goBack() {
        print("🔙 OnboardingCoordinatorView: goBack() called - current step: \(currentStep)")
        withAnimation(.easeInOut(duration: 0.3)) {
            switch currentStep {
            case .experience:
                // Can't go back from first screen
                break
            case .hostEvent:
                currentStep = .experience
            case .joinEvent:
                print("🔙 OnboardingCoordinatorView: Navigating from .joinEvent")
                if userExperience == .host {
                    currentStep = .hostEvent
                } else {
                    currentStep = .experience
                }
            case .personalInfo:
                // This step is now removed
                currentStep = .joinEvent
            case .profilePicture:
                currentStep = .joinEvent
            case .storyUsername:
                currentStep = .profilePicture
            case .interests:
                currentStep = .storyUsername
            case .syncContacts:
                currentStep = .interests
            case .location:
                currentStep = .interests
            case .final:
                currentStep = .syncContacts
            }
        }
        // Save progress after going back
        saveOnboardingProgress()
    }
    
    private func saveOnboardingProgress() {
        UserDefaults.standard.set(currentStep.rawValue, forKey: "onboarding_current_step")
        if let experience = userExperience {
            UserDefaults.standard.set(experience.rawValue, forKey: "onboarding_experience")
        }
        print("💾 OnboardingCoordinatorView: Saved progress - step: \(currentStep), experience: \(userExperience?.rawValue ?? "nil")")
    }
    
    private func restoreOnboardingProgress() {
        // Restore user experience
        if let savedExperience = UserDefaults.standard.string(forKey: "onboarding_experience") {
            userExperience = OnboardingExperienceView.ExperienceType(rawValue: savedExperience)
        }
        
        // Restore current step
        if let savedStepRawValue = UserDefaults.standard.object(forKey: "onboarding_current_step") as? Int,
           let savedStep = OnboardingStep(rawValue: savedStepRawValue) {
            print("🔄 OnboardingCoordinatorView: Found saved step: \(savedStep.rawValue), setting currentStep to: \(savedStep)")
            currentStep = savedStep
            print("🔄 OnboardingCoordinatorView: Restored progress - step: \(currentStep), experience: \(userExperience?.rawValue ?? "nil")")
        } else {
            print("🔄 OnboardingCoordinatorView: No saved step found, using default: \(currentStep)")
        }
    }
    
    // MARK: - Public Methods for Progress Management
    
    static func clearOnboardingProgress() {
        UserDefaults.standard.removeObject(forKey: "onboarding_current_step")
        UserDefaults.standard.removeObject(forKey: "onboarding_experience")
        print("🧹 OnboardingCoordinatorView: Cleared onboarding progress")
    }
    
    static func markOnboardingAsCompleted() {
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
        print("✅ OnboardingCoordinatorView: Marked onboarding as completed")
    }
    
    static func clearOnboardingCompletion() {
        UserDefaults.standard.removeObject(forKey: "onboarding_completed")
        print("🧹 OnboardingCoordinatorView: Cleared onboarding completion flag")
    }
    
    static func isOnboardingComplete() -> Bool {
        // First check if onboarding was marked as completed
        if UserDefaults.standard.bool(forKey: "onboarding_completed") {
            print("✅ OnboardingCoordinatorView: Onboarding marked as completed")
            return true
        }
        
        // Fallback: Check if there's saved onboarding progress
        if let currentStepRawValue = UserDefaults.standard.object(forKey: "onboarding_current_step") as? Int,
           let currentStep = OnboardingStep(rawValue: currentStepRawValue) {
            // If we're at the final step, onboarding is complete
            let isComplete = currentStep == .syncContacts
            print("🔍 OnboardingCoordinatorView: Current step \(currentStep) - isComplete: \(isComplete)")
            return isComplete
        }
        
        print("❌ OnboardingCoordinatorView: No onboarding progress found")
        return false
    }

    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // MAIN CONTENT - No extra padding or background

                    // MAIN CONTENT
                    Group {
                        switch currentStep {
                        case .experience:
                            OnboardingExperienceView()
                                .onReceive(NotificationCenter.default.publisher(for: .experienceSelected)) { notification in
                                    if let experience = notification.object as? OnboardingExperienceView.ExperienceType {
                                        userExperience = experience
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            switch experience {
                                            case .host:
                                                currentStep = .hostEvent
                                            case .join:
                                                currentStep = .joinEvent
                                            }
                                        }
                                        saveOnboardingProgress()
                                    }
                                }

                        case .hostEvent:
                            OnboardingCreateEventView()
                                .onReceive(NotificationCenter.default.publisher(for: .hostEventCompleted)) { _ in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep = .joinEvent
                                    }
                                    saveOnboardingProgress()
                                }

                        case .joinEvent:
                            JoinEventView()
                                .onReceive(NotificationCenter.default.publisher(for: .joinEventCompleted)) { _ in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep = .profilePicture
                                    }
                                    saveOnboardingProgress()
                                }

                        case .personalInfo:
                            // Removed - JoinEventView now handles name/DOB collection
                            EmptyView()

                        case .profilePicture:
                            OnboardingProfilePictureView()
                                .onReceive(NotificationCenter.default.publisher(for: .profilePictureCompleted)) { _ in
                                    print("🎯 OnboardingCoordinatorView: Received profilePictureCompleted notification")
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        print("🎯 OnboardingCoordinatorView: Moving from profilePicture to storyUsername")
                                        currentStep = .storyUsername
                                    }
                                    saveOnboardingProgress()
                                }

                        case .storyUsername:
                            OnboardingStoryUsernameView()
                                .onReceive(NotificationCenter.default.publisher(for: .storyUsernameCompleted)) { _ in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep = .interests
                                    }
                                    saveOnboardingProgress()
                                }

                        case .interests:
                            OnboardingInterestsView()
                                .onReceive(NotificationCenter.default.publisher(for: .interestsCompleted)) { _ in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep = .syncContacts
                                    }
                                    saveOnboardingProgress()
                                }

                        case .syncContacts:
                            OnboardingSyncContactsView()
                                // Remove the notification listener since sync contacts handles navigation directly

                        case .location:
                            OnboardingLocationView()
                                .onReceive(NotificationCenter.default.publisher(for: .locationCompleted)) { _ in
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentStep = .final
                                    }
                                    saveOnboardingProgress()
                                }

                        case .final:
                            OnboardingFinalView()
                                .onReceive(NotificationCenter.default.publisher(for: .onboardingCompleted)) { _ in
                                    // This case shouldn't be reached now as sync contacts is the final step
                                    viewItem = ViewItem(AnyView(NewTabBarView()), _presentationStyle: .fullScreen)
                                }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $viewItem) { viewItem in
            viewItem.viewToPresent
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingBackTapped)) { _ in
            print("🔙 OnboardingCoordinatorView: Received onboardingBackTapped notification - current step: \(currentStep)")
            goBack()
        }
        .onAppear {
            // Restore onboarding progress from UserDefaults
            restoreOnboardingProgress()
        }
    }
}

// Notifications
extension Notification.Name {
    static let experienceSelected = Notification.Name("experienceSelected")
    static let hostEventCompleted = Notification.Name("hostEventCompleted")
    static let joinEventCompleted = Notification.Name("joinEventCompleted")
    static let personalInfoCompleted = Notification.Name("personalInfoCompleted")
    static let profilePictureCompleted = Notification.Name("profilePictureCompleted")
    static let storyUsernameCompleted = Notification.Name("storyUsernameCompleted")
    static let interestsCompleted = Notification.Name("interestsCompleted")
    static let locationCompleted = Notification.Name("locationCompleted")
    static let onboardingCompleted = Notification.Name("onboardingCompleted")
    static let onboardingBackTapped = Notification.Name("onboardingBackTapped")
}

struct OnboardingCoordinatorView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingCoordinatorView()
    }
}
