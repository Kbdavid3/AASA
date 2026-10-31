//
//  NotificationBadgeView.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import SwiftUI

struct NotificationBadgeView: View {
    @StateObject private var notificationManager = EnhancedNotificationManager.shared
    
    let size: CGFloat
    let color: Color
    
    init(size: CGFloat = 16, color: Color = .red) {
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            if notificationManager.unreadNotifications.count > 0 {
                Circle()
                    .fill(color)
                    .frame(width: size, height: size)
                
                Text("\(min(notificationManager.unreadNotifications.count, 99))")
                    .font(.system(size: size * 0.6, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
            }
        }
    }
}

struct NotificationBadgeModifier: ViewModifier {
    @StateObject private var notificationManager = EnhancedNotificationManager.shared
    
    let size: CGFloat
    let color: Color
    let offset: CGSize
    
    init(size: CGFloat = 16, color: Color = .red, offset: CGSize = CGSize(width: 10, height: -10)) {
        self.size = size
        self.color = color
        self.offset = offset
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                NotificationBadgeView(size: size, color: color)
                    .offset(offset)
                    .opacity(notificationManager.unreadNotifications.count > 0 ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: notificationManager.unreadNotifications.count)
            )
    }
}

extension View {
    func notificationBadge(size: CGFloat = 16, color: Color = .red, offset: CGSize = CGSize(width: 10, height: -10)) -> some View {
        modifier(NotificationBadgeModifier(size: size, color: color, offset: offset))
    }
}

// MARK: - Preview
struct NotificationBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            NotificationBadgeView(size: 20)
            
            Image(systemName: "bell.fill")
                .font(.title)
                .notificationBadge()
        }
    }
}
