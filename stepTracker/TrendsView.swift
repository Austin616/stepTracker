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
                Picker("Range", selection: $appModel.selectedTrendRange) {
                    ForEach(TrendRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)

                chartCard
                statsCard
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trends")
    }

    @ViewBuilder
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
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

                    AreaMark(
                        x: .value("Hour", item.hourLabel),
                        y: .value("Steps", item.steps)
                    )
                    .foregroundStyle(appModel.accentColor.opacity(0.15))
                }
            case .week:
                Chart(appModel.weeklySteps) { item in
                    BarMark(
                        x: .value("Day", item.label),
                        y: .value("Steps", item.steps)
                    )
                    .foregroundStyle(appModel.accentColor.gradient)
                }
            case .month:
                Chart(appModel.monthlySteps) { item in
                    LineMark(
                        x: .value("Day", item.label),
                        y: .value("Steps", item.steps)
                    )
                    .foregroundStyle(appModel.accentColor)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .frame(height: 320)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                InsightRow(title: "Consistency", value: "Building toward daily goal")
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var chartTitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            return "Steps by hour"
        case .week:
            return "This week"
        case .month:
            return "Last 30 days"
        }
    }
}

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TrendsView()
                .environmentObject(AppModel())
        }
    }
}
