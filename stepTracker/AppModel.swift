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
    @Published private(set) var authorizationState: StepAuthorizationState
    @Published private(set) var snapshot: StepSnapshot
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    let profile = UserProfile(name: "Austin", initials: "AT")
    let accentColor = Color(red: 0.05, green: 0.69, blue: 0.56)
    let backgroundTop = Color(red: 0.97, green: 0.99, blue: 0.98)
    let backgroundBottom = Color(red: 0.90, green: 0.96, blue: 0.93)

    private let stepDataService: StepDataProviding
    private var hasPrepared = false

    init(stepDataService: StepDataProviding? = nil) {
        let resolvedService = stepDataService ?? HealthKitStepDataService()
        self.stepDataService = resolvedService
        authorizationState = resolvedService.authorizationState
        snapshot = StepSnapshot.empty
    }

    var todaySteps: Int {
        snapshot.todaySteps
    }

    var weeklySteps: [DayStepTotal] {
        snapshot.weeklySteps
    }

    var hourlySteps: [HourStepTotal] {
        snapshot.hourlySteps
    }

    var monthlySteps: [DayStepTotal] {
        snapshot.monthlySteps
    }

    var todayProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(todaySteps) / Double(dailyGoal), 1.0)
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

    var hasStepData: Bool {
        todaySteps > 0 || weeklyTotal > 0 || monthlySteps.contains(where: { $0.steps > 0 })
    }

    var leaderboard: [FriendStanding] {
        snapshot.friends.sorted { $0.steps > $1.steps }
    }

    var currentUserStanding: Int {
        (leaderboard.firstIndex(where: { $0.name == profile.name }) ?? 0) + 1
    }

    func prepareIfNeeded() async {
        guard !hasPrepared else { return }
        hasPrepared = true
        authorizationState = stepDataService.authorizationState

        if authorizationState == .authorized {
            await refresh()
        }
    }

    func requestHealthAccess() async {
        isLoading = true
        errorMessage = nil

        do {
            authorizationState = try await stepDataService.requestAuthorization()
            isLoading = false

            if authorizationState == .authorized {
                await refresh()
            }
        } catch {
            isLoading = false
            errorMessage = "Couldn’t connect to Health right now."
        }
    }

    func refresh() async {
        guard authorizationState == .authorized else { return }

        isLoading = true
        errorMessage = nil

        do {
            snapshot = try await stepDataService.fetchSnapshot(for: profile)
            authorizationState = stepDataService.authorizationState
        } catch {
            errorMessage = "Unable to load your latest steps."
        }

        isLoading = false
    }

    func toggleSignIn() {
        isSignedIn.toggle()
    }
}
