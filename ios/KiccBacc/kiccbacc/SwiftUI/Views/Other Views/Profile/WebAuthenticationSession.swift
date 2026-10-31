//
//  WebAuthenticationSession.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI
import AuthenticationServices

struct WebAuthenticationSession: UIViewControllerRepresentable {
    let url: URL
    let callbackURLScheme: String
    let completionHandler: (URL?, Error?) -> Void

    func makeUIViewController(context: Context) -> WebAuthenticationViewController {
        return WebAuthenticationViewController(
            url: url,
            callbackURLScheme: callbackURLScheme,
            completionHandler: completionHandler
        )
    }

    func updateUIViewController(_ uiViewController: WebAuthenticationViewController, context: Context) {}
}

class WebAuthenticationViewController: UIViewController {
    private var authSession: ASWebAuthenticationSession?
    
    init(url: URL, callbackURLScheme: String, completionHandler: @escaping (URL?, Error?) -> Void) {
        super.init(nibName: nil, bundle: nil)
        
        authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme, completionHandler: completionHandler)
        authSession?.presentationContextProvider = self
    }
    
    required init?(coder: NSCoder) {
        // FIXED: Return nil instead of fatalError() for safe initialization
        print("⚠️ WebAuthenticationViewController: init(coder:) not supported, returning nil")
        return nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        authSession?.start()
    }
}

extension WebAuthenticationViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}
