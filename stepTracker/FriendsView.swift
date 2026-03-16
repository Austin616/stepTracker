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
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if appModel.isSignedIn {
                    heroSummary
                    leaderboardSection
                    socialActionsSection
                } else {
                    guestSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(SignalBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FRIENDS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(appModel.accentColor)
            Text("Step together.")
                .font(.system(size: 42, weight: .bold))
            Text("A lightweight social layer when you want rankings and comparison.")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var heroSummary: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("#\(appModel.currentUserStanding)")
                    .font(.system(size: 64, weight: .bold))
                    .monospacedDigit()
                Text("your position today")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(appModel.todaySteps.formatted())
                    .font(.system(size: 28, weight: .bold))
                    .monospacedDigit()
                Text("steps")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var guestSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Social is optional")
                    .font(.system(size: 28, weight: .bold))
                Text("Track steps on your own first. Sign in only when you want rankings, friend comparisons, or simple competitions.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)

                Button("Sign in to unlock friends") {
                    appModel.toggleSignIn()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(appModel.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 14) {
                featureRow(icon: "list.number", title: "Daily leaderboard", subtitle: "See who moved most today.")
                featureRow(icon: "chart.bar", title: "Weekly rankings", subtitle: "Compare stronger and slower weeks.")
                featureRow(icon: "figure.run", title: "Friendly challenges", subtitle: "Keep the competition lightweight.")
            }
        }
    }

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Today")
                .font(.system(size: 30, weight: .bold))

            VStack(spacing: 12) {
                ForEach(appModel.leaderboard.indices, id: \.self) { index in
                    let friend = appModel.leaderboard[index]
                    leaderboardRow(friend: friend, rank: index + 1)
                }
            }
        }
    }

    private func leaderboardRow(friend: FriendStanding, rank: Int) -> some View {
        HStack(spacing: 14) {
            Text("#\(rank)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 30)

            Circle()
                .fill(friend.isCurrentUser ? appModel.accentColor : appModel.secondarySurfaceColor)
                .frame(width: 46, height: 46)
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
                .font(.system(size: 22, weight: .bold).monospacedDigit())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(friend.isCurrentUser ? appModel.accentColor.opacity(0.12) : appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.62 : 0.74))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.05), lineWidth: 1)
                )
        )
    }

    private var socialActionsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Social mode is active")
                    .font(.system(size: 16, weight: .semibold))
                Text("Turn it off any time and keep the local tracker flow.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Sign out of social mode") {
                appModel.toggleSignIn()
            }
            .buttonStyle(.plain)
            .foregroundStyle(appModel.accentColor)
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(appModel.accentColor)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
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
