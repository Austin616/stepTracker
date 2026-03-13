//
//  AppModel.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import Combine
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var dailyGoal = 10_000
    @Published var selectedTrendRange: TrendRange = .day

    let profile = UserProfile(name: "Austin", initials: "AT")
    let accentColor = Color(red: 0.09, green: 0.63, blue: 0.52)

    let todaySteps: Int
    let weeklySteps: [DayStepTotal]
    let hourlySteps: [HourStepTotal]
    let monthlySteps: [DayStepTotal]
    let friends: [FriendStanding]

    init() {
        weeklySteps = AppModel.makeWeeklySteps()
        hourlySteps = AppModel.makeHourlySteps()
        monthlySteps = AppModel.makeMonthlySteps()
        friends = AppModel.makeFriends(currentUserName: profile.name)
        todaySteps = weeklySteps.last?.steps ?? 0
    }

    var todayProgress: Double {
        min(Double(todaySteps) / Double(dailyGoal), 1.0)
    }

    var weeklyTotal: Int {
        weeklySteps.reduce(0) { $0 + $1.steps }
    }

    var weeklyAverage: Int {
        weeklyTotal / max(weeklySteps.count, 1)
    }

    var bestHour: HourStepTotal? {
        hourlySteps.max(by: { $0.steps < $1.steps })
    }

    var busiestDay: DayStepTotal? {
        weeklySteps.max(by: { $0.steps < $1.steps })
    }

    var leaderboard: [FriendStanding] {
        friends.sorted { $0.steps > $1.steps }
    }

    var currentUserStanding: Int {
        (leaderboard.firstIndex(where: { $0.name == profile.name }) ?? 0) + 1
    }

    func toggleSignIn() {
        isSignedIn.toggle()
    }
}

private extension AppModel {
    static func makeWeeklySteps() -> [DayStepTotal] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let values = [7_240, 9_120, 8_610, 10_430, 11_240, 6_980, 8_452]

        return values.enumerated().compactMap { offset, steps in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: startOfToday) else {
                return nil
            }

            return DayStepTotal(
                date: date,
                label: labels[offset],
                steps: steps
            )
        }
    }

    static func makeHourlySteps() -> [HourStepTotal] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let values = [
            0, 0, 0, 0, 0, 120, 260, 410, 680, 540, 310, 290,
            610, 780, 460, 430, 710, 890, 640, 520, 360, 240, 120, 82
        ]

        return values.enumerated().compactMap { hour, steps in
            guard let date = calendar.date(byAdding: .hour, value: hour, to: startOfToday) else {
                return nil
            }

            return HourStepTotal(
                date: date,
                hourLabel: hourLabel(for: hour),
                steps: steps
            )
        }
    }

    static func makeMonthlySteps() -> [DayStepTotal] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let values = [
            5_800, 7_100, 8_950, 6_420, 9_200, 10_150, 8_300, 7_840, 9_810, 10_400,
            6_100, 7_300, 8_600, 9_900, 10_200, 11_020, 7_660, 8_140, 9_420, 10_780,
            8_230, 7_910, 9_640, 10_100, 11_300, 6_850, 7_440, 8_880, 9_760, 8_970
        ]

        return values.enumerated().compactMap { offset, steps in
            guard let date = calendar.date(byAdding: .day, value: offset - 29, to: startOfToday) else {
                return nil
            }

            return DayStepTotal(
                date: date,
                label: "\(calendar.component(.day, from: date))",
                steps: steps
            )
        }
    }

    static func makeFriends(currentUserName: String) -> [FriendStanding] {
        [
            FriendStanding(name: "Maya", initials: "MY", steps: 10_120, isCurrentUser: false),
            FriendStanding(name: currentUserName, initials: "AT", steps: 8_452, isCurrentUser: true),
            FriendStanding(name: "Jordan", initials: "JR", steps: 7_980, isCurrentUser: false),
            FriendStanding(name: "Chris", initials: "CH", steps: 6_730, isCurrentUser: false)
        ]
    }

    static func hourLabel(for hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 13...23: return "\(hour - 12)p"
        default: return "\(hour)a"
        }
    }
}
