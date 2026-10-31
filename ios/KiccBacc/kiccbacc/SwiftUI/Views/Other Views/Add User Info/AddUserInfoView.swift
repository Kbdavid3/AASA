//
//  AddUserInfoView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import FirebaseAuth

struct AddUserInfoView: View {
        
    @StateObject private var viewModel = AddUserInfoViewViewModel()
    
    @State private var showImagePicker: Bool = false
    @State private var pickedImage: UIImage?
    
    @State private var newFullName: String = ""
    @State private var newBio: String = ""
    @State private var pickedGender: Int = 0
    @State private var pickedAgeGroupInt: Int = 12
    
    @State var alertItem : AlertItem?
    @State var viewControllerItem: UIKitViewControllerItem?
    @State var viewItem: ViewItem?
    @State var isUpdatingData: Bool = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Welcome to")
                        .font(.system(size: 26, weight: .bold, design: .default))
                    
                    Text("KiccBacc.")
                        .font(.system(size: 35, weight: .bold, design: .default))
                        .foregroundColor(.appColor)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 40) {
                        Text("We just need a few quick details to continue")
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundColor(.gray)
                        
                        if let pickedImage = pickedImage {
                            ZStack(alignment: .bottom) {
                                Image(uiImage: pickedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.secondaryBgColor, lineWidth: 5)
                                    )
                                
                                Button {
                                    showImagePicker.toggle()
                                } label: {
                                    Circle()
                                        .fill(Color.secondaryBgColor)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Assets.UI.image
                                                .foregroundColor(.labelColor)
                                        )
                                }
                                .offset(x: 50)
                            }
                        } else {
                            Button {
                                showImagePicker.toggle()
                            } label: {
                                Circle()
                                    .foregroundColor(.secondaryBgColor)
                                    .frame(width: 150, height: 150)
                                    .overlay (
                                        VStack (alignment: .center, spacing: 10) {
                                            Assets.UI.image
                                            
                                            Text("Upload pfp")
                                                .font(.system(size: 13, weight: .light, design: .rounded))
                                        }
                                    )
                            }
                            .foregroundColor(.labelColor)
                        }
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .center, spacing: 30) {
                    CustomInputField(title: "Full Name", placeholder: "e.g. Alex Joseph", newValue: $newFullName)
                        .padding(.horizontal, -20)
                    
                    CustomInputField(title: "Bio", placeholder: "e.g. I'm a rider.", newValue: $newBio)
                        .padding(.horizontal, -20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Gender")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(.gray)
                        
                        Picker("", selection: $pickedGender) {
                            ForEach(Gender.allCases, id: \.id) { ageGroup in
                                Text(ageGroup.title).tag(ageGroup.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Age group")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(.gray)
                        
                        Picker("", selection: $pickedAgeGroupInt) {
                            ForEach(AgeGroup.allCases, id: \.id) { ageGroup in
                                Text(ageGroup.title).tag(ageGroup.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // actions
                    VStack(alignment: .center, spacing: 10) {
                        Button {
                            updateUser()
                        } label: {
                            HStack {
                                if isUpdatingData {
                                    ProgressView()
                                } else {
                                    Text("Save")
                                }
                            }
                            .padding()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                            .background(isUpdatingData ? Color.gray : Color.buttonBgColor)
                            .foregroundColor(.white)
                            .cornerRadius(13)
                        }
                        
                        Button {
                            do {
                                // Clear onboarding completion flag before signing out
                                OnboardingCoordinatorView.clearOnboardingCompletion()
                                
                                try Auth.auth().signOut()
                                
                                // Reset the root view controller to properly handle logout
                                resetRootViewController()
                            } catch {
                                alertItem = AlertItem (
                                    title: Text("Can't sign out user"),
                                    message: Text(error.localizedDescription),
                                    dismissButton: .default(Text("Okay"))
                                )
                            }
                        } label: {
                            Text("Sign out")
                                .foregroundColor(.gray)
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                }
            }
            .padding()
        }
        .alert(item: $alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
            else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(isPresented: $showImagePicker, selectedImage: $pickedImage)
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $viewControllerItem) { viewControllerItem in
            UIKitVisualisationHelper(viewController: viewControllerItem.viewController)
        }
        .fullScreenCover(item: $viewItem) { viewItem in
            viewItem.viewToPresent
        }
    }
    
    private func updateUser() {
        guard !newFullName.isEmpty, !newBio.isEmpty else {
            // show error popup
            alertItem = AlertItem(title: Text("Empty fields ⚠️"), message: Text("Please enter value in all fields."), dismissButton: .default(Text("Okay")))
            return
        }
        
        withAnimation { isUpdatingData = true }
        
        viewModel.getUsersBasicData { result in
            switch result {
            case .success(let initialUser):
                if let pickedImage = pickedImage, let data = pickedImage.jpeg(.high) {
                    // upload profile image
                    UserManager.shared.uploadPfp(data: data, with: initialUser.userID) { result in
                        switch result {
                        case .success(let status):
                            switch status {
                            case .uploaded(withURL: let withURL):
                                // create user here with profile Url
                                let user = User(userID: initialUser.userID, email: initialUser.email, username: initialUser.username, fullName: newFullName, ageGroup: pickedAgeGroupInt, bio: newBio, preferredLocation: nil, profileImageUrlString: withURL, followerIDs: nil, followingIDs: nil, followerCounter: 0, followingCounter: 0, pushNotificationTokens: nil, createdAt: initialUser.createdAt, accessToken: nil, expiresAt: nil, refreshToken: nil, merchantId: nil, verified: false, instagramUsername: nil, snapchatUsername: nil, customURL: nil)
                                
                                viewModel.updateUserInfo(user: user) { status in
                                    withAnimation { isUpdatingData = false }
                                    
                                    switch status {
                                    case .updated:
                                        viewItem = ViewItem(AnyView(NewTabBarView()), _presentationStyle: .fullScreen)
                                    case .failed(let error):
                                        alertItem = AlertItem(title: Text("Error!"), message: Text("Cannot create your account at the moment: \(error.localizedDescription). Please try again later."), dismissButton: .default(Text("Okay")))
                                    }
                                }
                                
                            case .failed(withError: let error):
                                // image upload failed
                                withAnimation { isUpdatingData = false }
                                
                                alertItem = AlertItem(title: Text("Error!"), message: Text("Cannot upload profile picture of user at the moment: \(error.localizedDescription)"), dismissButton: .default(Text("Okay")))
                            }
                        case .failure(let error):
                            withAnimation { isUpdatingData = false }
                            
                            alertItem = AlertItem(title: Text("Error!"), message: Text("Cannot upload profile picture of user at the moment: \(error.localizedDescription)"), dismissButton: .default(Text("Okay")))
                        }
                    }
                } else {
                    withAnimation { isUpdatingData = false }
                    // show alert saying please select a profile image
                    alertItem = AlertItem(title: Text("No profile picture selected!"), message: Text("Please select an profile image to move ahead."), dismissButton: .default(Text("Okay")))
                }
            case .failure(let firebaseError):
                withAnimation { isUpdatingData = false }
                switch firebaseError {
                case .noDocumentsFound, .userNotFound:
                    alertItem = AlertItem(title: Text("Error!"), message: Text("User sign up details not found, please sign up again"), dismissButton: .cancel(), primaryButton: .default(Text("Sign Up"), action: {
                        // Use the new SwiftUI SignUpView instead of the old UIKit one
                        viewItem = ViewItem(AnyView(SignUpView()), _presentationStyle: .fullScreen)
                     }), secondaryButton: .default(Text("Cancel")))
                case .withError(error: let error):
                    alertItem = AlertItem(title: Text("Error!"), message: Text("\(error.localizedDescription). Please try again later, if the problem persists, please contact us."), dismissButton: .default(Text("Okay")))
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func resetRootViewController() {
        // Get the current window scene
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        // Create a new sign-in view controller
        let signInViewController = KiccBacc.ViewController.signIn
        
        // Set it as the root view controller with animation
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = signInViewController
        }, completion: nil)
    }
}

struct AddUserInfoView_Previews: PreviewProvider {
    static var previews: some View {
        AddUserInfoView()
            .preferredColorScheme(.dark)
    }
}
