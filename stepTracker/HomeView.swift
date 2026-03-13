//
//  HomeView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import Charts
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroHeader
                statusCard
                if appModel.authorizationState == .authorized {
                    todayCard
                    hourlyCard
                    insightsCard
                    socialCard
                } else {
                    permissionCard
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Step Tracker")
        .toolbar {
            if appModel.authorizationState == .authorized {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await appModel.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(appModel.isLoading)
                }
            }
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Move with intent.")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusCard: some View {
        StepCard {
            HStack(spacing: 12) {
                Circle()
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Image(systemName: statusIcon)
                            .foregroundStyle(statusColor)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headline)
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
    }

    private var permissionCard: some View {
        StepCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Connect your step data")
                    .font(.title3.bold())

                Text("The app works without login, but it still needs Health access to read your daily and hourly steps.")
                    .foregroundStyle(.secondary)

                if let errorMessage = appModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }

                Button {
                    Task { await appModel.requestHealthAccess() }
                } label: {
                    HStack {
                        if appModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(buttonTitle)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(appModel.accentColor)
                .disabled(appModel.isLoading || appModel.authorizationState == .unavailable)
            }
        }
    }

    private var todayCard: some View {
        StepCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("Today")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(appModel.todaySteps.formatted())
                    .font(.system(size: 54, weight: .bold, design: .rounded))

                Text("steps")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)

                Gauge(value: appModel.todayProgress) {
                    EmptyView()
                } currentValueLabel: {
                    Text("\(Int(appModel.todayProgress * 100))%")
                        .font(.headline.bold())
                } minimumValueLabel: {
                    Text("0")
                } maximumValueLabel: {
                    Text("\(appModel.dailyGoal / 1_000)k")
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(appModel.accentColor.gradient)
            }
        }
    }

    private var hourlyCard: some View {
        StepCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today by hour")
                    .font(.title3.bold())

                Chart(appModel.hourlySteps) { item in
                    BarMark(
                        x: .value("Hour", item.hourLabel),
                        y: .value("Steps", item.steps)
                    )
                    .foregroundStyle(appModel.accentColor.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
                .frame(height: 190)
                .chartXAxis {
                    AxisMarks(values: ["12a", "6a", "12p", "6p"]) { value in
                        AxisValueLabel(centered: true)
                    }
                }
            }
        }
    }

    private var insightsCard: some View {
        StepCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Insights")
                    .font(.title3.bold())

                InsightRow(title: "Peak hour", value: "\(appModel.bestHour?.hourLabel ?? "--") • \(appModel.bestHour?.steps.formatted() ?? "0")")
                InsightRow(title: "Weekly average", value: "\(appModel.weeklyAverage.formatted())")
                InsightRow(title: "Most active day", value: "\(appModel.busiestDay?.label ?? "--") • \(appModel.busiestDay?.steps.formatted() ?? "0")")
            }
        }
    }

    private var socialCard: some View {
        StepCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Social")
                    .font(.title3.bold())

                if appModel.isSignedIn {
                    Text("You’re #\(appModel.currentUserStanding) today. Friends comparison stays optional and separate from tracking.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Your steps stay local for now. Sign in later if you want rankings and friend comparisons.")
                        .foregroundStyle(.secondary)

                    Button("Unlock social features") {
                        appModel.toggleSignIn()
                    }
                    .buttonStyle(.bordered)
                    .tint(appModel.accentColor)
                }
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [appModel.backgroundTop, appModel.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var headerSubtitle: String {
        switch appModel.authorizationState {
        case .authorized:
            return appModel.hasStepData ? "Today’s progress and patterns are live from Health." : "Health is connected. Start moving to build your first trends."
        case .unavailable:
            return "This device can’t read Health data here, so the tracker is limited."
        case .denied:
            return "Health access is off. Re-enable it to populate your charts."
        case .notDetermined:
            return "Connect Health to see real steps without creating an account."
        }
    }

    private var statusTitle: String {
        switch appModel.authorizationState {
        case .authorized: return "Health connected"
        case .unavailable: return "Health unavailable"
        case .denied: return "Health access denied"
        case .notDetermined: return "Ready to connect"
        }
    }

    private var statusMessage: String {
        switch appModel.authorizationState {
        case .authorized:
            return appModel.isLoading ? "Refreshing your latest movement." : "Daily, weekly, and monthly charts now use local Health data."
        case .unavailable:
            return "HealthKit is not available in this environment."
        case .denied:
            return "The app can’t read step counts until access is granted again."
        case .notDetermined:
            return "Grant Health access to turn on the tracker."
        }
    }

    private var statusColor: Color {
        switch appModel.authorizationState {
        case .authorized: return appModel.accentColor
        case .unavailable: return .orange
        case .denied: return .red
        case .notDetermined: return .blue
        }
    }

    private var statusIcon: String {
        switch appModel.authorizationState {
        case .authorized: return "heart.text.square.fill"
        case .unavailable: return "exclamationmark.triangle.fill"
        case .denied: return "lock.fill"
        case .notDetermined: return "waveform.path.ecg"
        }
    }

    private var buttonTitle: String {
        switch appModel.authorizationState {
        case .denied: return "Try connecting again"
        case .notDetermined: return "Connect Health"
        case .unavailable: return "Unavailable on this device"
        case .authorized: return "Connected"
        }
    }
}

struct InsightRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
                .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
        }
    }
}
