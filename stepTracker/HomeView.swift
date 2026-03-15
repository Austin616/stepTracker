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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                if appModel.authorizationState == .readyToQuery {
                    heroSection
                    chartSection
                    socialSection
                } else {
                    permissionSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(SignalBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .refreshable {
            guard appModel.authorizationState == .readyToQuery else { return }
            selectedHourIndex = nil
            await appModel.refresh()
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(todayLabel.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(appModel.accentColor)

            Text(heroCopy)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            GoalRingView(
                progress: appModel.todayProgress,
                steps: appModel.todaySteps,
                goal: appModel.dailyGoal,
                accentColor: appModel.accentColor,
                showsCenterLabel: true,
                centerValue: appModel.todaySteps.formatted(),
                centerSubtitle: "of \(appModel.dailyGoal.formatted()) goal"
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 10)

            goalSummaryRow

            if appModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Refreshing")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var goalSummaryRow: some View {
        HStack(spacing: 18) {
            goalMetric(title: "Complete", value: "\(Int(appModel.todayProgress * 100))%")

            Rectangle()
                .fill(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.06))
                .frame(width: 1, height: 36)

            goalMetric(title: "Left", value: remainingSteps.formatted())

            Spacer()

            Text(statusText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(appModel.accentColor)
        }
        .padding(.top, 2)
    }

    private func goalMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .monospacedDigit()
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedHourTitle)
                    .font(.system(size: 30, weight: .bold))
                    .monospacedDigit()

                Text(selectedHourSubtitle)
                    .font(.system(size: 15, weight: .medium))
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
                .cornerRadius(4)
            }

            RuleMark(y: .value("Average", averageHourlyPace))
                .foregroundStyle(Color.secondary.opacity(0.26))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))

            if let peakHour, let peakHourIndex, selectedHourIndex == nil {
                PointMark(
                    x: .value("Peak Hour", peakHourIndex),
                    y: .value("Steps", peakHour.steps)
                )
                .foregroundStyle(appModel.accentColor)
                .symbolSize(70)
                .annotation(position: .top) {
                    chartBadge(title: "Peak", value: peakHour.steps.formatted())
                }
            }

            if let selectedHour, let selectedHourIndex {
                RuleMark(x: .value("Selected", selectedHourIndex))
                    .foregroundStyle(appModel.accentColor.opacity(0.18))

                PointMark(
                    x: .value("Selected", selectedHourIndex),
                    y: .value("Steps", selectedHour.steps)
                )
                .foregroundStyle(appModel.accentColor)
                .symbolSize(62)
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
        .frame(height: 248)
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.58 : 0.76))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.05), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
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
                                selectedHourIndex = min(max(rawIndex, 0), appModel.hourlySteps.count - 1)
                            }
                            .onEnded { _ in
                                selectedHourIndex = nil
                            }
                    )
            }
        }
    }

    private var socialSection: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(appModel.isSignedIn ? "Friends connected" : "Compare with friends later")
                    .font(.system(size: 16, weight: .semibold))
                Text(appModel.isSignedIn ? "You are #\(appModel.currentUserStanding) today." : "Tracking works fully without an account.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(appModel.isSignedIn ? "Friends" : "Sign in") {
                appModel.toggleSignIn()
            }
            .buttonStyle(.plain)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(appModel.isSignedIn ? Color.primary : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(appModel.isSignedIn ? appModel.surfaceColor.opacity(0.76) : appModel.accentColor)
            )
        }
        .padding(.top, 4)
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("STEP TRACKING")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.1)
                .foregroundStyle(appModel.accentColor)

            Text("Connect Health to start showing your steps in a clean daily view.")
                .font(.system(size: 34, weight: .bold))

            if let errorMessage = appModel.errorMessage {
                Text(errorMessage)
                    .font(.system(size: 15, weight: .medium))
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
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(appModel.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .disabled(appModel.isLoading || appModel.authorizationState == .unavailable)
        }
        .padding(.top, 10)
    }

    private var selectedHour: HourStepTotal? {
        guard let selectedHourIndex, appModel.hourlySteps.indices.contains(selectedHourIndex) else { return nil }
        return appModel.hourlySteps[selectedHourIndex]
    }

    private var selectedHourTitle: String {
        guard let selectedHour, let selectedHourIndex else {
            return "Today by hour"
        }

        return hourRangeLabel(for: selectedHourIndex, fallback: selectedHour.hourLabel)
    }

    private var selectedHourSubtitle: String {
        guard let selectedHour else {
            return "Press and drag across the chart to inspect a specific hour."
        }

        let percent = appModel.todaySteps > 0 ? Int((Double(selectedHour.steps) / Double(appModel.todaySteps)) * 100) : 0
        return "\(selectedHour.steps.formatted()) steps, \(percent)% of today."
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
            return appModel.accentColor.opacity(appModel.isDarkTheme ? 0.62 : 0.74)
        }

        if selectedHourIndex == index {
            return appModel.accentColor
        }

        return appModel.accentColor.opacity(0.18)
    }

    private func chartBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(appModel.accentColor)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(appModel.backgroundColor.opacity(appModel.isDarkTheme ? 0.94 : 0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.05), lineWidth: 1)
                )
        )
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

    private var todayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: .now)
    }

    private var heroCopy: String {
        appModel.hasStepData
            ? "A simple, live readout of your movement."
            : "Start moving and your daily trend will appear here."
    }

    private var remainingSteps: Int {
        max(appModel.dailyGoal - appModel.todaySteps, 0)
    }

    private var statusText: String {
        appModel.todaySteps >= appModel.dailyGoal ? "Goal cleared" : "In progress"
    }

    private var buttonTitle: String {
        switch appModel.authorizationState {
        case .notDetermined: return "Connect Health"
        case .unavailable: return "Unavailable on this device"
        case .readyToQuery: return "Connected"
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
