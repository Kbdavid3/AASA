//
//  CameraFilter.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 05/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

enum CameraFilter: Int, CaseIterable {
    case none = 0
    case mono
    case bloom
    case crystal
    case pixelate
}

extension CameraFilter {
    var title: String {
        switch self {
        case .none:
            return "None"
        case .mono:
            return "Mono"
        case .crystal:
            return "Crystal"
        case .bloom:
            return "Bloom"
        case .pixelate:
            return "Pixelate"
        }
    }
    
    var filterIdentifier: String {
        switch self {
        case .none:
            return ""
        case .mono:
            return "CIPhotoEffectNoir"
        case .bloom:
            return "CIBloom"
        case .pixelate:
            return "CIHexagonalPixellate"
        case .crystal:
            return "CICrystallize"
        }
    }
}
