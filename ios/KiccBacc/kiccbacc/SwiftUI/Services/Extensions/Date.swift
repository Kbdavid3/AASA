//
//  Date.swift
//  kiccbacc
//  Created by Siddharth Pillai on 16/02/2023
//  Copyright © 2023 Siddharth Pillai. All rights reserved.
//
import Foundation

extension Date {
    func getRelativeDate(from: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated

        let relativeDate = formatter.localizedString(for: self, relativeTo: from)
        return relativeDate
    }
    
    func addDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }
}
