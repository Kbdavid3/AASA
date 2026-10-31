//
//  PfpView.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 26/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

//import SDWebImageSwiftUI
import SwiftUI

struct PfpView: View {
    
    var user: User
    var size: CGFloat = 20
    var cornerRadius: CGFloat = 10
    var isRound: Bool = true
    var strokeWidth: CGFloat = 2
    
    init(user: User, size: CGFloat, cornerRadius: CGFloat, isRound: Bool, strokeWidth: CGFloat) {
        self.user = user
        self.size = size
        self.cornerRadius = cornerRadius
        self.isRound = isRound
        self.strokeWidth = strokeWidth
    }
    
    init(user: User, size: CGFloat, isRound: Bool, strokeWidth: CGFloat) {
        self.user = user
        self.size = size
        self.cornerRadius = 0
        self.isRound = isRound
        self.strokeWidth = strokeWidth
    }
    
    init(user: User, size: CGFloat, isRound: Bool) {
        self.user = user
        self.size = size
        self.cornerRadius = 0
        self.isRound = isRound
        self.strokeWidth = 0
    }
    
    init(user: User, size: CGFloat) {
        self.user = user
        self.size = size
        self.cornerRadius = 0
        self.isRound = false
        self.strokeWidth = 0
    }
    
    init(user: User, size: CGFloat, cornerRadius: CGFloat, strokeWidth: CGFloat) {
        self.user = user
        self.size = size
        self.cornerRadius = cornerRadius
        self.isRound = false
        self.strokeWidth = strokeWidth
    }
    
    var body: some View {
        if let pfpUrl = user.profileImageUrlString, let url = URL(string: pfpUrl) {
            KBImage(url: url)
                .modifier(PfpStyle(size: size, strokeWidth: strokeWidth, cornerRadius: cornerRadius, isRound: isRound))
                .onAppear {
                    print("🖼️ PfpView: Displaying profile image from URL: \(pfpUrl)")
                }
        } else {
            Rectangle()
                .foregroundColor(.appColor)
                .overlay(
                    Text(user.getInitials())
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.labelColor)
                )
                .modifier(PfpStyle(size: size, strokeWidth: strokeWidth, cornerRadius: cornerRadius, isRound: isRound))
                .onAppear {
                    print("🖼️ PfpView: No profile image URL found for user \(user.fullName), showing initials: \(user.getInitials())")
                }
        }
    }
    
    private struct PfpStyle: ViewModifier {
        
        var size: CGFloat = 20
        var strokeWidth: CGFloat
        var cornerRadius: CGFloat = 10
        var isRound: Bool = true
        
        func body(content: Content) -> some View {
            content
                .scaledToFill()
                .frame(width: size, height: size)
                .cornerRadius(isRound ? size/2 : cornerRadius)
                .overlay(isRound ? Circle().stroke(Color.secondaryBgColor, lineWidth: strokeWidth) : nil)
                .overlay(isRound ? nil : RoundedRectangle(cornerRadius: cornerRadius).stroke(Color.secondaryBgColor, lineWidth: strokeWidth))
                .shadow(color: .gray.opacity(strokeWidth != 0 ? 0.15 : 0), radius: 10, x: 0, y: 0)
        }
    }
}

struct PfpView_Provider: PreviewProvider {
    
    static var previews: some View {
        PfpView(user: User(), size: 300)
            .preferredColorScheme(.dark)
    }
}

