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
                header

                if appModel.authorizationState == .readyToQuery {
                    rangePicker
                    periodNavigation
                    detailSection
                    chartSection
                } else {
                    lockedSection
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(appModel.backgroundColor.ignoresSafeArea())
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.inline)
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
                    .disabled(!appModel.canMoveTrendForward)
                    .opacity(appModel.canMoveTrendForward ? 1 : 0.5)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        pendingDate = appModel.currentTrendSnapshot.periodStart
                        isShowingCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCalendar) {
            trendCalendarSheet
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

    private var periodNavigation: some View {
        HStack {
            Button {
                Task {
                    selectedIndex = nil
                    await appModel.moveTrendPeriod(by: -1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(appModel.secondarySurfaceColor, in: Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text(periodTitle)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                Task {
                    selectedIndex = nil
                    await appModel.moveTrendPeriod(by: 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(appModel.secondarySurfaceColor, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!appModel.canMoveTrendForward)
            .opacity(appModel.canMoveTrendForward ? 1 : 0.35)
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
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding(20)
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
        .presentationDetents([.fraction(0.82), .large])
        .presentationDragIndicator(.visible)
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
                    ForEach(Array(appModel.trendHourlySteps.enumerated()), id: \.element.id) { index, item in
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
                            if selectedIndex == nil {
                                Text("Avg")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                    if let peakHour, let peakHourIndex, selectedIndex == nil {
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
                            if let index = value.as(Int.self), index >= 0, index < appModel.trendHourlySteps.count {
                                Text(appModel.trendHourlySteps[index].hourLabel)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    selectionOverlay(proxy: proxy, itemCount: appModel.trendHourlySteps.count)
                }

            case .week:
                Chart {
                    ForEach(Array(appModel.trendDailySteps.enumerated()), id: \.element.id) { index, item in
                        BarMark(
                            x: .value("Day", index),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(barColor(for: index))
                        .cornerRadius(7)
                    }

                    RuleMark(y: .value("Weekly Average", Double(appModel.trendAverageSteps)))
                        .foregroundStyle(Color.secondary.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            if selectedIndex == nil {
                                Text("Average")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                    if let bestWeekDay, let bestWeekDayIndex, selectedIndex == nil {
                        PointMark(
                            x: .value("Best Day", bestWeekDayIndex),
                            y: .value("Steps", bestWeekDay.steps)
                        )
                        .foregroundStyle(appModel.accentColor)
                        .symbolSize(85)
                        .annotation(position: .top) {
                            chartBadge(title: "Best day", value: bestWeekDay.label)
                        }
                    }

                    if selectedDay != nil, let selectedIndex {
                        RuleMark(x: .value("Selected Day", selectedIndex))
                            .foregroundStyle(appModel.accentColor.opacity(0.22))
                    }
                }
                .chartXScale(domain: -0.5...Double(max(appModel.trendDailySteps.count - 1, 0)) + 0.5)
                .chartXAxis {
                    AxisMarks(values: Array(appModel.trendDailySteps.indices)) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), index >= 0, index < appModel.trendDailySteps.count {
                                Text(appModel.trendDailySteps[index].label)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    selectionOverlay(proxy: proxy, itemCount: appModel.trendDailySteps.count)
                }

            case .month:
                Chart {
                    ForEach(Array(appModel.trendDailySteps.enumerated()), id: \.element.id) { index, item in
                        BarMark(
                            x: .value("Day", index),
                            y: .value("Steps", item.steps)
                        )
                        .foregroundStyle(monthBarColor(for: index))
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Average", Double(appModel.trendAverageSteps)))
                        .foregroundStyle(Color.secondary.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .top, alignment: .leading) {
                            if selectedIndex == nil {
                                Text("Average")
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }

                    if let bestMonthDay, let bestMonthDayIndex, selectedIndex == nil {
                        PointMark(
                            x: .value("Top Day", bestMonthDayIndex),
                            y: .value("Steps", bestMonthDay.steps)
                        )
                        .foregroundStyle(appModel.accentColor)
                        .symbolSize(85)
                        .annotation(position: .top) {
                            chartBadge(title: "Top day", value: bestMonthDay.label)
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
                .chartXScale(domain: -0.5...Double(max(appModel.trendDailySteps.count - 1, 0)) + 0.5)
                .chartXAxis {
                    AxisMarks(values: stride(from: 0, to: appModel.trendDailySteps.count, by: max(appModel.trendDailySteps.count / 6, 1)).map { $0 }) { value in
                        AxisValueLabel {
                            if let index = value.as(Int.self), index >= 0, index < appModel.trendDailySteps.count {
                                Text(appModel.trendDailySteps[index].label)
                            }
                        }
                    }
                }
                .chartOverlay { proxy in
                    selectionOverlay(proxy: proxy, itemCount: appModel.trendDailySteps.count)
                }
            }
        }
        .frame(height: 280)
        .chartYAxis {
            AxisMarks(position: .leading)
        }
    }

    private var lockedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trends need step data")
                .font(.title3.weight(.semibold))
            Text("Connect Health from the Home tab to unlock hourly, weekly, and monthly analysis.")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(appModel.secondarySurfaceColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
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
        case .day: return "TODAY TOTAL"
        case .week: return "THIS WEEK"
        case .month: return "THIS MONTH"
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
                return "\(selectedHour.steps.formatted()) steps • \(percent)% of today"
            }
            return "\(appModel.trendAverageSteps.formatted()) average per hour • Peak hour is highlighted on the chart."
        case .week:
            if let selectedDay {
                let delta = selectedDay.steps - appModel.trendAverageSteps
                let prefix = delta >= 0 ? "+" : ""
                return "\(selectedDay.steps.formatted()) steps • \(prefix)\(delta.formatted()) vs average"
            }
            return "\(appModel.trendAverageSteps.formatted()) average per day • Best day is highlighted on the chart."
        case .month:
            if let selectedMonthDay, let selectedIndex {
                let previous = selectedIndex > 0 ? appModel.trendDailySteps[selectedIndex - 1].steps : nil
                if let previous {
                    let delta = selectedMonthDay.steps - previous
                    let prefix = delta >= 0 ? "+" : ""
                    return "\(selectedMonthDay.steps.formatted()) steps • \(prefix)\(delta.formatted()) vs previous day"
                }
                return "\(selectedMonthDay.steps.formatted()) steps"
            }
            return "\(appModel.trendAverageSteps.formatted()) average per day • Top day is highlighted on the chart."
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
            return appModel.accentColor.opacity(0.68)
        }
        if selectedIndex == index {
            return appModel.accentColor
        }
        if selectedIndex != nil {
            return appModel.accentColor.opacity(0.22)
        }
        return appModel.accentColor.opacity(0.82)
    }

    private func monthBarColor(for index: Int) -> Color {
        if selectedIndex == nil {
            if let bestMonthDayIndex, index == bestMonthDayIndex {
                return appModel.accentColor
            }
            return appModel.accentColor.opacity(0.5)
        }
        if selectedIndex == index {
            return appModel.accentColor
        }
        if selectedIndex != nil {
            return appModel.accentColor.opacity(0.22)
        }
        return appModel.accentColor.opacity(0.82)
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

    private func shortMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
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

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TrendsView()
                .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
        }
    }
}
