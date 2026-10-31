//
//  CustomInputField.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 24/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

struct CustomInputField: View {
    
    var title: String
    var placeholder: String?
    @Binding var newValue: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .padding(.leading)
                .font(.system(size: 14, weight: .regular, design: .default))
                .foregroundColor(.gray)
            
            TextField(placeholder == nil ? "" : placeholder!, text: $newValue)
                .padding(8)
                .background(Color.secondaryBgColor)
                .cornerRadius(10)
                .padding(.horizontal)
                .font(.system(size: 14, weight: .regular, design: .default))
        }
    }
}
