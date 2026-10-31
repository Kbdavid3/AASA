//
//  FirebaseStorageUploadStatus.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 25/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

enum FirebaseStorageUploadStatus {
    case uploaded(withURL: String?)
    case failed(withError: Error)
}
