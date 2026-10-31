//
//  SettingsView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    
    // Theme-related state variables removed - app now uses dark theme only
    
    @State var alertItem : AlertItem?
    @State var viewControllerItem: UIKitViewControllerItem?
    
    @Binding var logout: Bool
    
    @State private var showProfileView = false
    @State private var showEditProfileView = false
    

    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 35) {
                //.. user profile preview
                HStack {
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 10) {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(minWidth: 0, maxWidth: .infinity)
                        } else if let user = viewModel.fetchedUser {
                            VStack(alignment: .center, spacing: 15) {
                                // Profile picture - clickable to go to profile
                                Button {
                                    showProfileView = true
                                } label: {
                                    PfpView(user: user, size: 120, isRound: true, strokeWidth: 2)
                                }
                                
                                // Name and username - clickable to go to profile
                                Button {
                                    showProfileView = true
                                } label: {
                                    VStack(alignment: .center, spacing: 5) {
                                        Text("\(user.fullName)")
                                            .font(.system(size: 21, weight: .medium, design: .default))

                                        Text("@ \(user.username)")
                                            .font(.system(size: 14, weight: .regular, design: .default))
                                    }
                                }
                                
                                // Edit profile button
                                Button {
                                    showEditProfileView = true
                                } label: {
                                    HStack {
                                        Text("Edit profile")
                                            .font(.system(size: 13, weight: .regular, design: .default))
                                        
                                        Image(systemName: "chevron.right")
                                            .resizable()
                                            .frame(width: 6, height: 8)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background(Color.buttonBgColor)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .foregroundColor(.labelColor)
                
                //.. General
                VStack(alignment: .leading, spacing: 20) {
                    // Theme picker removed - app now uses dark theme only
                    
                    SettingRow<EmptyView>(title: "Notifications settings", accessoryIndicator: .right, action: {
                        // Track when user accesses notification settings
                        AnalyticsManager.logCustomEvent(name: "access_notification_settings", parameters: nil)
                        
                        if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                            UIApplication.shared.open(appSettings)
                        }
                    })
                }
                .modifier(SectionStyle(title: "General"))
                
                //.. Contact us
                VStack(alignment: .leading, spacing: 20) {
                    SettingRow<EmptyView>(title: "Follow us on Meta", accessoryIndicator: .right, url: URLManager.meta)
                        .onTapGesture {
                            // Track Meta link tap
                            AnalyticsManager.logCustomEvent(name: "social_link_tap", parameters: [
                                "platform": "Meta"
                            ])
                        }
                    
                    SettingRow<EmptyView>(title: "Follow us on Instagram", accessoryIndicator: .right, url: URLManager.instagram)
                        .onTapGesture {
                            // Track Instagram link tap
                            AnalyticsManager.logCustomEvent(name: "social_link_tap", parameters: [
                                "platform": "Instagram"
                            ])
                        }
                }
                .modifier(SectionStyle(title: "Contact us"))
                
                //.. About us
                VStack(alignment: .leading, spacing: 20) {
                    SettingRow<AnyView>(title: "Terms & conditions", accessoryIndicator: .right, navigateToView: {
                        AnyView(TermsAndConditionsView())
                    })
                    
                    SettingRow<AnyView>(title: "Privacy policy", accessoryIndicator: .right, navigateToView: {
                        AnyView(PrivacyPolicyView())
                    })
                }
                .modifier(SectionStyle(title: "About us"))
                
                //.. My Account
                VStack(alignment: .leading, spacing: 20, content: {
                                            Button {
                            // Track logout attempt
                            AnalyticsManager.logCustomEvent(name: "logout_attempt", parameters: nil)
                            
                            alertItem = AlertItem(title: Text("Log out?"), message: Text("Are you sure you want to log out?"), primaryButton: .destructive(Text("Log Out"), action: {
                                
                                do {
                                    // Clear onboarding completion flag before signing out
                                    OnboardingCoordinatorView.clearOnboardingCompletion()
                                    
                                    try Auth.auth().signOut()
                                    
                                    // Track successful logout
                                    AnalyticsManager.logCustomEvent(name: "logout_success", parameters: nil)
                                    
                                    // Reset the root view controller to properly handle logout
                                    resetRootViewController()
                                } catch {
                                    // Track logout error
                                    AnalyticsManager.logCustomEvent(name: "logout_error", parameters: [
                                        "error": error.localizedDescription
                                    ])
                                    
                                    alertItem = AlertItem(title: Text("Error!"), message: Text(error.localizedDescription), dismissButton: .default(Text("Okay")))
                                }
                            }), secondaryButton: .cancel())
                    } label: {
                        Text("Log out")
                            .foregroundColor(.red)
                            .font(.system(size: 18, weight: .medium, design: .default))
                    }
                    
                    Button {
                        // Track account deletion attempt
                        AnalyticsManager.logCustomEvent(name: "account_deletion_attempt", parameters: nil)
                        
                        alertItem = AlertItem(title: Text("Delete account?"), message: Text("Are you sure you want to delete your account and data?"), primaryButton: .destructive(Text("Delete"), action: {
                            
                            if let user = viewModel.fetchedUser {
                                UserManager.shared.delete(user: user) { isDeleted in
                                    if isDeleted {
                                        // Clear onboarding completion flag before account deletion
                                        OnboardingCoordinatorView.clearOnboardingCompletion()
                                        
                                        // Track successful account deletion
                                        AnalyticsManager.logCustomEvent(name: "account_deletion_success", parameters: nil)
                                        
                                        viewControllerItem = UIKitViewControllerItem(_viewController: KiccBacc.ViewController.signIn, _presentationStyle: .fullScreen)
                                    } else {
                                        // Track account deletion error
                                        AnalyticsManager.logCustomEvent(name: "account_deletion_error", parameters: nil)
                                        
                                        alertItem = AlertItem(title: Text("Error!"), message: Text("Can't delete account at the moment!"), dismissButton: .default(Text("Okay")))
                                    }
                                }
                            }
                        }), secondaryButton: .cancel())
                    } label: {
                        Text("Delete account")
                            .foregroundColor(.red)
                            .font(.system(size: 18, weight: .medium, design: .default))
                    }
                })
                .modifier(SectionStyle(title: "My Account"))
                

                
                // Version information
                VStack(alignment: .center, spacing: 10) {
                    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                       let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            }
            .padding(.bottom, 100)
        }
        .navigationBarTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Track screen view when this view appears
            AnalyticsManager.logScreenView(screenName: "Settings", screenClass: "SettingsView")
            
            viewModel.fetchUser()
        }
        .alert(item: $alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
            else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
        .fullScreenCover(item: $viewControllerItem) { vcItem in
            UIKitVisualisationHelper(viewController: vcItem.viewController)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showProfileView) {
            SelfProfileView()
        }
        .sheet(isPresented: $showEditProfileView) {
            if let user = viewModel.fetchedUser {
                EditProfileView(user: user)
            }
        }

    }
    
    // MARK: - Helper Functions
    
    private func resetRootViewController() {
        // iOS 16 compatibility check for window scene management
        if #available(iOS 16.0, *) {
            // iOS 16+ improved window scene handling
            Task { @MainActor in
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let window = windowScene.windows.first else {
                    print("❌ Failed to get window scene for logout")
                    return
                }
                
                let signInViewController = KiccBacc.ViewController.signIn
                
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    window.rootViewController = signInViewController
                }, completion: nil)
            }
        } else {
            // Legacy iOS support
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("❌ Failed to get window scene for logout")
                return
            }
            
            let signInViewController = KiccBacc.ViewController.signIn
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = signInViewController
            }, completion: nil)
        }
    }
}

fileprivate struct SettingRow<Content: View> : View {
    
    var title: String
    var url: URL?
    var navigateToView: (() -> Content)?
    var accessoryView: (() -> Content)?
    var accessoryIndicator: AccessoryIndicator?
    var action: (() -> ())?
    
    //.. link row
    init(title: String, accessoryIndicator: AccessoryIndicator?, url: URL?) {
        self.title = title
        self.url = url
        self.accessoryView = nil
        self.accessoryIndicator = accessoryIndicator
        self.action = nil
    }
    
    //.. tappable row
    init(title: String, accessoryIndicator: AccessoryIndicator?, action: (()->())?) {
        self.title = title
        self.url = nil
        self.accessoryView = nil
        self.accessoryIndicator = accessoryIndicator
        self.action = action
    }
    
    //.. only row
    init(title: String) {
        self.title = title
        self.url = nil
        self.accessoryView = nil
        self.accessoryIndicator = nil
        self.action = nil
    }
    
    //.. row with accessView
    init(title: String, accessoryView: (() -> Content)?) {
        self.title = title
        self.url = nil
        self.accessoryView = accessoryView
        self.accessoryIndicator = nil
        self.action = nil
    }
    
    //.. row with accessView and action
    init(title: String, accessoryView: (() -> Content)?, action: (() -> ())?) {
        self.title = title
        self.url = nil
        self.accessoryView = accessoryView
        self.accessoryIndicator = nil
        self.action = action
    }
    
    //.. navigate to view
    init(title: String, accessoryIndicator: AccessoryIndicator?, navigateToView: (() -> Content)?) {
        self.title = title
        self.url = nil
        self.navigateToView = navigateToView
        self.accessoryView = nil
        self.accessoryIndicator = accessoryIndicator
        self.action = nil
    }
    
    @State private var isTapped: Bool = false
    
    var body: some View {
        if let url = url {
            Link(destination: url) {
                row()
            }
        } else if let action = action {
            row()
                .onTapGesture {
                    action()
                    
                    withAnimation {
                        isTapped.toggle()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            isTapped.toggle()
                        }
                    }
                }
        } else if let navigateToView = navigateToView {
            NavigationLink{
                navigateToView()
            } label: {
                row()
            }
        } else {
            row()
        }
    }
    
    @ViewBuilder
    private func row() -> some View {
        HStack(alignment: .center, spacing: 20) {
            Text(title)
                .font(.system(size: 15, weight: .regular, design: .default))
            
            Spacer()
            
            if let accessoryView = accessoryView {
                accessoryView()
            } else if let accessoryIndicator = accessoryIndicator {
                accessoryIndicator.getImage()
            }
        }
        .background(isTapped ? Color.gray.opacity(0.1) : .clear)
        .cornerRadius(14)
        .contentShape(Rectangle())
    }
}

fileprivate struct SectionStyle: ViewModifier {
    
    var title: String
    
    func body(content: Content) -> some View {
        
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(.gray)
            
            content
        }
        .buttonStyle(FlatLinkStyle())
        .padding(.horizontal)
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView(logout: Binding<Bool>)
//            .preferredColorScheme(.dark)
//    }
//}
