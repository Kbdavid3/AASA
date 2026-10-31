//
//  FirebaseError.swift
//  
//
//  Created by Ankit Yadav on 25/01/22.
//

import Foundation

enum FirebaseError: Error {
    case noDocumentsFound
    case undefined
    case userNotFound
    case badJSON
    case withError(error: Error)
}
