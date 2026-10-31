//
//  CircleIcon.swift
//  kiccbacc
//
//  Created by Assistant on 16/02/2025
//  Copyright © 2025 Assistant. All rights reserved.
//

import SwiftUI

struct CircleIcon: View {
    let systemName: String?
    let image: Image?
    let size: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    
    init(systemName: String, size: CGFloat = 40, backgroundColor: Color = .clear, foregroundColor: Color = .labelColor) {
        self.systemName = systemName
        self.image = nil
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    init(image: Image, size: CGFloat = 40, backgroundColor: Color = .clear, foregroundColor: Color = .labelColor) {
        self.systemName = nil
        self.image = image
        self.size = size
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: size, height: size)
                .background(BlurView(style: .systemThinMaterial))
                .clipShape(Circle())
            
            if let systemName = systemName {
                Image(systemName: systemName)
                    .foregroundColor(foregroundColor)
                    .font(.system(size: size * 0.4, weight: .medium))
            } else if let image = image {
                image
                    .foregroundColor(foregroundColor)
                    .font(.system(size: size * 0.4, weight: .medium))
            }
        }
    }
}

struct CircleIcon_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CircleIcon(systemName: "xmark")
            CircleIcon(image: Assets.UI.image)
            CircleIcon(systemName: "camera.rotate", size: 50, backgroundColor: .blue, foregroundColor: .white)
        }
        .padding()
    }
}


