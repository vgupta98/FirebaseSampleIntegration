//
//  File.swift
//  FirebaseSampleIntegration
//
//  Created by Vishal Gupta on 07/11/25.
//

import Foundation
import FirebaseAnalytics

protocol FirebaseAnalyticsAdapter {
    func setUserID(_ id: String?)
    func setUserProperty(_ value: String?, forName: String)
    func logEvent(_ name: String, parameters: [String: Any]?)
    func getAnalyticsInstance() -> Any?
}

// MARK - Actual Implementation

class FirebaseAnalyticsAdapterImpl: FirebaseAnalyticsAdapter {
    func setUserID(_ id: String?) {
        FirebaseAnalytics.Analytics.setUserID(id)
    }

    func setUserProperty(_ value: String?, forName: String) {
        FirebaseAnalytics.Analytics.setUserProperty(value, forName: forName)
    }

    func logEvent(_ name: String, parameters: [String : Any]?) {
        FirebaseAnalytics.Analytics.logEvent(name, parameters: parameters)
    }
    
    func getAnalyticsInstance() -> Any? {
        return FirebaseAnalytics.Analytics.self
    }
}


// MARK - Mock Implementation

class MockFirebaseAnalyticsAdapter: FirebaseAnalyticsAdapter {
    var setUserIDCals: [String?] = []
    var setUserPropertyCalls: [(name: String, value: String?)] = []
    var logEventCalls: [(name: String, parameters: [String: Any]?)] = []

    func setUserID(_ id: String?) {
        setUserIDCals.append(id)
    }

    func setUserProperty(_ value: String?, forName: String) {
        setUserPropertyCalls.append((forName, value))
    }

    func logEvent(_ name: String, parameters: [String: Any]?) {
        logEventCalls.append((name, parameters))
    }
    
    func getAnalyticsInstance() -> Any? {
        return nil
    }
}
