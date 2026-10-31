//
//  CustomScrollView.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 15/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

enum NavigationStyle: Equatable {
    case none
    case dismissBack(title: String)
    case custom
    case system(title: String)
    
    static func ==(lhs: NavigationStyle, rhs: NavigationStyle) -> Bool {
        switch (lhs, rhs) {
        case (.dismissBack(title: _), .dismissBack(title: _)):
            return true
        case (.system(title: _), .system(title: _)):
            return true
        default:
            return false
        }
    }
}

enum PresentationStyle {
    case none
    case fullScreen
    case modal
}

struct CustomScrollView<Content: View>: View {
    
    @Environment(\.presentationMode) private var presentation
    
    var navigationStyle: NavigationStyle
    var navigationView: (() -> Content)?
    var scrollViewData: (() -> Content)
    var isEmbeddedInNavigationView: Bool = false
    @Binding var alertItem: (AlertItem?)
    @Binding var viewControllerItem: (UIKitViewControllerItem?)
    @Binding var viewItem: (ViewItem?)
    
    init(
        navigationStyle: NavigationStyle,
        scrollViewData: @escaping (() -> Content),
        isEmbeddedInNavigationView: Bool = false,
        alertItem: Binding<(AlertItem?)>,
        viewControllerItem: Binding<(UIKitViewControllerItem?)>,
        viewItem: Binding<(ViewItem?)>
    ) {
        self.navigationStyle = navigationStyle
        self.scrollViewData = scrollViewData
        self.isEmbeddedInNavigationView = isEmbeddedInNavigationView
        self._alertItem = alertItem
        self._viewItem = viewItem
        self._viewControllerItem = viewControllerItem
    }
    
    init(
        navigationStyle: NavigationStyle,
        navigationView: (() -> Content)?,
        scrollViewData: @escaping (() -> Content),
        isEmbeddedInNavigationView: Bool = false,
        alertItem: Binding<(AlertItem?)>,
        viewControllerItem: Binding<(UIKitViewControllerItem?)>,
        viewItem: Binding<(ViewItem?)>
    ) {
        self.navigationStyle = navigationStyle
        self.scrollViewData = scrollViewData
        self.navigationView = navigationView
        self.isEmbeddedInNavigationView = isEmbeddedInNavigationView
        self._alertItem = alertItem
        self._viewItem = viewItem
        self._viewControllerItem = viewControllerItem
    }
    
    var body: some View {
        if isEmbeddedInNavigationView {
            NavigationView {
                ContentView()
                    .navigationBarTitle(navigationTitle)
                    .navigationBarHidden(true)
            }
        } else {
            ContentView()
                .navigationBarHidden(true)
                .navigationBarTitle(navigationTitle)
        }
    }
    
    @ViewBuilder
    private func ContentView() -> some View {
        VStack(alignment: .center, spacing: 10) {
            if navigationStyle == .dismissBack(title: "") {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Assets.UI.arrowLeft
                            .foregroundColor(.labelColor)
                    }
                    
                    Text(navigationTitle)
                        .font(.system(size: 22, weight: .bold, design: .default))

                    Spacer()
                }
                .padding([.horizontal, .top])
            } else if navigationStyle == .custom, let navigationView = navigationView {
                navigationView()
            }
            
            ScrollView(.vertical, showsIndicators: false) {
                scrollViewData()
            }
        }
        .alert(item: $alertItem) { alertItem in
            guard let primaryButton = alertItem.primaryButton, let secondaryButton = alertItem.secondaryButton
            else {
                return Alert(title: alertItem.title, message: alertItem.message, dismissButton: alertItem.dismissButton)
            }
            
            return Alert(title: alertItem.title, message: alertItem.message, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
        .if(viewControllerItem?.presentationStyle == .modal) { view in
            view
                .sheet(item: $viewControllerItem) { vcItem in
                    UIKitVisualisationHelper(viewController: vcItem.viewController)
                        .ignoresSafeArea()
                }
        }
        .if(viewControllerItem?.presentationStyle == .fullScreen) { view in
            view
                .fullScreenCover(item: $viewControllerItem) { vcItem in
                    UIKitVisualisationHelper(viewController: vcItem.viewController)
                        .ignoresSafeArea()
                }
        }
        .if(viewItem?.presentationStyle == .fullScreen) { view in
            view
                .fullScreenCover(item: $viewItem) { viewItem in
                    viewItem.viewToPresent
                }
        }
        .if(viewItem?.presentationStyle == .modal) { view in
            view
                .sheet(item: $viewItem) { } content: { viewItem in
                    viewItem.viewToPresent
                }
        }
    }
    
    private func dismiss() {
        presentation.wrappedValue.dismiss()
    }
    
    private var navigationTitle: String {
        switch navigationStyle {
        case .none, .custom:
            return ""
        case .dismissBack(title: let title):
            return title
        case .system(title: let title):
            return title
        }
    }
}

struct CustomScrollView_Previews: PreviewProvider {
    static var previews: some View {
        CustomScrollView(navigationStyle: .dismissBack(title: "@escaping"), scrollViewData: {
            Text("Lol bhai lol")
        }, isEmbeddedInNavigationView: false, alertItem: .constant(nil), viewControllerItem: .constant(nil), viewItem: .constant(nil))
    }
}
