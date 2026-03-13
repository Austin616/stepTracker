//
//  Models.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import Foundation

struct UserProfile {
    let name: String
    let initials: String
}

struct DayStepTotal: Identifiable, Equatable {
    let date: Date
    let label: String
    let steps: Int

    var id: Date { date }
}

struct HourStepTotal: Identifiable, Equatable {
    let date: Date
    let hourLabel: String
    let steps: Int

    var id: Date { date }
}

struct FriendStanding: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let initials: String
    let steps: Int
    let isCurrentUser: Bool
}

struct StepSnapshot: Equatable {
    let todaySteps: Int
    let weeklySteps: [DayStepTotal]
    let hourlySteps: [HourStepTotal]
    let monthlySteps: [DayStepTotal]
    let friends: [FriendStanding]

    static let empty = StepSnapshot(
        todaySteps: 0,
        weeklySteps: [],
        hourlySteps: [],
        monthlySteps: [],
        friends: []
    )
}

enum TrendRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}

enum StepAuthorizationState: Equatable {
    case unavailable
    case notDetermined
    case denied
    case authorized
}
