//
//  SocialMediaLinksView.swift
//  kiccbacc
//
//  Created by Assistant on 16/02/2025
//  Copyright © 2025 Assistant. All rights reserved.
//

import SwiftUI
import SafariServices

struct SocialMediaLinksView: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 15) {
            // Instagram Link
            if let instagramUsername = user.instagramUsername, !instagramUsername.isEmpty {
                Button(action: {
                    openInstagram(username: instagramUsername)
                }) {
                    HStack(spacing: 8) {
                        Image("instagram")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("@\(instagramUsername)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink, Color.orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                }
            }
            
            // Snapchat Link
            if let snapchatUsername = user.snapchatUsername, !snapchatUsername.isEmpty {
                Button(action: {
                    openSnapchat(username: snapchatUsername)
                }) {
                    HStack(spacing: 8) {
                        Image("Snapchat-Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                        Text("@\(snapchatUsername)")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.yellow)
                    .cornerRadius(20)
                }
            }
            
            // Custom URL Link
            if let customURL = user.customURL, !customURL.isEmpty {
                Button(action: {
                    openCustomURL(url: customURL)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "link")
                            .font(.system(size: 16))
                        Text("Link")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
            }
        }
    }
    
    private func openInstagram(username: String) {
        let instagramURL = "https://www.instagram.com/\(username)"
        if let url = URL(string: instagramURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSnapchat(username: String) {
        let snapchatURL = "https://www.snapchat.com/add/\(username)"
        if let url = URL(string: snapchatURL) {
            UIApplication.shared.open(url)
        }
    }
    
    private func openCustomURL(url: String) {
        var urlString = url
        if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") {
            urlString = "https://" + urlString
        }
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

struct SocialMediaLinksView_Previews: PreviewProvider {
    static var previews: some View {
        SocialMediaLinksView(user: User())
            .preferredColorScheme(.dark)
    }
}
