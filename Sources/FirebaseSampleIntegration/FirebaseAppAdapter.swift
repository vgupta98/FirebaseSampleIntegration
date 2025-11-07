//
//  File.swift
//  FirebaseSampleIntegration
//
//  Created by Vishal Gupta on 07/11/25.
//

import Foundation
import FirebaseCore

protocol FirebaseAppAdapter {
    var isConfigured: Bool { get }
    func configure()
}

// MARK - Actual Implementation
class FirebaseAppAdapterImpl: FirebaseAppAdapter {
    var isConfigured: Bool { FirebaseApp.app() != nil }
    
    func configure() {
        DispatchQueue.main.sync {
            FirebaseApp.configure()
        }
    }
}

// MARK - Mock Implementation
class MockFirebaseAppAdapter: FirebaseAppAdapter {
    var configured = false

    var isConfigured: Bool { configured }

    func configure() {
        configured = true
    }
}
