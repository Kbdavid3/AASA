//
//  CameraError.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 05/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

enum CameraError: Error, Equatable {
    case deniedAuthorization
    case restrictedAuthorization
    case unknownAuthorization
    case cameraUnavailable
    case cannotAddInput
    case cannotAddOutput
    case createCaptureInput(Error)
    case setupFailed
    case sessionRuntimeError(String)
    case noFramesReceived
    case lowLightCondition
    case deviceDisconnected
    
    static func == (lhs: CameraError, rhs: CameraError) -> Bool {
        switch (lhs, rhs) {
        case (.deniedAuthorization, .deniedAuthorization),
             (.restrictedAuthorization, .restrictedAuthorization),
             (.unknownAuthorization, .unknownAuthorization),
             (.cameraUnavailable, .cameraUnavailable),
             (.cannotAddInput, .cannotAddInput),
             (.cannotAddOutput, .cannotAddOutput),
             (.setupFailed, .setupFailed),
             (.noFramesReceived, .noFramesReceived),
             (.lowLightCondition, .lowLightCondition),
             (.deviceDisconnected, .deviceDisconnected):
            return true
        case (.createCaptureInput(let lhsError), .createCaptureInput(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.sessionRuntimeError(let lhsString), .sessionRuntimeError(let rhsString)):
            return lhsString == rhsString
        default:
            return false
        }
    }
}
