import SwiftUI

struct OnboardingPersonalInfoView: View {
    @State private var showContent = false
    @State private var name = ""
    @State private var dateOfBirth = Date()
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
            // Header section with title and progress
            VStack(spacing: 24) {
                // Welcome to KiccBacc title
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Welcome to")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    HStack {
                        Text("KiccBacc")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.pink)
                        Spacer()
                    }
                }
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -30)
                
                // Tell us about yourself text
                HStack {
                    Text("Tell us about yourself")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .opacity(showContent ? 1 : 0)
                .offset(x: showContent ? 0 : -20)
                
                // Progress bar at 40%
                HStack {
                    Rectangle()
                        .fill(Color.pink)
                        .frame(height: 4)
                        .frame(width: showContent ? UIScreen.main.bounds.width * 0.4 * 0.85 : 0)
                        .animation(.easeInOut(duration: 1.0), value: showContent)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            
            Spacer()
            
            // Form content
            VStack(spacing: 24) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    TextField("", text: $name, prompt: Text("Enter your name").foregroundColor(.white.opacity(0.6)))
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
                
                // Date of Birth field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date of Birth")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .colorScheme(.dark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: showContent)
            
            Spacer()
            
            // Continue button
            Button(action: {
                // Validate required fields
                let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedName.isEmpty else {
                    return // Don't continue if name is empty
                }
                
                // Store the name and DOB
                UserDefaults.standard.set(trimmedName, forKey: "onboarding_name")
                UserDefaults.standard.set(dateOfBirth, forKey: "onboarding_dob")
                NotificationCenter.default.post(name: .personalInfoCompleted, object: nil)
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.pink.opacity(0.5) : Color.pink)
                    .cornerRadius(28)
            }
            .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
            .animation(.easeOut(duration: 0.6).delay(0.6), value: showContent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            
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
            // Always start with empty name - user must enter it fresh each time
            name = ""
            
            // Load saved date of birth when returning to this screen
            if let savedDate = UserDefaults.standard.object(forKey: "onboarding_dob") as? Date {
                dateOfBirth = savedDate
            }
            
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }
}

struct OnboardingPersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingPersonalInfoView()
    }
}
