//
//  KBImage.swift
//  kiccbacc
//
//  Created by Guillermo Jimenez on 10/5/24.
//  Copyright © 2024 APPLE. All rights reserved.
//

import SwiftUI
import SDWebImageSwiftUI

struct KBImage: View {
    let url: URL
    var resizeMode: ContentMode = .fit
    var useCaching: Bool = true
    
    var body: some View {
        if useCaching {
            // Use SDWebImage for caching
            WebImage(url: url)
                .resizable()
                .indicator(.activity)
                .transition(.fade(duration: 0.2))
                .aspectRatio(contentMode: resizeMode)
        } else {
            // Fallback to AsyncImage for non-cached images
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    // More visible loading state
                    ProgressView()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .background(Color.gray.opacity(0.3))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: resizeMode)
                case .failure:
                    // Clear error state
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                        Text("Failed to load image")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.3))
                @unknown default:
                    EmptyView()
                }
            }
        }
    }
}
