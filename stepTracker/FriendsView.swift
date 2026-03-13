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
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Friends")
    }

    private var guestView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Compare steps with your friends once you sign in.")
                    .font(.title2.bold())

                Text("Guest mode keeps the tracker fully usable. Social features are optional and can be unlocked any time.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 12) {
                    Label("Daily leaderboard", systemImage: "list.number")
                    Label("Weekly rankings", systemImage: "chart.bar")
                    Label("Friendly step competitions", systemImage: "figure.run")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                Button("Sign in to unlock friends") {
                    appModel.toggleSignIn()
                }
                .buttonStyle(.borderedProminent)
                .tint(appModel.accentColor)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
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
                    .fill(friend.isCurrentUser ? appModel.accentColor : Color.secondary.opacity(0.18))
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
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FriendsView()
                .environmentObject(AppModel())
        }
    }
}
