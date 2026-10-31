//
//  AnalyticsManager.swift
//  kiccbacc
//
//  Created by Siddharth Pillai on 4/1/25.
//  Copyright © 2025 APPLE. All rights reserved.
//

import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    
    // MARK: - Screen Tracking
    static func logScreenView(screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView, parameters: [
            AnalyticsParameterScreenName: screenName,
            AnalyticsParameterScreenClass: screenClass
        ])
    }
    
    // MARK: - User Properties
    static func setUserProperty(value: String?, forName name: String) {
        Analytics.setUserProperty(value, forName: name)
    }
    
    // MARK: - Common Events
    static func logLogin(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    static func logSignUp(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }
    
    static func logPurchase(amount: Double, currency: String, itemName: String, success: Bool) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterValue: amount,
            AnalyticsParameterCurrency: currency,
            AnalyticsParameterItemName: itemName,
            "success": success
        ])
    }
    
    static func logAddToCart(itemName: String, itemCategory: String, price: Double) {
        Analytics.logEvent(AnalyticsEventAddToCart, parameters: [
            AnalyticsParameterItemName: itemName,
            AnalyticsParameterItemCategory: itemCategory,
            AnalyticsParameterPrice: price
        ])
    }
    
    // MARK: - Custom Events
    static func logCustomEvent(name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
}
