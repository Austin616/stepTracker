//
//  StepDataService.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import Foundation
import HealthKit

protocol StepDataProviding {
    func authorizationState() async -> StepAuthorizationState
    func requestAuthorization() async throws -> StepAuthorizationState
    func fetchSnapshot(for profile: UserProfile) async throws -> StepSnapshot
}

struct HealthKitStepDataService: StepDataProviding {
    private let healthStore = HKHealthStore()
    private let calendar = Calendar.current

    func authorizationState() async -> StepAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        let requestStatus = await withCheckedContinuation { (continuation: CheckedContinuation<HKAuthorizationRequestStatus, Never>) in
            healthStore.getRequestStatusForAuthorization(toShare: Set<HKSampleType>(), read: [stepType]) { status, _ in
                continuation.resume(returning: status)
            }
        }

        switch requestStatus {
        case .shouldRequest:
            return .notDetermined
        case .unnecessary, .unknown:
            return .readyToQuery
        @unknown default:
            return .readyToQuery
        }
    }

    func requestAuthorization() async throws -> StepAuthorizationState {
        guard HKHealthStore.isHealthDataAvailable() else {
            return .unavailable
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<StepAuthorizationState, Error>) in
            healthStore.requestAuthorization(toShare: Set<HKSampleType>(), read: [stepType]) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    Task {
                        let state = await authorizationState()
                        continuation.resume(returning: state)
                    }
                }
            }
        }
    }

    func fetchSnapshot(for profile: UserProfile) async throws -> StepSnapshot {
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let startOfWeek = calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
        let startOfMonth = calendar.date(byAdding: .day, value: -29, to: startOfToday) ?? startOfToday

        async let hourlyQuery = hourlyStepTotals(start: startOfToday, end: now)
        async let weeklyQuery = dailyStepTotals(start: startOfWeek, end: now)
        async let monthlyQuery = dailyStepTotals(start: startOfMonth, end: now)

        let hourly = try await hourlyQuery
        let weekly = try await weeklyQuery
        let month = try await monthlyQuery
        let todaySteps = hourly.reduce(0) { $0 + $1.steps }

        return StepSnapshot(
            todaySteps: todaySteps,
            weeklySteps: weekly,
            hourlySteps: hourly,
            monthlySteps: month,
            friends: mockFriends(currentUserName: profile.name, currentUserInitials: profile.initials, todaySteps: todaySteps)
        )
    }

    private func hourlyStepTotals(start: Date, end: Date) async throws -> [HourStepTotal] {
        let stats = try await statistics(
            start: start,
            end: end,
            interval: DateComponents(hour: 1),
            anchorDate: start
        )

        return (0..<24).compactMap { hour in
            guard let bucketDate = calendar.date(byAdding: .hour, value: hour, to: start) else {
                return nil
            }

            let steps = value(at: bucketDate, from: stats)
            return HourStepTotal(
                date: bucketDate,
                hourLabel: Self.hourLabel(for: hour),
                steps: steps
            )
        }
    }

    private func dailyStepTotals(start: Date, end: Date) async throws -> [DayStepTotal] {
        let startOfRange = calendar.startOfDay(for: start)
        let endOfRange = calendar.startOfDay(for: end)
        let stats = try await statistics(
            start: startOfRange,
            end: end,
            interval: DateComponents(day: 1),
            anchorDate: startOfRange
        )

        let daySpan = calendar.dateComponents([.day], from: startOfRange, to: endOfRange).day ?? 0

        return (0...daySpan).compactMap { offset in
            guard let bucketDate = calendar.date(byAdding: .day, value: offset, to: startOfRange) else {
                return nil
            }

            return DayStepTotal(
                date: bucketDate,
                label: Self.dayLabel(for: bucketDate, calendar: calendar, shortWeekday: daySpan <= 6),
                steps: value(at: bucketDate, from: stats)
            )
        }
    }

    private func statistics(
        start: Date,
        end: Date,
        interval: DateComponents,
        anchorDate: Date
    ) async throws -> HKStatisticsCollection {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results else {
                    continuation.resume(throwing: StepDataError.missingResults)
                    return
                }

                continuation.resume(returning: results)
            }

            healthStore.execute(query)
        }
    }

    private func value(at date: Date, from stats: HKStatisticsCollection) -> Int {
        let quantity = stats.statistics(for: date)?.sumQuantity()
        return Int(quantity?.doubleValue(for: HKUnit.count()) ?? 0)
    }

    private func mockFriends(currentUserName: String, currentUserInitials: String, todaySteps: Int) -> [FriendStanding] {
        [
            FriendStanding(name: "Maya", initials: "MY", steps: max(todaySteps + 1_320, 4_200), isCurrentUser: false),
            FriendStanding(name: currentUserName, initials: currentUserInitials, steps: todaySteps, isCurrentUser: true),
            FriendStanding(name: "Jordan", initials: "JR", steps: max(todaySteps - 420, 3_600), isCurrentUser: false),
            FriendStanding(name: "Chris", initials: "CH", steps: max(todaySteps - 1_140, 2_900), isCurrentUser: false)
        ]
    }

    private static func hourLabel(for hour: Int) -> String {
        switch hour {
        case 0: return "12a"
        case 12: return "12p"
        case 13...23: return "\(hour - 12)p"
        default: return "\(hour)a"
        }
    }

    private static func dayLabel(for date: Date, calendar: Calendar, shortWeekday: Bool) -> String {
        if shortWeekday {
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        }

        return "\(calendar.component(.day, from: date))"
    }

    private var stepType: HKQuantityType {
        HKQuantityType.quantityType(forIdentifier: .stepCount)!
    }
}

enum StepDataError: Error {
    case missingResults
}
