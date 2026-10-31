//
//  MapAnnotationView.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 03/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

struct MapAnnotationView: View {
 
    var name: String
    
    @State private var isNamePopped: Bool = false
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack {
                Text(name)
            }
            .padding(10)
            .background(Color.bgColor)
            .cornerRadius(10)
            .offset(y: -65)
            .scaleEffect(isNamePopped ? 1 : 0)
            .font(.system(size: 19, weight: .regular, design: .rounded))
            .foregroundColor(.gray)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 0)
            
            Button {
                withAnimation { isNamePopped.toggle() }
                HapticGenerator.light.impactOccurred()
            } label: {
                Circle()
                    .fill(Color.appColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.appColor.opacity(0.5))
                            .frame(width: 40, height: 40)
                    )
                    .shadow(color: Color.appColor, radius: 10, x: 0, y: 0)
            }
            .buttonStyle(FlatLinkStyle())
        }
    }
}


struct MapAnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        MapAnnotationView(name: "place name")
//            .preferredColorScheme(.dark)
    }
}
