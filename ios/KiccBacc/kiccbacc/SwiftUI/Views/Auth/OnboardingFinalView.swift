import SwiftUI

struct OnboardingFinalView: View {
    @State private var showContent = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 24) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("You're all set!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -30)
                
                Text("Welcome to the KiccBacc community")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(showContent ? 1 : 0)
                    .offset(x: showContent ? 0 : -20)
            }
            
            Spacer()
            
            // Success content
            VStack(spacing: 30) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color.pink.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)
                
                VStack(spacing: 16) {
                    Text("Account Created Successfully")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Your profile is ready and you can start exploring events!")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Get Started button
            Button(action: {
                NotificationCenter.default.post(name: .onboardingCompleted, object: nil)
            }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.pink)
                    .cornerRadius(28)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
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
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

struct OnboardingFinalView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFinalView()
    }
}
