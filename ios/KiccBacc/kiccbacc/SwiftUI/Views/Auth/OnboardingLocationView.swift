import SwiftUI

struct OnboardingLocationView: View {
    @State private var showContent = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Where are you located?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -30)
                
                Text("Help us find events near you")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -20)
            }
            
            Spacer()
            
            // Placeholder content
            VStack(spacing: 20) {
                Text("Location Step")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("This will be the fourth screen of onboarding")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Continue button
            Button(action: {
                NotificationCenter.default.post(name: .locationCompleted, object: nil)
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.pink)
                    .cornerRadius(28)
            }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            
            // Back Button Overlay
            Button(action: {
                NotificationCenter.default.post(name: .onboardingBackTapped, object: nil)
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

struct OnboardingLocationView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingLocationView()
    }
}
