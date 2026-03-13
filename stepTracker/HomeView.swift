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
                header
                todayCard
                hourlyCard
                insightsCard
                socialCard
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Step Tracker")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Today")
                .font(.title.bold())
            Text("Track your movement now, add friends later.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(appModel.todaySteps.formatted())")
                .font(.system(size: 44, weight: .bold, design: .rounded))

            Text("steps so far")
                .font(.headline)
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

            Text("Goal: \(appModel.dailyGoal.formatted()) steps")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var hourlyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hourly breakdown")
                .font(.title3.bold())

            Chart(appModel.hourlySteps) { item in
                BarMark(
                    x: .value("Hour", item.hourLabel),
                    y: .value("Steps", item.steps)
                )
                .foregroundStyle(appModel.accentColor.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .frame(height: 180)
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    AxisValueLabel()
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick insights")
                .font(.title3.bold())

            InsightRow(title: "Best hour", value: "\(appModel.bestHour?.hourLabel ?? "--") • \(appModel.bestHour?.steps.formatted() ?? "0") steps")
            InsightRow(title: "Weekly average", value: "\(appModel.weeklyAverage.formatted()) steps")
            InsightRow(title: "Most active day", value: "\(appModel.busiestDay?.label ?? "--") • \(appModel.busiestDay?.steps.formatted() ?? "0")")
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var socialCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Friends")
                .font(.title3.bold())

            if appModel.isSignedIn {
                Text("You’re currently #\(appModel.currentUserStanding) among friends today.")
                    .foregroundStyle(.secondary)

                Text("Open the Friends tab to compare rankings and streaks.")
                    .foregroundStyle(.secondary)
            } else {
                Text("Use the tracker without an account. Sign in later to compare steps with friends.")
                    .foregroundStyle(.secondary)

                Button("Unlock social features") {
                    appModel.toggleSignIn()
                }
                .buttonStyle(.borderedProminent)
                .tint(appModel.accentColor)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
                .environmentObject(AppModel())
        }
    }
}
