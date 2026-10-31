//
//  SceneDelegate.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftUI
import GoogleSignIn

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var pendingDeepLinkEvent: Event?
    // Add a flag to track if we received a deep link
    var receivedDeepLink = false
    // Note: Authentication state listener handle removed to prevent automatic logout

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        self.window = UIWindow(windowScene: windowScene)
        
        // FIXED: Safe unwrapping of window with guard statement
        guard let window = self.window else {
            print("❌ SceneDelegate: Failed to create window")
            return
        }
        
        // Set window background to prevent black screen flash
        window.backgroundColor = UIColor.systemBackground
        
        // Note: Authentication state listener removed to prevent automatic logout on app close
        // The app will rely on the initial auth check above for determining the initial view
        
        // Check if user is logged in
        if let _ = Auth.auth().currentUser?.uid {
            // User is logged in - show main app directly to eliminate loading screen
            print("🚀 SceneDelegate: User authenticated, showing main app directly")
            let mainAppVC = UIHostingController(rootView: NewTabBarView())
            window.rootViewController = mainAppVC
        } else {
            // No user logged in - show onboarding/sign in screen
            let initialViewController = KiccBacc.ViewController.onboarding
            window.rootViewController = initialViewController
        }
        
        window.makeKeyAndVisible()
        
        // FIXED: Use modern UIWindowScene API instead of deprecated UIApplication.shared.windows
        // Force dark theme for all windows in the scene
        windowScene.windows.forEach { sceneWindow in
            sceneWindow.overrideUserInterfaceStyle = .dark
        }
        
        // Handle deep links when app is launched from a URL
        if let urlContext = connectionOptions.urlContexts.first {
            receivedDeepLink = true
            handleDeepLink(url: urlContext.url)
        }
        
        // Handle universal links when app is launched from a universal link
        if let userActivity = connectionOptions.userActivities.first,
           userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            print("App launched from universal link: \(url.absoluteString)")
            receivedDeepLink = true
            handleDeepLink(url: url)
        }
        
        // tap anywhere out of the textFields to dismiss them
        let tapGesture = AnyGestureRecognizer(target: self.window, action:#selector(UIView.endEditing))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        self.window?.addGestureRecognizer(tapGesture)
    }
    
    // Handle deep links when app is already running
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        print("SceneDelegate received URL: \(url.absoluteString)")
        print("URL Scheme: \(url.scheme ?? "nil")")
        print("URL Host: \(url.host ?? "nil")")
        
        // Handle Google Sign-In URL first
        if GIDSignIn.sharedInstance.handle(url) {
            print("Google Sign-In handled the URL")
            return
        }
        
        // Handle other deep links
        receivedDeepLink = true
        handleDeepLink(url: url)
    }
    
    // Add this method to handle universal links when app is already running
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL {
            print("Universal link received: \(url.absoluteString)")
            receivedDeepLink = true
            handleDeepLink(url: url)
        }
    }
    
    // Update handleDeepLink to handle both custom scheme and universal links
    public func handleDeepLink(url: URL) {
        print("Received Deep Link: \(url.absoluteString)")
        print("URL Scheme: \(url.scheme ?? "nil")")
        print("URL Host: \(url.host ?? "nil")")
        print("URL Path: \(url.path)")
        
        // Handle authentication deep links
        if url.scheme == "kiccbacc", url.host == "auth-success" {
            handleAuthDeepLink(url: url)
            return
        }
        
        // Handle event deep links - both custom scheme and universal links
        let pathComponents = url.pathComponents
        
        // For universal links like https://kiccbacc.com/event/478557B2-57F3-485D-B3BE-E2CBDEA7C2CE
        if url.host == "kiccbacc.com" && pathComponents.count >= 3 && pathComponents[1] == "event" {
            let eventId = pathComponents[2]
            print("Found Event ID from universal link: \(eventId)")
            openEvent(withId: eventId)
            return
        }
        
        // For custom scheme links like kiccbacc://event/478557B2-57F3-485D-B3BE-E2CBDEA7C2CE
        if url.scheme == "kiccbacc" && url.host == "event" && pathComponents.count >= 2 {
            let eventId = pathComponents[1]
            print("Found Event ID from custom scheme: \(eventId)")
            openEvent(withId: eventId)
            return
        }
        
        print("Unhandled URL format: \(url.absoluteString)")
    }
    
    private func handleAuthDeepLink(url: URL) {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            
            let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value
            let expiresAt = queryItems.first(where: { $0.name == "expires_at" })?.value
            let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value
            let merchantId = queryItems.first(where: { $0.name == "merchant_id" })?.value
            
            if let accessToken = accessToken,
               let expiresAt = expiresAt,
               let refreshToken = refreshToken,
               let merchantId = merchantId {
                print("Access Token: \(accessToken)")
                print("Expires At: \(expiresAt)")
                print("Refresh Token: \(refreshToken)")
                print("Merchant ID: \(merchantId)")
                
                guard let userID = UserManager.shared.currentUserID else {
                    return
                }
                
                UserManager.shared.getUserListener(withUserID: userID) { result in
                    switch result {
                    case .success(let user):
                        do {
                            try UserManager.shared.updateCurrentUserTokens(
                                accessToken: accessToken,
                                expiresAt: expiresAt,
                                refreshToken: refreshToken,
                                merchantId: merchantId
                            )
                            // Handle successful update
                        } catch {
                            print("Error updating user tokens: \(error)")
                            // Handle the error
                        }
                    case .failure(_):
                        // login again, user fetch failed
                        break
                    }
                }
            } else {
                print("Error: Missing required parameters in the URL")
            }
        }
    }

    private func openEvent(withId eventId: String) {
        // Store the eventId in case we need to handle it after initialization
        UserDefaults.standard.set(eventId, forKey: "pendingEventId")
        
        EventManager.shared.getEvent(with: eventId) { [weak self] event in
            guard let self = self else { return }
            
            if let event = event {
                DispatchQueue.main.async {
                    if self.window?.rootViewController?.view.window != nil {
                        // App is already initialized - present the event immediately
                        self.presentEventDetail(event: event)
                    } else {
                        // App is still initializing - store the event for later presentation
                        self.pendingDeepLinkEvent = event
                    }
                }
            } else {
                print("Error: Event not found for ID: \(eventId)")
                // Optionally show an alert to the user
            }
        }
    }
    
    private func presentEventDetail(event: Event) {
        // For now, present event detail directly
        // TODO: Add password protection once EventPasswordView is properly accessible
        if let password = event.password, !password.isEmpty {
            print("Note: Event requires password: \(event.name) - but password protection temporarily disabled for deeplinks")
        }
        presentEventDetailView(event: event)
    }
    
    private func presentEventDetailView(event: Event) {
        let eventDetailView = EventDetailView(event: event)
        let hostingController = UIHostingController(rootView: 
            NavigationView {
                eventDetailView
            }
        )
        
        // Find the appropriate navigation controller to push onto
        if let rootViewController = self.window?.rootViewController {
            // If we're in a tab bar controller, present modally with full navigation capabilities
            if let tabBarController = findTabBarController(from: rootViewController) {
                let navigationController = UINavigationController(rootViewController: hostingController)
                navigationController.modalPresentationStyle = .fullScreen
                navigationController.isNavigationBarHidden = true
                tabBarController.present(navigationController, animated: true)
            } else {
                // Otherwise present modally from whatever view controller we have
                hostingController.modalPresentationStyle = .fullScreen
                rootViewController.present(hostingController, animated: true)
            }
        }
    }
    
    // Helper method to find the tab bar controller
    private func findTabBarController(from viewController: UIViewController) -> UITabBarController? {
        if let tabBarController = viewController as? UITabBarController {
            return tabBarController
        }
        
        if let navigationController = viewController as? UINavigationController {
            return findTabBarController(from: navigationController.visibleViewController ?? navigationController)
        }
        
        if let presentedViewController = viewController.presentedViewController {
            return findTabBarController(from: presentedViewController)
        }
        
        return nil
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Only check for pending events if we actually received a deep link
        if receivedDeepLink {
            if let pendingEvent = pendingDeepLinkEvent {
                presentEventDetail(event: pendingEvent)
                pendingDeepLinkEvent = nil
                // Reset the flag after handling
                receivedDeepLink = false
            } else if let pendingEventId = UserDefaults.standard.string(forKey: "pendingEventId") {
                UserDefaults.standard.removeObject(forKey: "pendingEventId")
                openEvent(withId: pendingEventId)
                // Reset the flag after handling
                receivedDeepLink = false
            }
        }
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background
    }
    
    // MARK: - Authentication State Management
    // Note: Authentication state listener removed to prevent automatic logout on app close
    // The app now relies on the initial authentication check in scene(_:willConnectTo:options:)
}

extension SceneDelegate: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

fileprivate class AnyGestureRecognizer: UIGestureRecognizer {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if let touchedView = touches.first?.view, touchedView is UIControl {
            state = .cancelled

        } else if let touchedView = touches.first?.view as? UITextView, touchedView.isEditable {
            state = .cancelled

        } else {
            state = .began
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       state = .ended
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
}
