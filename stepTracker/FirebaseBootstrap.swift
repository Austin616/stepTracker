//
//  FirebaseBootstrap.swift
//  stepTracker
//
//  Created by Codex on 3/16/26.
//

import Foundation

#if canImport(FirebaseCore)
import FirebaseCore
#endif

enum FirebaseBootstrap {
    static var hasGoogleServiceInfo: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }

    static var isFirebaseSDKAvailable: Bool {
        #if canImport(FirebaseCore)
        true
        #else
        false
        #endif
    }

    static var isConfigured: Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.app() != nil
        #else
        false
        #endif
    }

    static func configureIfPossible() {
        #if canImport(FirebaseCore)
        guard hasGoogleServiceInfo else { return }
        guard FirebaseApp.app() == nil else { return }
        FirebaseApp.configure()
        #endif
    }
}
