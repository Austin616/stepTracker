//
//  SignalUI.swift
//  stepTracker
//
//  Created by Austin Tran on 3/14/26.
//

import SwiftUI

struct SignalBackground: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ZStack {
            appModel.backgroundColor

            LinearGradient(
                colors: [
                    appModel.accentColor.opacity(appModel.isDarkTheme ? 0.16 : 0.05),
                    .clear,
                    Color.white.opacity(appModel.isDarkTheme ? 0.01 : 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            SignalGridOverlay()
                .blendMode(appModel.isDarkTheme ? .screen : .multiply)
                .opacity(appModel.isDarkTheme ? 0.12 : 0.05)
        }
        .ignoresSafeArea()
    }
}

struct SignalPanel<Content: View>: View {
    @EnvironmentObject private var appModel: AppModel
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.58 : 0.72))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(panelStroke, lineWidth: 0.8)
                    )
                    .shadow(color: shadowColor, radius: 16, x: 0, y: 10)
            )
    }

    private var panelStroke: Color {
        appModel.isDarkTheme
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.05)
    }

    private var shadowColor: Color {
        appModel.isDarkTheme
            ? Color.black.opacity(0.20)
            : appModel.accentColor.opacity(0.04)
    }
}

struct SignalHeader: View {
    @EnvironmentObject private var appModel: AppModel
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .tracking(2.4)
                    .foregroundStyle(appModel.accentColor)

                Rectangle()
                    .fill(appModel.accentColor.opacity(0.4))
                    .frame(width: 32, height: 1)
            }

            Text(title)
                .font(.system(size: 36, weight: .bold, design: .default))

            Text(subtitle)
                .font(.system(size: 16, weight: .medium, design: .default))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SignalChip: View {
    @EnvironmentObject private var appModel: AppModel
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold, design: .default))
            .foregroundStyle(isSelected ? chipForeground : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? appModel.accentColor.opacity(appModel.isDarkTheme ? 0.22 : 0.14) : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isSelected ? appModel.accentColor.opacity(0.55) : Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.06), lineWidth: 1)
                    )
            )
    }

    private var chipForeground: Color {
        appModel.isDarkTheme ? .white : Color.primary
    }
}

struct SignalMetric: View {
    enum Layout {
        case leading
        case trailing
    }

    let label: String
    let value: String
    let layout: Layout

    init(label: String, value: String, alignment: Layout = .leading) {
        self.label = label
        self.value = value
        layout = alignment
    }

    var body: some View {
        VStack(alignment: layout == .trailing ? .trailing : .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .tracking(1.8)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .default))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: layout == .trailing ? .trailing : .leading)
    }
}

struct SignalRuleDivider: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.06))
            .frame(height: 1)
    }
}

struct SignalInsetRail<Content: View>: View {
    @EnvironmentObject private var appModel: AppModel
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(appModel.secondarySurfaceColor.opacity(appModel.isDarkTheme ? 0.46 : 0.66))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.06 : 0.04), lineWidth: 0.8)
                    )
            )
    }
}

private struct SignalGridOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let spacing: CGFloat = 28
                var horizontal = Path()
                var vertical = Path()

                for y in stride(from: CGFloat.zero, through: size.height, by: spacing) {
                    horizontal.move(to: CGPoint(x: 0, y: y))
                    horizontal.addLine(to: CGPoint(x: size.width, y: y))
                }

                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    vertical.move(to: CGPoint(x: x, y: 0))
                    vertical.addLine(to: CGPoint(x: x, y: size.height))
                }

                context.stroke(horizontal, with: .color(.white.opacity(0.12)), lineWidth: 0.5)
                context.stroke(vertical, with: .color(.white.opacity(0.06)), lineWidth: 0.5)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
}
