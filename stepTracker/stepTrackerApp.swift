//
//  stepTrackerApp.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI
import FirebaseCore

@main
struct stepTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appModel = AppModel()

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appModel)
        }
    }
}
