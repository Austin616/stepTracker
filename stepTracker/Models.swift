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

struct DayStepTotal: Identifiable {
    let date: Date
    let label: String
    let steps: Int

    var id: Date { date }
}

struct HourStepTotal: Identifiable {
    let date: Date
    let hourLabel: String
    let steps: Int

    var id: Date { date }
}

struct FriendStanding: Identifiable {
    let id = UUID()
    let name: String
    let initials: String
    let steps: Int
    let isCurrentUser: Bool
}

enum TrendRange: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
}
