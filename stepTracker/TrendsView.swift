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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if appModel.authorizationState == .readyToQuery {
                    Picker("Range", selection: $appModel.selectedTrendRange) {
                        ForEach(TrendRange.allCases) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    chartCard
                    statsCard
                } else {
                    StepCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trends need step data")
                                .font(.title3.bold())
                            Text("Connect Health from the Home tab to unlock hourly, weekly, and monthly analysis.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .background(backgroundGradient.ignoresSafeArea())
        .navigationTitle("Trends")
    }

    @ViewBuilder
    private var chartCard: some View {
        StepCard {
            VStack(alignment: .leading, spacing: 18) {
                Text(chartTitle)
                    .font(.title3.bold())

                switch appModel.selectedTrendRange {
                case .day:
                    Chart(appModel.hourlySteps) { item in
                        LineMark(
                            x: .value("Hour", item.hourLabel),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(appModel.accentColor)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Hour", item.hourLabel),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(appModel.accentColor.opacity(0.18))
                        .interpolationMethod(.catmullRom)
                    }
                    .chartXAxis {
                        AxisMarks(values: ["12a", "6a", "12p", "6p"]) { value in
                            AxisValueLabel(centered: true)
                        }
                    }
                case .week:
                    Chart(appModel.weeklySteps) { item in
                        BarMark(
                            x: .value("Day", item.label),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(appModel.accentColor.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                case .month:
                    Chart(appModel.monthlySteps) { item in
                        LineMark(
                            x: .value("Day", item.label),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(appModel.accentColor)
                        .interpolationMethod(.catmullRom)
                    }
                }
            }
        }
        .frame(height: 330)
    }

    private var statsCard: some View {
        StepCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Summary")
                    .font(.title3.bold())

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
                    InsightRow(title: "Pattern", value: "See how consistent your movement stays")
                }
            }
        }
    }

    private var chartTitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            return "Steps by hour"
        case .week:
            return "Last 7 days"
        case .month:
            return "Last 30 days"
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [appModel.backgroundTop, appModel.backgroundBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
