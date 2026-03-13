//
//  TrendsView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import Charts
import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var selectedIndex: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if appModel.authorizationState == .readyToQuery {
                    rangePicker
                    detailSection
                    chartSection
                    summarySection
                } else {
                    lockedSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: appModel.selectedTrendRange) { _, _ in
            selectedIndex = nil
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Movement trends")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("Inspect your activity by hour, day, and longer-term patterns.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var rangePicker: some View {
        Picker("Range", selection: $appModel.selectedTrendRange) {
            ForEach(TrendRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detailEyebrow)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            Text(detailTitle)
                .font(.title2.weight(.semibold))

            Text(detailSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            chartView

            Text("Press and drag across the chart to inspect a specific interval.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var chartView: some View {
        Group {
            switch appModel.selectedTrendRange {
            case .day:
                Chart {
                    ForEach(Array(appModel.hourlySteps.enumerated()), id: \.element.id) { index, item in
                        AreaMark(
                            x: .value("Hour", index),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(appModel.accentColor.opacity(selectedIndex == nil ? 0.16 : 0.08))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("Hour", index),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(lineColor(for: index))
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: selectedIndex == index ? 3 : 2))
                    }

                    if let selectedHour, let selectedIndex {
                        RuleMark(x: .value("Selected Hour", selectedIndex))
                            .foregroundStyle(appModel.accentColor.opacity(0.22))
                        PointMark(
                            x: .value("Selected Hour", selectedIndex),
                            y: .value("Steps", selectedHour.steps)
                        )
                        .foregroundStyle(appModel.accentColor)
                        .symbolSize(80)
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
                .chartOverlay { proxy in
                    selectionOverlay(proxy: proxy, itemCount: appModel.hourlySteps.count)
                }

            case .week:
                Chart {
                    ForEach(Array(appModel.weeklySteps.enumerated()), id: \.element.id) { index, item in
                        BarMark(
                            x: .value("Day", index),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(barColor(for: index))
                        .cornerRadius(7)
                    }

                    if selectedDay != nil, let selectedIndex {
                        RuleMark(x: .value("Selected Day", selectedIndex))
                            .foregroundStyle(appModel.accentColor.opacity(0.22))
                    }
                }
                .chartXScale(domain: -0.5...Double(max(appModel.weeklySteps.count - 1, 0)) + 0.5)
                .chartXAxis {
                    AxisMarks(values: Array(appModel.weeklySteps.indices)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), index >= 0, index < appModel.weeklySteps.count {
                                Text(appModel.weeklySteps[index].label)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    selectionOverlay(proxy: proxy, itemCount: appModel.weeklySteps.count)
                }

            case .month:
                Chart {
                    ForEach(Array(appModel.monthlySteps.enumerated()), id: \.element.id) { index, item in
                        LineMark(
                            x: .value("Day", index),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(lineColor(for: index))
                        .interpolationMethod(.catmullRom)

                        if selectedIndex == index {
                            PointMark(
                                x: .value("Day", index),
                                y: .value("Steps", item.steps)
                            )
                            .foregroundStyle(appModel.accentColor)
                            .symbolSize(70)
                        }
                    }

                    if let selectedMonthDay, let selectedIndex {
                        RuleMark(x: .value("Selected Day", selectedIndex))
                            .foregroundStyle(appModel.accentColor.opacity(0.22))
                        PointMark(
                            x: .value("Selected Day", selectedIndex),
                            y: .value("Steps", selectedMonthDay.steps)
                        )
                        .foregroundStyle(appModel.accentColor)
                            .symbolSize(80)
                    }
                }
                .chartXScale(domain: -0.5...Double(max(appModel.monthlySteps.count - 1, 0)) + 0.5)
                .chartXAxis {
                    AxisMarks(values: stride(from: 0, to: appModel.monthlySteps.count, by: 5).map { $0 }) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), index >= 0, index < appModel.monthlySteps.count {
                                Text(appModel.monthlySteps[index].label)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    selectionOverlay(proxy: proxy, itemCount: appModel.monthlySteps.count)
                }
            }
        }
        .frame(height: 280)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Summary")
                .font(.title3.weight(.semibold))

            switch appModel.selectedTrendRange {
            case .day:
                InsightRow(title: "Today total", value: "\(appModel.todaySteps.formatted()) steps")
                InsightRow(title: "Peak hour", value: appModel.bestHour?.hourLabel ?? "--")
                InsightRow(title: "Goal progress", value: "\(Int(appModel.todayProgress * 100))%")
            case .week:
                InsightRow(title: "Weekly total", value: "\(appModel.weeklyTotal.formatted()) steps")
                InsightRow(title: "Average per day", value: "\(appModel.weeklyAverage.formatted())")
                InsightRow(title: "Best day", value: appModel.busiestDay?.label ?? "--")
            case .month:
                let monthAverage = appModel.monthlySteps.map(\.steps).reduce(0, +) / max(appModel.monthlySteps.count, 1)
                let bestMonthDay = appModel.monthlySteps.max(by: { $0.steps < $1.steps })
                InsightRow(title: "30-day average", value: "\(monthAverage.formatted())")
                InsightRow(title: "Top day", value: "\(bestMonthDay?.label ?? "--") • \(bestMonthDay?.steps.formatted() ?? "0")")
                InsightRow(title: "Pattern", value: "Follow consistency over time")
            }
        }
        .padding(.top, 4)
    }

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends need step data")
                .font(.title3.weight(.semibold))
            Text("Connect Health from the Home tab to unlock hourly, weekly, and monthly analysis.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func selectionOverlay(proxy: ChartProxy, itemCount: Int) -> some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(.clear)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard itemCount > 0 else { return }
                            guard let plotFrame = proxy.plotFrame else { return }
                            let frame = geometry[plotFrame]
                            let locationX = value.location.x - frame.origin.x
                            guard locationX >= 0, locationX <= frame.width else { return }

                            let bucketWidth = frame.width / CGFloat(itemCount)
                            let rawIndex = Int((locationX / bucketWidth).rounded(.down))
                            selectedIndex = min(max(rawIndex, 0), itemCount - 1)
                        }
                )
        }
    }

    private var selectedHour: HourStepTotal? {
        guard let selectedIndex, appModel.hourlySteps.indices.contains(selectedIndex) else { return nil }
        return appModel.hourlySteps[selectedIndex]
    }

    private var selectedDay: DayStepTotal? {
        guard let selectedIndex, appModel.weeklySteps.indices.contains(selectedIndex) else { return nil }
        return appModel.weeklySteps[selectedIndex]
    }

    private var selectedMonthDay: DayStepTotal? {
        guard let selectedIndex, appModel.monthlySteps.indices.contains(selectedIndex) else { return nil }
        return appModel.monthlySteps[selectedIndex]
    }

    private var detailEyebrow: String {
        selectedIndex == nil ? "OVERVIEW" : "SELECTED"
    }

    private var detailTitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            if let selectedIndex {
                return "\(hourDisplay(for: selectedIndex)) - \(hourDisplay(for: (selectedIndex + 1) % 24))"
            }
            return "Hourly movement"
        case .week:
            if let selectedDay {
                return formattedWeekday(selectedDay.date)
            }
            return "Weekly pattern"
        case .month:
            if let selectedMonthDay {
                return formattedMonthDay(selectedMonthDay.date)
            }
            return "Monthly pattern"
        }
    }

    private var detailSubtitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            if let selectedHour {
                let percent = appModel.todaySteps > 0 ? Int((Double(selectedHour.steps) / Double(appModel.todaySteps)) * 100) : 0
                return "\(selectedHour.steps.formatted()) steps • \(percent)% of today"
            }
            return "Inspect how your step count changes through the day."
        case .week:
            if let selectedDay {
                let delta = selectedDay.steps - appModel.weeklyAverage
                let prefix = delta >= 0 ? "+" : ""
                return "\(selectedDay.steps.formatted()) steps • \(prefix)\(delta.formatted()) vs average"
            }
            return "Compare each day against your weekly average."
        case .month:
            if let selectedMonthDay, let selectedIndex {
                let previous = selectedIndex > 0 ? appModel.monthlySteps[selectedIndex - 1].steps : nil
                if let previous {
                    let delta = selectedMonthDay.steps - previous
                    let prefix = delta >= 0 ? "+" : ""
                    return "\(selectedMonthDay.steps.formatted()) steps • \(prefix)\(delta.formatted()) vs previous day"
                }
                return "\(selectedMonthDay.steps.formatted()) steps"
            }
            return "Look for consistency and stronger days over the month."
        }
    }

    private func barColor(for index: Int) -> Color {
        if selectedIndex == index {
            return appModel.accentColor
        }
        if selectedIndex != nil {
            return appModel.accentColor.opacity(0.22)
        }
        return appModel.accentColor.opacity(0.82)
    }

    private func lineColor(for index: Int) -> Color {
        if selectedIndex == index {
            return appModel.accentColor
        }
        if selectedIndex != nil {
            return appModel.accentColor.opacity(0.35)
        }
        return appModel.accentColor.opacity(0.88)
    }

    private func formattedWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func formattedMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    private func hourDisplay(for hour: Int) -> String {
        switch hour {
        case 0: return "12 AM"
        case 12: return "12 PM"
        case 13...23: return "\(hour - 12) PM"
        default: return "\(hour) AM"
        }
    }
}

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TrendsView()
                .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
        }
    }
}
