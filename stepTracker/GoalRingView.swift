//
//  GoalRingView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

struct GoalRingView: View {
    let progress: Double
    let steps: Int
    let goal: Int
    let accentColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.12), lineWidth: 24)

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
                    style: StrokeStyle(lineWidth: 24, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text(steps.formatted())
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text("of \(goal.formatted()) goal")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 250, height: 250)
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
    }
}
