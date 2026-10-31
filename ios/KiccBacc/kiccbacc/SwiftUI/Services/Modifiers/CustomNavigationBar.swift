//
//  CustomNavigationBar.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

fileprivate struct CustomNavigationBar: ViewModifier {
    
    @Environment(\.presentationMode) private var presentationMode
    
    var title: String
    
    func body(content: Content) -> some View {
        NavigationView {
            VStack {
                HStack {
                    Text(title)
                        .font(.system(size: 30, weight: .bold, design: .default))

                    Spacer()

                    NavigationLink {
                        SelfProfileView()
                    } label: {
                        Assets.Sample.user
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)

                content
            }
            .navigationBarHidden(true)
            .navigationTitle("")
        }
    }
}

extension View {
    func customNavigationBar(title: String) -> some View {
        modifier(CustomNavigationBar(title: title))
    }
}
