//
//  TestView.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 05/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import SwiftUI

struct TestView: View {
    var body: some View {
        VStack {
            Spacer()
            
            VStack {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack {
//                        ForEach(CameraFilter.allCases, id: \.rawValue) { cameraFilter in
//                            Button {
//
//                            } label: {
//                                Text(cameraFilter.title)
//                                    .padding(10)
//                                    .background(Color.red)
//                                    .clipShape(Capsule())
//                            }
//                            .buttonStyle(FlatLinkStyle())
//                        }
//                    }
//                }
//                .padding(.bottom)

                HStack {
                    Button {
                    } label: {
//                        StoryUploadView().CircleIcon(image: Assets.UI.image)
                    }

                    Spacer()

                    Button {
                        
                    } label: {
                        Circle()
                            .fill(Color.labelColor)
                            .frame(width: 60, height: 60, alignment: .center)
                            .overlay (
                                Circle()
                                    .stroke(Color.labelColor, lineWidth: 2)
                                    .frame(width: 70, height: 70, alignment: .center)
                            )
                    }

                    Spacer()

                    Button {
                        
                    } label: {
//                        StoryUploadView().CircleIcon(systemName: "arrow.triangle.2.circlepath.camera.fill")
                    }
                }
                .foregroundColor(.labelColor)
            }
            .padding(20)
            .padding(.top, 40)
            .padding(.bottom, 40)
            .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(20))
            .padding(-16)
        }
        .padding()
//        .padding(.vertical, 40)
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
            .ignoresSafeArea()
//            .preferredColorScheme(.dark)
    }
}
