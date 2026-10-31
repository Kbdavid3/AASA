//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//
import SwiftUI
import WebKit

struct SquareAuthWebView: UIViewRepresentable {
    @Binding var isAuthorized: Bool
    @Binding var merchantId: String?
    @Environment(\.presentationMode) var presentationMode

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let squareAuthURL = "https://squareauth-7ce4gb3x2q-uc.a.run.app/auth"
        if let url = URL(string: squareAuthURL) {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: SquareAuthWebView

        init(_ parent: SquareAuthWebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.scheme == "kiccbacc" {
                // Parse merchantId from URL
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                   let queryItems = components.queryItems,
                   let merchantId = queryItems.first(where: { $0.name == "merchantId" })?.value {
                    parent.merchantId = merchantId
                    parent.isAuthorized = true
                }
                parent.presentationMode.wrappedValue.dismiss()
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
