//
//  EditProfileView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct EditProfileView: View {
    
    @Environment(\.presentationMode) private var presentation
    var user: User
    
    @State private var newName = ""
    @State private var newBio = ""
    @State private var newInstagramUsername = ""
    @State private var newSnapchatUsername = ""
    @State private var newCustomURL = ""
    @State private var pickedImage: UIImage?
    @State private var isUpdating: Bool = false
    @State private var showImagePicker: Bool = false
    
    @State private var alertItem: AlertItem?
    @State private var viewItem: ViewItem?
    @State private var viewControllerItem: UIKitViewControllerItem?
    
    var body: some View {
        
        CustomScrollView(navigationStyle: .dismissBack(title: "Edit profile"), scrollViewData: {
            VStack {
                // Emergency back button - always visible and functional
                HStack {
                    Button("Cancel") {
                        presentation.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    .opacity(isUpdating ? 0.7 : 1.0)
                    
                    Spacer()
                    
                    if isUpdating {
                        Text("Updating...")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
                if let pickedImage = pickedImage {
                    Image(uiImage: pickedImage)
                        .resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Button {
                        showImagePicker.toggle()
                    } label: {
                        PfpView(user: user, size: 120, isRound: true)
                    }
                }

                
                VStack(spacing: 25) {
                    CustomInputField(title: "Name", placeholder: user.fullName, newValue: $newName)
                    
                    CustomInputField(title: "Bio", placeholder: user.bio, newValue: $newBio)
                    
                    CustomInputField(title: "Instagram Username", placeholder: user.instagramUsername ?? "Enter Instagram username", newValue: $newInstagramUsername)
                    
                    CustomInputField(title: "Snapchat Username", placeholder: user.snapchatUsername ?? "Enter Snapchat username", newValue: $newSnapchatUsername)
                    
                    CustomInputField(title: "Custom URL", placeholder: user.customURL ?? "Enter custom URL", newValue: $newCustomURL)
                    
                    Button {
                        guard !isUpdating else { return }
                        
                        withAnimation {
                            isUpdating = true
                        }
                        print("EditProfileView: Update button tapped, isUpdating set to true")
                        // update profile here
                        if let pickedImage = pickedImage, let data = pickedImage.jpeg(.high) {
                            UserManager.shared.uploadPfp(data: data, with: user.userID) { result in
                                switch result {
                                case .success(let status):
                                    switch status {
                                    case .uploaded(withURL: let withURL):
                                        guard let url = withURL else {
                                            withAnimation {
                                                isUpdating = false
                                            }
                                            return
                                        }
                                        
                                        // update
                                        let newValues = [
                                            "profileImageUrlString" : url,
                                            "fullName" : newName,
                                            "bio" : newBio,
                                            "instagramUsername" : newInstagramUsername.isEmpty ? nil : newInstagramUsername,
                                            "snapchatUsername" : newSnapchatUsername.isEmpty ? nil : newSnapchatUsername,
                                            "customURL" : newCustomURL.isEmpty ? nil : newCustomURL
                                        ]
                                        
                                        update(values: newValues as [String : Any])
                                    case .failed(withError: let withError):
                                        print(withError.localizedDescription)
                                        withAnimation {
                                            isUpdating = false
                                        }
                                    }
                                case .failure(let error):
                                    print("Upload failed: \(error.localizedDescription)")
                                    withAnimation {
                                        isUpdating = false
                                    }
                                }
                            }
                        } else {
                            let newValues = [
                                "fullName" : newName,
                                "bio" : newBio,
                                "instagramUsername" : newInstagramUsername.isEmpty ? nil : newInstagramUsername,
                                "snapchatUsername" : newSnapchatUsername.isEmpty ? nil : newSnapchatUsername,
                                "customURL" : newCustomURL.isEmpty ? nil : newCustomURL
                            ]

                            update(values: newValues as [String : Any])
                        }
                    } label: {
                        Text(isUpdating ? "" : "Update")
                            .foregroundColor(.white)
                            .padding()
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: 50)
                            .background(isUpdating ? Color.gray : Color.buttonBgColor)
                            .cornerRadius(15)
                            .padding(.horizontal)
                            .if(isUpdating) { view in
                                view
                                    .overlay (
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    )
                            }
                    }
                    .disabled(isUpdating)
                }
            }
        }, alertItem: $alertItem, viewControllerItem: $viewControllerItem, viewItem: $viewItem)
            .onAppear {
                newName = user.fullName
                newBio = user.bio
                newInstagramUsername = user.instagramUsername ?? ""
                newSnapchatUsername = user.snapchatUsername ?? ""
                newCustomURL = user.customURL ?? ""
            }
            .fullScreenCover(isPresented: $showImagePicker) {
                ImagePicker(isPresented: $showImagePicker, selectedImage: $pickedImage, allowsEditing: true)
            }
    }
    
    private func update(values: [String: Any]) {
        print("EditProfileView: Starting update with values: \(values)")
        
        // TARGETED TIMEOUT: Force close just this view after 0.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("EditProfileView: 💥 TARGETED TIMEOUT - Force closing profile edit only")
            isUpdating = false
            presentation.wrappedValue.dismiss()
        }
        
        // BYPASS ASYNC - Use synchronous approach to avoid hanging
        do {
            print("EditProfileView: 🚀 Using synchronous update to avoid hanging...")
            try UserManager.shared.update(userID: user.userID, values: values)
            print("EditProfileView: ✅ Synchronous update completed!")
            
            // Immediate success handling
            isUpdating = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                print("EditProfileView: 👋 Quick dismissing presentation")
                presentation.wrappedValue.dismiss()
            }
        } catch {
            print("EditProfileView: ❌ Synchronous update failed: \(error)")
            // Still dismiss on error
            isUpdating = false
            presentation.wrappedValue.dismiss()
        }
        
        // BACKUP Safety timeout - reset loading state after 1 second if still loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if isUpdating {
                print("EditProfileView: ⏰ BACKUP TIMEOUT - forcing reset of loading state")
                withAnimation {
                    isUpdating = false
                }
                
                // Auto-dismiss after timeout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    print("EditProfileView: 🚪 Backup force dismissing profile edit")
                    presentation.wrappedValue.dismiss()
                }
            } else {
                print("EditProfileView: ✅ No backup timeout needed - operation completed normally")
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        EditProfileView(user: User())
            .preferredColorScheme(.dark)
    }
}
