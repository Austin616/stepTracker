//
//  PreviewStepDataService.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import Foundation

struct PreviewStepDataService: StepDataProviding {
    var previewAuthorizationState: StepAuthorizationState = .readyToQuery

    func authorizationState() async -> StepAuthorizationState {
        previewAuthorizationState
    }

    func requestAuthorization() async throws -> StepAuthorizationState {
        previewAuthorizationState
    }

    func fetchSnapshot(for profile: UserProfile) async throws -> StepSnapshot {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let weeklyValues = [7_240, 9_120, 8_610, 10_430, 11_240, 6_980, 8_452]
        let hourlyValues = [
            0, 0, 0, 0, 0, 120, 260, 410, 680, 540, 310, 290,
            610, 780, 460, 430, 710, 890, 640, 520, 360, 240, 120, 82
        ]
        let monthlyValues = [
            5_800, 7_100, 8_950, 6_420, 9_200, 10_150, 8_300, 7_840, 9_810, 10_400,
            6_100, 7_300, 8_600, 9_900, 10_200, 11_020, 7_660, 8_140, 9_420, 10_780,
            8_230, 7_910, 9_640, 10_100, 11_300, 6_850, 7_440, 8_880, 9_760, 8_970
        ]

        let weekly = weeklyValues.enumerated().compactMap { index, steps -> DayStepTotal? in
            guard let date = calendar.date(byAdding: .day, value: index - 6, to: startOfToday) else {
                return nil
            }

            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return DayStepTotal(date: date, label: formatter.string(from: date), steps: steps)
        }

        let hourly = hourlyValues.enumerated().compactMap { hour, steps -> HourStepTotal? in
            guard let date = calendar.date(byAdding: .hour, value: hour, to: startOfToday) else {
                return nil
            }

            return HourStepTotal(date: date, hourLabel: hourLabel(for: hour), steps: steps)
        }

        let month = monthlyValues.enumerated().compactMap { offset, steps -> DayStepTotal? in
            guard let date = calendar.date(byAdding: .day, value: offset - 29, to: startOfToday) else {
                return nil
            }

            return DayStepTotal(date: date, label: "\(calendar.component(.day, from: date))", steps: steps)
        }

        let todaySteps = hourly.reduce(0) { $0 + $1.steps }

        return StepSnapshot(
            todaySteps: todaySteps,
            weeklySteps: weekly,
            hourlySteps: hourly,
            monthlySteps: month,
            friends: [
                FriendStanding(name: "Maya", initials: "MY", steps: todaySteps + 1_320, isCurrentUser: false),
                FriendStanding(name: profile.name, initials: profile.initials, steps: todaySteps, isCurrentUser: true),
                FriendStanding(name: "Jordan", initials: "JR", steps: todaySteps - 420, isCurrentUser: false),
                FriendStanding(name: "Chris", initials: "CH", steps: todaySteps - 1_140, isCurrentUser: false)
            ]
        )
    }

    private func hourLabel(for hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 13...23: return "\(hour - 12)p"
        default: return "\(hour)a"
        }
    }
}
