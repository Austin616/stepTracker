//
//  GoalRingView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

struct GoalRingView: View {
    @EnvironmentObject private var appModel: AppModel
    let progress: Double
    let steps: Int
    let goal: Int
    let accentColor: Color
    var showsCenterLabel = true
    var centerValue: String?
    var centerSubtitle: String?

    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(appModel.isDarkTheme ? 0.12 : 0.08), style: StrokeStyle(lineWidth: 22, lineCap: .round))

            Circle()
                .trim(from: 0, to: max(0.02, min(progress, 1.0)))
                .stroke(
                    AngularGradient(
                        colors: [
                            accentColor.opacity(0.65),
                            accentColor,
                            accentColor.opacity(0.8)
                        ],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 22, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.04), lineWidth: 1)
                .padding(18)

            if showsCenterLabel {
                VStack(spacing: 6) {
                    Text(centerValue ?? steps.formatted())
                        .font(.system(size: 46, weight: .bold, design: .default))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(centerSubtitle ?? "of \(goal.formatted()) goal")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 250, height: 250)
        .background(
            Circle()
                .fill(accentColor.opacity(appModel.isDarkTheme ? 0.12 : 0.05))
                .blur(radius: 32)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.86), value: progress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily step goal")
        .accessibilityValue("\(steps) of \(goal) steps")
    }
}

struct GoalRingView_Previews: PreviewProvider {
    static var previews: some View {
        GoalRingView(progress: 0.72, steps: 7_200, goal: 10_000, accentColor: .green)
            .padding()
            .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
    }
}
