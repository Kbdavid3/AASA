//
//  FirestoreService.swift
//  kiccbacc
//
//  Created by Ankit Yadav on 03/03/22.
//  Copyright © 2022 APPLE. All rights reserved.
//

//import CodableFirebase
import FirebaseStorage
import FirebaseFirestore
//import FirebaseFirestoreSwift

struct FirestoreService {
    
    private static let database = Firestore.firestore()
    
    static func convertModelToDictionary<T: Codable>(object: T) -> [String : Any]? {
        try? Firestore.Encoder().encode(object)
    }
 
    static func createDocumentInCollection<T: Encodable>(object: T, id: String, collectionName: String) throws {
        
        do {
            try database
                .collection(collectionName)
                .document(id)
                .setData(from: object)
        } catch {
            throw error
        }
    }
    
    static func createOrUpdateDocumentInCollection<T: Encodable>(object: T, id: String, collectionName: String, merge: Bool = true) throws {
        
        do {
            try database
                .collection(collectionName)
                .document(id)
                .setData(from: object, merge: merge)
        } catch {
            throw error
        }
    }
    
    static func getDocument<T: Codable>(inCollection: String, withID: String, completion: @escaping (T?) -> ()) {
        database
            .collection(inCollection)
            .document(withID)
            .getDocument { (document, error) in
                do {
                    let document = try document?.data(as: T.self)
                    completion(document)
                } catch {
                    completion(nil)
                }
            }
    }
    
    static func getDocuments<T: Codable>(inCollection: String, whereField: String, isEqualTo: Any, completion: @escaping ([T]?) -> ()) {
        Task {
            do {
                let snapshot = try await database
                    .collection(inCollection)
                    .whereField(whereField, isEqualTo: isEqualTo)
                    .getDocuments()
                
                let myObjects = snapshot.documents.compactMap { document in
                    try? document.data(as: T.self)
                }
                
                completion(myObjects)
            } catch {
                completion(nil)
            }
        }
    }
    
    static func getDocuments<T: Codable>(inCollection: String, whereField: String, arrayContains: Any, completion: @escaping ([T]?) -> ()) {
        Task {
            do {
                let snapshot = try await database
                    .collection(inCollection)
                    .whereField(whereField, arrayContains: arrayContains)
                    .getDocuments()
                
                let myObjects = snapshot.documents.compactMap { document in
                    try? document.data(as: T.self)
                }
                
                completion(myObjects)
            } catch {
                completion(nil)
            }
        }
    }
    
    static func getDocumentsForArray<T: Codable>(inCollection: String, whereField: String, arrayContains: [Any], completion: @escaping ([T]?) -> ()) {
        Task {
            do {
                let snapshot = try await database
                    .collection(inCollection)
                    .whereField(whereField, arrayContainsAny: arrayContains)
                    .getDocuments()
                
                let myObjects = snapshot.documents.compactMap { document in
                    try? document.data(as: T.self)
                }
                
                completion(myObjects)
            } catch {
                completion(nil)
            }
        }
    }
    
    static func getDocuments<T: Codable>(inCollection: String, whereField: String, values: [Any], completion: @escaping ([T]?) -> ()) {
        Task {
            do {
                let snapshot = try await database
                    .collection(inCollection)
                    .whereField(whereField, isEqualTo: values)
                    .getDocuments()
                
                let myObjects = snapshot.documents.compactMap { document in
                    try? document.data(as: T.self)
                }
                completion(myObjects)
            } catch {
                completion(nil)
            }
        }
    }
    
    static func getDocumentsWithSnapshotListener<T: Codable>(inCollection: String, whereField: String, isEqualTO: Any, completion: @escaping ([T]?) -> ()) {
        database
            .collection(inCollection)
            .whereField(whereField, isEqualTo: isEqualTO)
            .limit(toLast: 50)
            .addSnapshotListener { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion(nil)
                    return
                }
                
                let myObjects = snapshot.documents.compactMap { document in
                    try? document.data(as: T.self)
                }
                
                completion(myObjects)
            }
    }
    
    static func update(in collection: String, documentID: String, withValues: [String: Any]) throws {
        Task {
            let docRef = database
                .collection(collection)
                .document(documentID)
            
            do {
                try await docRef.updateData(withValues)
            } catch {
                throw error
            }
        }
    }
    
    static func updateAsync(in collection: String, documentID: String, withValues: [String: Any]) async throws {
        let docRef = database
            .collection(collection)
            .document(documentID)
        
        try await docRef.updateData(withValues)
    }
    
    static func getAllDocuments<T: Codable>(inCollection: String, completion: @escaping ([T]?) -> ()) {
        
        Task {
            do {
                let snapshot = try await database
                    .collection(inCollection)
                    .getDocuments()
                
                let myObjects = snapshot.documents.compactMap { document in
                    try? document.data(as: T.self)
                }
                
                completion(myObjects)
            } catch {
                completion(nil)
            }
        }
    }
    
    static func uploadImage(with data: Data, fileName: String, withChild: String, completion: @escaping (Result<FirebaseStorageUploadStatus,Error>) -> Void) {
     
        // Validate input data
        guard !data.isEmpty else {
            completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty data provided"])))
            return
        }
        
        // Check data size to prevent memory issues
        let maxSize: Int64 = 10 * 1024 * 1024 // 10MB limit
        if Int64(data.count) > maxSize {
            completion(.failure(NSError(domain: "FirestoreService", code: -2, userInfo: [NSLocalizedDescriptionKey: "File size too large. Maximum size is 10MB"])))
            return
        }
        
        let bucket = Storage.storage().reference()
        let documentPath = bucket.child(withChild)
        
        // Create metadata for better upload handling
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Add timeout and progress tracking
        let uploadTask = documentPath.putData(data, metadata: metadata) { (metadata, error) in
            guard metadata != nil else {
                if let error = error {
                    print("Upload error: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "FirestoreService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Upload failed - no metadata returned"])))
                }
                return
            }
            
            documentPath.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    // Uh-oh, an error occurred!
                    if let error = error {
                        print("Download URL error: \(error.localizedDescription)")
                        completion(.failure(error))
                    } else {
                        completion(.failure(NSError(domain: "FirestoreService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    }
                    return
                }
                
                // return uploaded url
                completion(.success(.uploaded(withURL: downloadURL.absoluteString)))
            }
        }
        
        // Add timeout protection
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { // 60 second timeout
            uploadTask.cancel()
            completion(.failure(NSError(domain: "FirestoreService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Upload timed out"])))
        }
    }
    
    static func searchDocument<T: Codable>(inCollection: String, field: String, withSearchText: String, completion: @escaping ([T]?) -> ()) {
        
        print("searching for ", withSearchText)
        
        print (
            """
            
            -----------
            \([withSearchText])
            \(withSearchText) \u{f8ff}
            -----------
            
            """
        )
        
        database
            .collection(inCollection)
            .order(by: field)
            .start(at: [withSearchText])
            .end(before: ["\(withSearchText) \u{f8ff}"])
            .getDocuments { snapshot, error in
                guard let snapshot = snapshot, error == nil else {
                    completion(nil)
                    return
                }

                let myData = snapshot.documents.compactMap { document in
                    try? document.data(as: T.self)
                }

                print("found ", myData.count, " documents")
                
                completion(myData)
            }
        
//        database
//            .collection(inCollection)
//            .whereField(field, isLessThan: withSearchText)
//            .addSnapshotListener { snapshot, error in
//                guard error == nil else {
//                    print(error!.localizedDescription)
//                    completion(nil)
//                    return
//                }
//
//                let myData = snapshot?.documents.compactMap{ document in
//                    try? document.data(as: T.self)
//                }
//
//                print("found ", myData?.count, " documents")
//
//                completion(myData)
//            }
    }
}

