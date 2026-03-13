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
                        .frame(width: 56, height: 56)
                        .overlay {
                            Text(appModel.profile.initials)
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appModel.profile.name)
                            .font(.title3.bold())
                        Text(appModel.isSignedIn ? "Signed in for social features" : "Using guest mode")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Tracker") {
                LabeledContent("Daily goal", value: "\(appModel.dailyGoal.formatted()) steps")
                LabeledContent("Health access", value: "Not connected yet")
                LabeledContent("Default mode", value: "Guest-friendly")
            }

            Section("Account") {
                Button(appModel.isSignedIn ? "Sign out" : "Sign in later") {
                    appModel.toggleSignIn()
                }
                .foregroundStyle(appModel.accentColor)
            }
        }
        .navigationTitle("Profile")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(AppModel())
        }
    }
}
