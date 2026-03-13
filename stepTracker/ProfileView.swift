//
//  ProfileView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(appModel.accentColor)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Text(appModel.profile.initials)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appModel.profile.name)
                            .font(.title3.bold())
                        Text(appModel.isSignedIn ? "Signed in for social features" : "Guest mode")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Tracker") {
                LabeledContent("Daily goal", value: "\(appModel.dailyGoal.formatted()) steps")
                LabeledContent("Health status", value: profileHealthStatus)
                LabeledContent("Tracker mode", value: "Local-first")
            }

            Section("Account") {
                Button(appModel.isSignedIn ? "Sign out" : "Sign in later") {
                    appModel.toggleSignIn()
                }
                .foregroundStyle(appModel.accentColor)
            }
        }
        .scrollContentBackground(.hidden)
        .background(
            LinearGradient(
                colors: [appModel.backgroundTop, appModel.backgroundBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Profile")
    }

    private var profileHealthStatus: String {
        switch appModel.authorizationState {
        case .authorized: return "Connected"
        case .denied: return "Denied"
        case .notDetermined: return "Not connected"
        case .unavailable: return "Unavailable"
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
        }
    }
}
