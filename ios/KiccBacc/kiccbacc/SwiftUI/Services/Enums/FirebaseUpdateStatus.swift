//
//  FirebaseUpdateStatus.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 26/01/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

import Foundation

enum FirebaseUpdateStatus {
    case updated
    case failed(withError: Error)
}
