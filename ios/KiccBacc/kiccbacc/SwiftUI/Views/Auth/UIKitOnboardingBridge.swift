import SwiftUI
import UIKit

struct UIKitOnboardingBridge: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showOnboarding = false
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingCoordinatorView()
            } else {
                // Loading or transition view
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                    
                    Text("Setting up your account...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color.purple.opacity(0.3),
                            Color.pink.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            }
        }
        .onAppear {
            // Small delay to show loading state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showOnboarding = true
                }
            }
        }
    }
}



struct UIKitOnboardingBridge_Previews: PreviewProvider {
    static var previews: some View {
        UIKitOnboardingBridge()
    }
}
