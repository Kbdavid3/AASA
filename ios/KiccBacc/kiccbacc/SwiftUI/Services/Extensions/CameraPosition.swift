//
//  CameraPosition.swift
//  kiccbacc
//  Created by Siddharth Pillai on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import AVFoundation

typealias CameraPosition = AVCaptureDevice.Position

extension CameraPosition {
    mutating func toggle() {
        if self == .front {
            self = .back
        } else if self == .back {
            self = .front
        }
    }
    
    func flipMessage() {
        switch self {
        case .unspecified:
            print("flipped to unspecified")
        case .back:
            print("camera flipped to back")
        case .front:
            print("camera flipped to front")
        @unknown default:
            print("camera flipped to unknown")
        }
    }
}
