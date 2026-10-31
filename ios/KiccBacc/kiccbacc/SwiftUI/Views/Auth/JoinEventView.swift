import SwiftUI

struct JoinEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showContent = false
    @State private var userName: String = ""
    @State private var userDOB: Date = Date()
    
    let themeColor = Color(red: 242/255, green: 108/255, blue: 146/255)
    
    private var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: Date())
    }
    
    private var currentTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                VStack(spacing: 0) {
                    // Header section matching other onboarding screens exactly
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
                        
                        Text("We need some quick info to continue.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .offset(x: showContent ? 0 : -30)
                        
                        // Progress Bar
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                            Rectangle()
                                .fill(themeColor)
                                .frame(width: geo.size.width * 0.4, height: 4)
                                .cornerRadius(2)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(x: showContent ? 0 : -20)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // EVENT CARD
                        ZStack {
                            Image("party")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width - 48, height: 350)
                                .clipped()
                                .cornerRadius(20)
                            
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.3))
                                .frame(width: geo.size.width - 48, height: 350)
                            
                            VStack(spacing: 0) {
                                Spacer().frame(height: 45)
                                
                                // Pink box with Name & DOB
                                VStack(spacing: 12) {
                                    TextField("", text: $userName, prompt: Text("Name").foregroundColor(.gray))
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .cornerRadius(10)
                                    
                                    HStack {
                                        Text("DOB")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        DatePicker("", selection: $userDOB, displayedComponents: .date)
                                            .labelsHidden()
                                            .datePickerStyle(.compact)
                                            .font(.system(size: 18))
                                            .accentColor(.black)
                                            .colorScheme(.light)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                                    .frame(height: 50)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(themeColor.opacity(0.6))
                                )
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                                .padding(.horizontal, 8)
                                
                                Spacer()
                                
                                // Event details at bottom
                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 6) {
                                            Text("🎉")
                                                .font(.system(size: 12))
                                            Text("Party")
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color.gray.opacity(0.6))
                                        .cornerRadius(12)
                                        
                                        Text("Rock Party")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text("\(currentDate)    \(currentTime)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    Spacer()
                                    
                                    Circle()
                                        .fill(themeColor)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image("def_Logo")
                                                .resizable()
                                                .scaledToFit()
                                                .clipShape(Circle())
                                        )
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 20)
                            }
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                        .padding(.horizontal, 24)
                        
                        Spacer().frame(height: 40)
                        
                        Text("Joining Rock Party as \"\(userName.isEmpty ? "Name" : userName)\"")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .opacity(showContent ? 1 : 0)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        
                        Button(action: {
                            // Validate input before continuing
                            guard !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                return // Could add alert here for empty name
                            }
                            
                            // Save the userName and DOB to UserDefaults
                            UserDefaults.standard.set(userName.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "onboarding_name")
                            UserDefaults.standard.set(userDOB, forKey: "onboarding_dob")
                            NotificationCenter.default.post(name: .joinEventCompleted, object: nil)
                        }) {
                            Text("Continue")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : themeColor)
                                .cornerRadius(14)
                        }
                        .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(showContent ? 1 : 0)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                
                // Back Button Overlay - positioned exactly like other onboarding screens
                Button(action: {
                    NotificationCenter.default.post(name: .onboardingBackTapped, object: nil)
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }
}

#Preview {
    JoinEventView()
}
