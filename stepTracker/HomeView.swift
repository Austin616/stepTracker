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
    @State private var selectedHourIndex: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heroHeader

                if appModel.authorizationState == .readyToQuery {
                    ringSection
                    hourlySection
                    socialSection
                } else {
                    permissionSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(appModel.backgroundColor.ignoresSafeArea())
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            guard appModel.authorizationState == .readyToQuery else { return }
            selectedHourIndex = nil
            await appModel.refresh()
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Step Tracker")
                .font(.system(size: 32, weight: .bold, design: .rounded))

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var ringSection: some View {
        VStack(spacing: 18) {
            GoalRingView(
                progress: appModel.todayProgress,
                steps: appModel.todaySteps,
                goal: appModel.dailyGoal,
                accentColor: appModel.accentColor
            )
            .frame(maxWidth: .infinity)

            if appModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Refreshing your latest steps")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today by hour")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text(selectedHourSummaryTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(selectedHourTitle)
                    .font(.headline)
                Text(selectedHourSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            chartView
        }
    }

    private var chartView: some View {
        Chart {
            ForEach(Array(appModel.hourlySteps.enumerated()), id: \.element.id) { index, item in
                BarMark(
                    x: .value("Hour", index),
                    y: .value("Steps", item.steps)
                )
                .foregroundStyle(barColor(for: index))
                .cornerRadius(6)
            }

            RuleMark(y: .value("Average Pace", averageHourlyPace))
                .foregroundStyle(Color.secondary.opacity(0.45))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .annotation(position: .top, alignment: .leading) {
                    if selectedHourIndex == nil {
                        Text("Avg")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

            if let peakHour, let peakHourIndex, selectedHourIndex == nil {
                PointMark(
                    x: .value("Peak Hour", peakHourIndex),
                    y: .value("Steps", peakHour.steps)
                )
                .foregroundStyle(appModel.accentColor)
                .symbolSize(85)
                .annotation(position: .top) {
                    chartBadge(title: "Peak hour", value: "\(peakHour.steps.formatted())")
                }
            }

            if let selectedHour {
                RuleMark(x: .value("Selected Hour", selectedHourIndex ?? 0))
                    .foregroundStyle(appModel.accentColor.opacity(0.22))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                PointMark(
                    x: .value("Selected Hour", selectedHourIndex ?? 0),
                    y: .value("Steps", selectedHour.steps)
                )
                .foregroundStyle(appModel.accentColor)
                .symbolSize(70)
            }
        }
        .chartXScale(domain: -0.5...23.5)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let index = value.as(Int.self), index >= 0, index < appModel.hourlySteps.count {
                        Text(appModel.hourlySteps[index].hourLabel)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 240)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plotFrame = proxy.plotFrame else { return }
                                let frame = geometry[plotFrame]
                                let locationX = value.location.x - frame.origin.x
                                guard locationX >= 0, locationX <= frame.width else { return }

                                let bucketWidth = frame.width / CGFloat(max(appModel.hourlySteps.count, 1))
                                let rawIndex = Int((locationX / bucketWidth).rounded(.down))
                                let clampedIndex = min(max(rawIndex, 0), appModel.hourlySteps.count - 1)
                                selectedHourIndex = clampedIndex
                            }
                            .onEnded { _ in
                                selectedHourIndex = nil
                            }
                    )
            }
        }
    }

    private var socialSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Social")
                .font(.title3.weight(.semibold))

            if appModel.isSignedIn {
                Text("You’re #\(appModel.currentUserStanding) among friends today.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Use the tracker on your own, then sign in when you want to compare with friends.")
                    .foregroundStyle(.secondary)

                Button("Unlock social features") {
                    appModel.toggleSignIn()
                }
                .buttonStyle(.bordered)
                .tint(appModel.accentColor)
            }
        }
        .padding(.top, 8)
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect your step data")
                .font(.title3.weight(.semibold))

            Text("The tracker works without login, but it needs Health access to read your daily, weekly, and hourly steps.")
                .foregroundStyle(.secondary)

            if let errorMessage = appModel.errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }

            Button {
                Task { await appModel.requestHealthAccess() }
            } label: {
                HStack(spacing: 10) {
                    if appModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(buttonTitle)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(appModel.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(appModel.isLoading || appModel.authorizationState == .unavailable)
        }
        .padding(24)
        .background(appModel.secondarySurfaceColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var selectedHour: HourStepTotal? {
        guard let selectedHourIndex else { return nil }
        guard appModel.hourlySteps.indices.contains(selectedHourIndex) else { return nil }
        return appModel.hourlySteps[selectedHourIndex]
    }

    private var selectedHourSummaryTitle: String {
        selectedHour == nil ? "Press and drag" : "Selected interval"
    }

    private var selectedHourTitle: String {
        guard let selectedHour, let selectedHourIndex else {
            return "Your hourly pattern"
        }

        return hourRangeLabel(for: selectedHourIndex, fallback: selectedHour.hourLabel)
    }

    private var selectedHourSubtitle: String {
        guard let selectedHour else {
            return "\(Int(appModel.todayProgress * 100))% of goal • Peak hour is highlighted on the chart."
        }

        let percent = appModel.todaySteps > 0 ? Int((Double(selectedHour.steps) / Double(appModel.todaySteps)) * 100) : 0
        return "\(selectedHour.steps.formatted()) steps • \(percent)% of today"
    }

    private func hourRangeLabel(for index: Int, fallback: String) -> String {
        guard index >= 0, index < 24 else { return fallback }
        let start = hourDisplay(for: index)
        let end = hourDisplay(for: (index + 1) % 24)
        return "\(start) - \(end)"
    }

    private func hourDisplay(for hour: Int) -> String {
        switch hour {
        case 0: return "12 AM"
        case 12: return "12 PM"
        case 13...23: return "\(hour - 12) PM"
        default: return "\(hour) AM"
        }
    }

    private func barColor(for index: Int) -> Color {
        if selectedHourIndex == nil {
            if let peakHourIndex, index == peakHourIndex {
                return appModel.accentColor
            }
            return appModel.accentColor.opacity(0.68)
        }

        if selectedHourIndex == index {
            return appModel.accentColor
        }

        if selectedHourIndex != nil {
            return appModel.accentColor.opacity(0.22)
        }

        return appModel.accentColor.opacity(0.82)
    }

    private var headerSubtitle: String {
        switch appModel.authorizationState {
        case .readyToQuery:
            return appModel.hasStepData ? "A cleaner look at your daily movement." : "Health is connected. Start moving to build today’s trend."
        case .unavailable:
            return "Health data is unavailable in this environment."
        case .notDetermined:
            return "Connect Health to start tracking your steps."
        }
    }

    private var buttonTitle: String {
        switch appModel.authorizationState {
        case .notDetermined: return "Connect Health"
        case .unavailable: return "Unavailable on this device"
        case .readyToQuery: return "Connected"
        }
    }

    private func chartBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(appModel.secondarySurfaceColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var peakHourIndex: Int? {
        guard !appModel.hourlySteps.isEmpty else { return nil }
        return appModel.hourlySteps.enumerated().max(by: { $0.element.steps < $1.element.steps })?.offset
    }

    private var peakHour: HourStepTotal? {
        guard let peakHourIndex, appModel.hourlySteps.indices.contains(peakHourIndex) else { return nil }
        return appModel.hourlySteps[peakHourIndex]
    }

    private var averageHourlyPace: Double {
        Double(appModel.todaySteps) / 24.0
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
