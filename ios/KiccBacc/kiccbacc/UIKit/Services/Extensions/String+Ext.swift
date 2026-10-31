//
//  String+Ext.swift
//  kiccbacc
//
//  Created by Colin Murphy on 1/7/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import Foundation

// MARK: - Optional String Extension for Safety
extension Optional where Wrapped == String {
    /// Safely check if optional string is nil or empty
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

extension String {
    
    func capitalizeFirstCharacter() -> String {
        return prefix(1).uppercased() + lowercased().dropFirst()
    }
    
    func compareDate(to value: String) -> Bool {
        
        let format = DateFormatter()
        format.dateFormat = "d MMM yyyy h:mm a"
        
        if let dateA = format.date(from: self),
           let dateB = format.date(from: value) {
            return dateA > dateB
        } else {
            return true
        }
    }
    
    func convertDate() -> String {
        let format = DateFormatter()
        format.dateFormat = "d MMM yyyy h:m a"
        guard let date = format.date(from: self) else { return self }
        
        let newFormat = DateFormatter()
        newFormat.dateFormat = "MMM d, yyyy"
        return newFormat.string(from: date)
    }
    
    func compareTime(to value: String) -> Bool {
        if self == "now" {
            return true
        } else if value == "now" {
            return false
        }
        
        if hasSuffix("m") && value.hasSuffix("m") {
            return self > value
        } else if hasSuffix("m") && !value.hasSuffix("m") {
            return true
        } else if value.hasSuffix("m") && !hasSuffix("m") {
            return false
        }
        
        if contains("h") && value.contains("h") {
            return self > value
        } else if contains("h") && !value.contains("h") {
            return true
        } else if value.contains("h") && !contains("h") {
            return false
        }
        
        if contains("d") && value.contains("d") {
            return self > value
        } else if contains("d") && !value.contains("d") {
            return true
        } else if value.contains("d") && !contains("d") {
            return false
        }

        if contains("w") && value.contains("w") {
            return self > value
        } else if contains("w") && !value.contains("w") {
            return true
        } else if value.contains("w") && !contains("w") {
            return false
        }

        if contains("mn") && value.contains("mn") {
            return self > value
        } else if contains("mn") && !value.contains("mn") {
            return true
        } else if value.contains("mn") && !contains("mn") {
            return false
        }
        
        if contains("yr") && value.contains("yr") {
            return self > value
        } else if contains("yr") && !value.contains("yr") {
            return true
        } else if value.contains("yr") && !contains("yr") {
            return false
        }
        return true
    }
}
