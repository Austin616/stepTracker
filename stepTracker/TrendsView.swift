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
    @State private var isShowingCalendar = false
    @State private var pendingDate = Date()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SignalHeader(
                    eyebrow: "ANALYTICS",
                    title: "Movement trends",
                    subtitle: "Navigate across time and inspect your movement like a signal."
                )

                if appModel.authorizationState == .readyToQuery {
                    rangeStrip
                    periodStrip
                    detailSection
                    chartSection
                } else {
                    lockedPanel
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(SignalBackground())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task(id: appModel.selectedTrendRange) {
            await appModel.ensureTrendLoaded(for: appModel.selectedTrendRange)
            pendingDate = appModel.currentTrendSnapshot.periodStart
        }
        .onChange(of: appModel.selectedTrendRange) { _, _ in
            selectedIndex = nil
            pendingDate = appModel.currentTrendSnapshot.periodStart
        }
        .toolbar {
            if appModel.authorizationState == .readyToQuery {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") {
                        Task {
                            selectedIndex = nil
                            await appModel.resetTrendPeriodToCurrent()
                            pendingDate = appModel.currentTrendSnapshot.periodStart
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(appModel.secondarySurfaceColor.opacity(appModel.isDarkTheme ? 0.78 : 0.84))
                    )
                    .disabled(!appModel.canMoveTrendForward)
                    .opacity(appModel.canMoveTrendForward ? 1 : 0.45)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        pendingDate = appModel.currentTrendSnapshot.periodStart
                        isShowingCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                            .font(.system(size: 15, weight: .semibold, design: .default))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(appModel.secondarySurfaceColor.opacity(appModel.isDarkTheme ? 0.78 : 0.84))
                            )
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCalendar) {
            trendCalendarSheet
        }
    }

    private var rangeStrip: some View {
        HStack(spacing: 8) {
            ForEach(TrendRange.allCases) { range in
                Button {
                    appModel.selectedTrendRange = range
                } label: {
                    SignalChip(title: range.rawValue, isSelected: appModel.selectedTrendRange == range)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var periodStrip: some View {
        HStack {
            navButton(systemName: "chevron.left") {
                Task {
                    selectedIndex = nil
                    await appModel.moveTrendPeriod(by: -1)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Text("PERIOD")
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .tracking(1.8)
                    .foregroundStyle(appModel.accentColor)
                Text(periodTitle)
                    .font(.system(size: 19, weight: .bold, design: .default))
                    .monospacedDigit()
            }

            Spacer()

            navButton(systemName: "chevron.right", disabled: !appModel.canMoveTrendForward) {
                Task {
                    selectedIndex = nil
                    await appModel.moveTrendPeriod(by: 1)
                }
            }
        }
    }

    private func navButton(systemName: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold, design: .default))
                .frame(width: 42, height: 42)
                .background(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.92 : 0.98), in: Circle())
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.05), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
    }

    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(detailEyebrow)
                .font(.system(size: 11, weight: .semibold, design: .default))
                .tracking(2.0)
                .foregroundStyle(appModel.accentColor)

            Text(detailTitle)
                .font(.system(size: 42, weight: .bold, design: .default))
                .monospacedDigit()

            Text(detailSubtitle)
                .font(.system(size: 15, weight: .medium, design: .default))
                .foregroundStyle(.secondary)
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            chartView

            Text("Press and drag to inspect each interval.")
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var chartView: some View {
        Group {
            switch appModel.selectedTrendRange {
            case .day:
                hourlyChart
            case .week:
                dailyChart(values: appModel.trendDailySteps, average: Double(appModel.trendAverageSteps), badgeTitle: "Best day", badgeValue: bestWeekDay?.label ?? "--", bestIndex: bestWeekDayIndex)
            case .month:
                dailyChart(values: appModel.trendDailySteps, average: Double(appModel.trendAverageSteps), badgeTitle: "Top day", badgeValue: bestMonthDay?.label ?? "--", bestIndex: bestMonthDayIndex, narrow: true)
            }
        }
    }

    private var hourlyChart: some View {
        Chart {
            ForEach(Array(appModel.trendHourlySteps.enumerated()), id: \.element.id) { index, item in
                BarMark(
                    x: .value("Hour", index),
                    y: .value("Steps", item.steps)
                )
                .foregroundStyle(barColor(for: index))
                .cornerRadius(5)
            }

            RuleMark(y: .value("Average Pace", averageHourlyPace))
                .foregroundStyle(Color.secondary.opacity(0.35))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

            if let peakHour, let peakHourIndex, selectedIndex == nil {
                PointMark(
                    x: .value("Peak Hour", peakHourIndex),
                    y: .value("Steps", peakHour.steps)
                )
                .foregroundStyle(appModel.accentColor)
                .symbolSize(88)
                .annotation(position: .top) {
                    chartBadge(title: "Peak hour", value: peakHour.steps.formatted())
                }
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
        .modifier(CommonChartModifier())
        .chartXScale(domain: -0.5...23.5)
        .chartXAxis {
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisValueLabel {
                    if let index = value.as(Int.self), index >= 0, index < appModel.trendHourlySteps.count {
                        Text(appModel.trendHourlySteps[index].hourLabel)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            selectionOverlay(proxy: proxy, itemCount: appModel.trendHourlySteps.count)
        }
    }

    private func dailyChart(values: [DayStepTotal], average: Double, badgeTitle: String, badgeValue: String, bestIndex: Int?, narrow: Bool = false) -> some View {
        let barWidth: CGFloat = narrow ? 7 : 14
        let cornerRadius: CGFloat = narrow ? 4 : 7
        let barOpacity = narrow ? 0.95 : 1.0

        return Chart {
            dailyBarMarks(values: values, narrow: narrow, cornerRadius: cornerRadius, barOpacity: barOpacity, barWidth: barWidth)
            averageRuleMark(value: average)
            bestDayMarker(values: values, bestIndex: bestIndex, badgeTitle: badgeTitle, badgeValue: badgeValue)
            selectedDayMarker(values: values)
        }
        .modifier(CommonChartModifier())
        .chartXScale(domain: -0.5...Double(max(values.count - 1, 0)) + 0.5)
        .chartXAxis {
            AxisMarks(values: tickValues(for: values.count)) { value in
                AxisValueLabel {
                    if let index = value.as(Int.self), index >= 0, index < values.count {
                        Text(values[index].label)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            selectionOverlay(proxy: proxy, itemCount: values.count)
        }
    }

    private func dailyBarColor(for index: Int, narrow: Bool) -> Color {
        narrow ? monthBarColor(for: index) : barColor(for: index)
    }

    @ChartContentBuilder
    private func dailyBarMarks(values: [DayStepTotal], narrow: Bool, cornerRadius: CGFloat, barOpacity: Double, barWidth: CGFloat) -> some ChartContent {
        ForEach(Array(values.enumerated()), id: \.element.id) { index, item in
            BarMark(
                x: .value("Bucket", index),
                y: .value("Steps", item.steps)
            )
            .foregroundStyle(dailyBarColor(for: index, narrow: narrow))
            .cornerRadius(cornerRadius)
            .opacity(barOpacity)
        }
    }

    @ChartContentBuilder
    private func averageRuleMark(value: Double) -> some ChartContent {
        RuleMark(y: .value("Average", value))
            .foregroundStyle(Color.secondary.opacity(0.35))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
    }

    @ChartContentBuilder
    private func bestDayMarker(values: [DayStepTotal], bestIndex: Int?, badgeTitle: String, badgeValue: String) -> some ChartContent {
        if let bestIndex, selectedIndex == nil, let bestValue = values[safe: bestIndex] {
            PointMark(
                x: .value("Best", bestIndex),
                y: .value("Steps", bestValue.steps)
            )
            .foregroundStyle(appModel.accentColor)
            .symbolSize(88)
            .annotation(position: .top) {
                chartBadge(title: badgeTitle, value: badgeValue)
            }
        }
    }

    @ChartContentBuilder
    private func selectedDayMarker(values: [DayStepTotal]) -> some ChartContent {
        if let selectedIndex, let selectedValue = values[safe: selectedIndex] {
            RuleMark(x: .value("Selected", selectedIndex))
                .foregroundStyle(appModel.accentColor.opacity(0.22))

            PointMark(
                x: .value("Selected", selectedIndex),
                y: .value("Steps", selectedValue.steps)
            )
            .foregroundStyle(appModel.accentColor)
            .symbolSize(80)
        }
    }

    private var lockedPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONNECT HEALTH")
                .font(.system(size: 11, weight: .semibold, design: .default))
                .tracking(2.0)
                .foregroundStyle(appModel.accentColor)
            Text("Trend views need Health data before analytics can be generated.")
                .font(.system(size: 28, weight: .bold, design: .default))
            Text("Once connected, you can move across days, weeks, and months from here.")
                .foregroundStyle(.secondary)
        }
    }

    private var trendCalendarSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                DatePicker(
                    calendarTitle,
                    selection: $pendingDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .labelsHidden()

                Text(calendarSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Jump to Today") {
                    pendingDate = Date()
                    isShowingCalendar = false
                    Task {
                        selectedIndex = nil
                        await appModel.resetTrendPeriodToCurrent()
                        pendingDate = appModel.currentTrendSnapshot.periodStart
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(appModel.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(20)
            .background(SignalBackground())
            .navigationTitle(calendarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isShowingCalendar = false
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Go") {
                        isShowingCalendar = false
                        Task {
                            selectedIndex = nil
                            await appModel.setTrendPeriod(containing: pendingDate)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(appModel.preferredColorScheme)
        .presentationDetents([.fraction(0.82), .large])
        .presentationDragIndicator(.visible)
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
                        .onEnded { _ in
                            selectedIndex = nil
                        }
                )
        }
    }

    private var selectedHour: HourStepTotal? {
        guard let selectedIndex, appModel.trendHourlySteps.indices.contains(selectedIndex) else { return nil }
        return appModel.trendHourlySteps[selectedIndex]
    }

    private var selectedDay: DayStepTotal? {
        guard let selectedIndex, appModel.trendDailySteps.indices.contains(selectedIndex) else { return nil }
        return appModel.trendDailySteps[selectedIndex]
    }

    private var selectedMonthDay: DayStepTotal? {
        guard let selectedIndex, appModel.trendDailySteps.indices.contains(selectedIndex) else { return nil }
        return appModel.trendDailySteps[selectedIndex]
    }

    private var detailEyebrow: String {
        if selectedIndex != nil {
            return "SELECTED"
        }
        switch appModel.selectedTrendRange {
        case .day: return "DAY VIEW"
        case .week: return "WEEK VIEW"
        case .month: return "MONTH VIEW"
        }
    }

    private var detailTitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            if let selectedIndex {
                return "\(hourDisplay(for: selectedIndex)) - \(hourDisplay(for: (selectedIndex + 1) % 24))"
            }
            return "\(appModel.currentTrendSnapshot.totalSteps.formatted()) steps"
        case .week:
            if let selectedDay {
                return formattedWeekday(selectedDay.date)
            }
            return "\(appModel.currentTrendSnapshot.totalSteps.formatted()) steps"
        case .month:
            if let selectedMonthDay {
                return formattedMonthDay(selectedMonthDay.date)
            }
            return "\(appModel.currentTrendSnapshot.totalSteps.formatted()) steps"
        }
    }

    private var detailSubtitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            if let selectedHour {
                let percent = appModel.currentTrendSnapshot.totalSteps > 0 ? Int((Double(selectedHour.steps) / Double(appModel.currentTrendSnapshot.totalSteps)) * 100) : 0
                return "\(selectedHour.steps.formatted()) steps. \(percent)% of this day."
            }
            return "\(appModel.trendAverageSteps.formatted()) average per hour. Peak hour is highlighted."
        case .week:
            if let selectedDay {
                let delta = selectedDay.steps - appModel.trendAverageSteps
                let prefix = delta >= 0 ? "+" : ""
                return "\(selectedDay.steps.formatted()) steps. \(prefix)\(delta.formatted()) vs weekly average."
            }
            return "\(appModel.trendAverageSteps.formatted()) average per day. Best day is highlighted."
        case .month:
            if let selectedMonthDay, let selectedIndex {
                let previous = selectedIndex > 0 ? appModel.trendDailySteps[selectedIndex - 1].steps : nil
                if let previous {
                    let delta = selectedMonthDay.steps - previous
                    let prefix = delta >= 0 ? "+" : ""
                    return "\(selectedMonthDay.steps.formatted()) steps. \(prefix)\(delta.formatted()) vs previous day."
                }
                return "\(selectedMonthDay.steps.formatted()) steps."
            }
            return "\(appModel.trendAverageSteps.formatted()) average per day. Top day is highlighted."
        }
    }

    private func barColor(for index: Int) -> Color {
        if selectedIndex == nil {
            switch appModel.selectedTrendRange {
            case .day:
                if let peakHourIndex, index == peakHourIndex {
                    return appModel.accentColor
                }
            case .week:
                if let bestWeekDayIndex, index == bestWeekDayIndex {
                    return appModel.accentColor
                }
            case .month:
                break
            }
            return appModel.accentColor.opacity(appModel.isDarkTheme ? 0.62 : 0.76)
        }
        if selectedIndex == index {
            return appModel.accentColor
        }
        return appModel.accentColor.opacity(0.20)
    }

    private func monthBarColor(for index: Int) -> Color {
        if selectedIndex == nil {
            if let bestMonthDayIndex, index == bestMonthDayIndex {
                return appModel.accentColor
            }
            return appModel.accentColor.opacity(appModel.isDarkTheme ? 0.44 : 0.58)
        }
        if selectedIndex == index {
            return appModel.accentColor
        }
        return appModel.accentColor.opacity(0.20)
    }

    private func chartBadge(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundStyle(appModel.accentColor)
                .tracking(1.4)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .default))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.95 : 0.98))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.05), lineWidth: 1)
                )
        )
    }

    private func tickValues(for count: Int) -> [Int] {
        let step = max(count / 6, 1)
        return stride(from: 0, to: count, by: step).map { $0 }
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

    private func shortMonthDay(_ date: Date) -> String {
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

    private var peakHourIndex: Int? {
        guard !appModel.trendHourlySteps.isEmpty else { return nil }
        return appModel.trendHourlySteps.enumerated().max(by: { $0.element.steps < $1.element.steps })?.offset
    }

    private var peakHour: HourStepTotal? {
        guard let peakHourIndex, appModel.trendHourlySteps.indices.contains(peakHourIndex) else { return nil }
        return appModel.trendHourlySteps[peakHourIndex]
    }

    private var bestWeekDayIndex: Int? {
        guard !appModel.trendDailySteps.isEmpty else { return nil }
        return appModel.trendDailySteps.enumerated().max(by: { $0.element.steps < $1.element.steps })?.offset
    }

    private var bestWeekDay: DayStepTotal? {
        guard let bestWeekDayIndex, appModel.trendDailySteps.indices.contains(bestWeekDayIndex) else { return nil }
        return appModel.trendDailySteps[bestWeekDayIndex]
    }

    private var bestMonthDayIndex: Int? {
        guard !appModel.trendDailySteps.isEmpty else { return nil }
        return appModel.trendDailySteps.enumerated().max(by: { $0.element.steps < $1.element.steps })?.offset
    }

    private var bestMonthDay: DayStepTotal? {
        guard let bestMonthDayIndex, appModel.trendDailySteps.indices.contains(bestMonthDayIndex) else { return nil }
        return appModel.trendDailySteps[bestMonthDayIndex]
    }

    private var averageHourlyPace: Double {
        Double(appModel.currentTrendSnapshot.totalSteps) / 24.0
    }

    private var periodTitle: String {
        let snapshot = appModel.currentTrendSnapshot
        switch appModel.selectedTrendRange {
        case .day:
            return formattedMonthDay(snapshot.periodStart)
        case .week:
            return "\(shortMonthDay(snapshot.periodStart)) - \(shortMonthDay(snapshot.periodEnd))"
        case .month:
            let formatter = DateFormatter()
            formatter.dateFormat = "LLLL yyyy"
            return formatter.string(from: snapshot.periodStart)
        }
    }

    private var calendarTitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            return "Choose Day"
        case .week:
            return "Choose Week"
        case .month:
            return "Choose Month"
        }
    }

    private var calendarSubtitle: String {
        switch appModel.selectedTrendRange {
        case .day:
            return "Pick a date to jump to that day."
        case .week:
            return "Pick any date inside the week you want to inspect."
        case .month:
            return "Pick any date inside the month you want to inspect."
        }
    }
}

private struct CommonChartModifier: ViewModifier {
    @EnvironmentObject private var appModel: AppModel

    func body(content: Content) -> some View {
        content
            .frame(height: 280)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(appModel.secondarySurfaceColor.opacity(appModel.isDarkTheme ? 0.42 : 0.60))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.05), lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
