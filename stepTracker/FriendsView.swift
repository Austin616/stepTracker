//
//  FriendsView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Group {
            if appModel.isSignedIn {
                signedInView
            } else {
                guestView
            }
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Friends")
    }

    private var guestView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StepCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Social is optional")
                            .font(.title2.bold())
                        Text("You can track steps as a guest. Sign in only when you want rankings, friend comparisons, or shared challenges.")
                            .foregroundStyle(.secondary)
                        Button("Sign in to unlock friends") {
                            appModel.toggleSignIn()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.accentColor)
                    }
                }

                StepCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What this tab will do")
                            .font(.title3.bold())
                        Label("Daily leaderboard", systemImage: "list.number")
                        Label("Weekly rankings", systemImage: "chart.bar")
                        Label("Simple step competitions", systemImage: "figure.run")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
    }

    private var signedInView: some View {
        List(appModel.leaderboard.indices, id: \.self) { index in
            let friend = appModel.leaderboard[index]

            HStack(spacing: 14) {
                Text("#\(index + 1)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 32)

                Circle()
                    .fill(friend.isCurrentUser ? appModel.accentColor : Color.secondary.opacity(0.16))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Text(friend.initials)
                            .font(.subheadline.bold())
                            .foregroundStyle(friend.isCurrentUser ? .white : .primary)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(friend.name)
                        .fontWeight(friend.isCurrentUser ? .bold : .semibold)
                    Text(friend.isCurrentUser ? "You" : "Friend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(friend.steps.formatted())
                    .font(.headline.monospacedDigit())
            }
            .padding(.vertical, 6)
            .listRowBackground(friend.isCurrentUser ? appModel.accentColor.opacity(0.12) : nil)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            Button("Sign out of social mode") {
                appModel.toggleSignIn()
            }
            .buttonStyle(.bordered)
            .padding()
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [appModel.backgroundTop, appModel.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FriendsView()
                .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
        }
    }
}
