//
//  CrashPrevention.swift
//  KiccBacc
//
//  Created by AI Assistant on 16/02/2025
//  Copyright © 2025 Siddharth Pillai. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI

/// Utility class for preventing common crash scenarios in the app
@MainActor
class CrashPrevention {
    
    // MARK: - Safe Threading Utilities
    
    /// Safely execute code on main actor with error handling
    static func safeMainActorExecution<T>(
        operation: @escaping () throws -> T,
        fallback: T,
        errorMessage: String = "Main actor operation failed"
    ) async -> T {
        do {
            return try await MainActor.run {
                try operation()
            }
        } catch {
            print("❌ \(errorMessage): \(error.localizedDescription)")
            return fallback
        }
    }
    
    /// Safely execute background tasks with proper error handling
    static func safeBackgroundTask<T>(
        priority: TaskPriority = .userInitiated,
        operation: @escaping () throws -> T,
        completion: @escaping @MainActor (Result<T, Error>) -> Void
    ) {
        Task.detached(priority: priority) {
            do {
                let result = try operation()
                await MainActor.run {
                    completion(.success(result))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Safe Unwrapping Utilities
    
    /// Safely unwrap optional with logging
    static func safeUnwrap<T>(
        _ optional: T?,
        errorMessage: String = "Failed to unwrap optional",
        file: String = #file,
        line: Int = #line
    ) -> T? {
        guard let value = optional else {
            print("⚠️ \(errorMessage) at \(file):\(line)")
            return nil
        }
        return value
    }
    
    /// Safely unwrap optional with fallback value
    static func safeUnwrap<T>(
        _ optional: T?,
        fallback: T,
        errorMessage: String = "Using fallback value",
        file: String = #file,
        line: Int = #line
    ) -> T {
        guard let value = optional else {
            print("⚠️ \(errorMessage) at \(file):\(line)")
            return fallback
        }
        return value
    }
    
    // MARK: - iOS Version Compatibility
    
    /// Check if running on iOS 16 or later
    static var isIOS16OrLater: Bool {
        if #available(iOS 16.0, *) {
            return true
        } else {
            return false
        }
    }
    
    /// Execute code with iOS version compatibility
    static func executeWithCompatibility<T>(
        ios16Operation: () throws -> T,
        legacyOperation: () throws -> T,
        fallback: T
    ) -> T {
        do {
            if #available(iOS 16.0, *) {
                return try ios16Operation()
            } else {
                return try legacyOperation()
            }
        } catch {
            print("❌ Compatibility operation failed: \(error.localizedDescription)")
            return fallback
        }
    }
    
    // MARK: - Safe UI Operations
    
    /// Safely get current window scene
    static func getCurrentWindowScene() -> UIWindowScene? {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            print("⚠️ Failed to get active window scene")
            return nil
        }
        return windowScene
    }
    
    /// Safely get key window
    static func getKeyWindow() -> UIWindow? {
        guard let windowScene = getCurrentWindowScene() else { return nil }
        return windowScene.windows.first(where: { $0.isKeyWindow })
    }
    
    // MARK: - Safe Notification Handling
    
    /// Safely post notification with error handling
    static func safePostNotification(
        name: Notification.Name,
        object: Any? = nil,
        userInfo: [AnyHashable: Any]? = nil
    ) {
        do {
            NotificationCenter.default.post(
                name: name,
                object: object,
                userInfo: userInfo
            )
        } catch {
            print("❌ Failed to post notification \(name): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Safe UserDefaults Operations
    
    /// Safely get value from UserDefaults
    static func safeUserDefaultsValue<T>(
        key: String,
        type: T.Type,
        fallback: T
    ) -> T {
        guard let value = UserDefaults.standard.object(forKey: key) as? T else {
            print("⚠️ Failed to get UserDefaults value for key: \(key), using fallback")
            return fallback
        }
        return value
    }
    
    /// Safely set value in UserDefaults
    static func safeSetUserDefaults<T>(
        key: String,
        value: T
    ) {
        do {
            UserDefaults.standard.set(value, forKey: key)
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ Failed to set UserDefaults value for key \(key): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Memory Management Helpers
    
    /// Check available memory and warn if low
    static func checkMemoryUsage() {
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsedMB = Double(info.resident_size) / (1024 * 1024)
            if memoryUsedMB > 200 { // Warn if using more than 200MB
                print("⚠️ High memory usage detected: \(String(format: "%.1f", memoryUsedMB))MB")
            }
        }
    }
    
    // MARK: - Safe Array Operations
    
    /// Safely access array element
    static func safeArrayAccess<T>(
        _ array: [T],
        index: Int,
        fallback: T? = nil
    ) -> T? {
        guard index >= 0 && index < array.count else {
            print("⚠️ Array index \(index) out of bounds for array of size \(array.count)")
            return fallback
        }
        return array[index]
    }
    
    /// Safely remove array element
    static func safeArrayRemove<T>(
        _ array: inout [T],
        at index: Int
    ) -> Bool {
        guard index >= 0 && index < array.count else {
            print("⚠️ Cannot remove array element at index \(index) - out of bounds")
            return false
        }
        array.remove(at: index)
        return true
    }
}

// MARK: - Safe Extensions

extension Optional {
    /// Safely unwrap with custom error message
    func safeUnwrap(
        errorMessage: String = "Failed to unwrap optional",
        file: String = #file,
        line: Int = #line
    ) -> Wrapped? {
        return CrashPrevention.safeUnwrap(self, errorMessage: errorMessage, file: file, line: line)
    }
    
    /// Safely unwrap with fallback
    func safeUnwrap(
        fallback: Wrapped,
        errorMessage: String = "Using fallback value",
        file: String = #file,
        line: Int = #line
    ) -> Wrapped {
        return CrashPrevention.safeUnwrap(self, fallback: fallback, errorMessage: errorMessage, file: file, line: line)
    }
}

extension Array {
    /// Safe subscript that returns nil instead of crashing
    subscript(safe index: Int) -> Element? {
        return CrashPrevention.safeArrayAccess(self, index: index)
    }
}
