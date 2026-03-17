//
//  AppModel.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import Combine
import OSLog
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    private let logger = Logger(subsystem: "com.austintran.stepTracker", category: "auth")
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: Self.themeDefaultsKey)
            if usesCustomTheme {
                usesCustomTheme = false
            }
        }
    }
    @Published var usesCustomTheme: Bool {
        didSet {
            UserDefaults.standard.set(usesCustomTheme, forKey: Self.customThemeEnabledKey)
        }
    }
    @Published var isSignedIn = false
    @Published var dailyGoal = 10_000
    @Published var selectedTrendRange: TrendRange = .day
    @Published private(set) var authorizationState: StepAuthorizationState
    @Published private(set) var snapshot: StepSnapshot
    @Published private(set) var trendOffsets: [TrendRange: Int] = [.day: 0, .week: 0, .month: 0]
    @Published private(set) var trendSnapshots: [TrendRange: TrendSnapshot] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var authProviderName: String
    @Published private(set) var isFirebaseConfigured: Bool
    @Published var isShowingAuthFlow = false
    @Published private(set) var authFlowErrorMessage: String?
    @Published private(set) var isAuthSubmitting = false
    private var customTheme: CustomThemeData {
        didSet {
            if let encoded = try? JSONEncoder().encode(customTheme) {
                UserDefaults.standard.set(encoded, forKey: Self.customThemeDataKey)
            }
        }
    }

    let profile = UserProfile(name: "Austin", initials: "AT")

    private let stepDataService: StepDataProviding
    private var authService: AuthProviding?
    private var hasPrepared = false
    private static let themeDefaultsKey = "selectedTheme"
    private static let customThemeEnabledKey = "usesCustomTheme"
    private static let customThemeDataKey = "customThemeData"

    init(stepDataService: StepDataProviding? = nil) {
        let resolvedService = stepDataService ?? HealthKitStepDataService()
        self.stepDataService = resolvedService
        selectedTheme = UserDefaults.standard.string(forKey: Self.themeDefaultsKey).flatMap(AppTheme.init(rawValue:)) ?? .core
        usesCustomTheme = UserDefaults.standard.bool(forKey: Self.customThemeEnabledKey)
        if let data = UserDefaults.standard.data(forKey: Self.customThemeDataKey),
           let decoded = try? JSONDecoder().decode(CustomThemeData.self, from: data) {
            customTheme = decoded
        } else {
            customTheme = .default
        }
        authorizationState = .notDetermined
        snapshot = StepSnapshot.empty
        authProviderName = "Local"
        isFirebaseConfigured = false
        isSignedIn = false
    }

    var accentColor: Color { usesCustomTheme ? customTheme.accentColor : selectedTheme.accent }
    var backgroundColor: Color { usesCustomTheme ? customTheme.backgroundColor : selectedTheme.background }
    var surfaceColor: Color { usesCustomTheme ? customTheme.surfaceColor : selectedTheme.surface }
    var secondarySurfaceColor: Color { usesCustomTheme ? customTheme.secondarySurfaceColor : selectedTheme.secondarySurface }
    var preferredColorScheme: ColorScheme { usesCustomTheme ? (customTheme.isDark ? .dark : .light) : selectedTheme.preferredColorScheme }
    var isDarkTheme: Bool { preferredColorScheme == .dark }
    var themeRefreshKey: String {
        if usesCustomTheme {
            return [
                customTheme.accentHex,
                customTheme.backgroundHex,
                customTheme.surfaceHex,
                customTheme.secondarySurfaceHex,
                customTheme.isDark.description
            ].joined(separator: "|")
        }

        return selectedTheme.rawValue
    }

    var todaySteps: Int {
        snapshot.todaySteps
    }

    var weeklySteps: [DayStepTotal] {
        snapshot.weeklySteps
    }

    var hourlySteps: [HourStepTotal] {
        snapshot.hourlySteps
    }

    var monthlySteps: [DayStepTotal] {
        snapshot.monthlySteps
    }

    var todayProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(Double(todaySteps) / Double(dailyGoal), 1.0)
    }

    var weeklyTotal: Int {
        weeklySteps.reduce(0) { $0 + $1.steps }
    }

    var weeklyAverage: Int {
        weeklyTotal / max(weeklySteps.count, 1)
    }

    var bestHour: HourStepTotal? {
        hourlySteps.max(by: { $0.steps < $1.steps })
    }

    var busiestDay: DayStepTotal? {
        weeklySteps.max(by: { $0.steps < $1.steps })
    }

    var hasStepData: Bool {
        todaySteps > 0 || weeklyTotal > 0 || monthlySteps.contains(where: { $0.steps > 0 })
    }

    var leaderboard: [FriendStanding] {
        snapshot.friends.sorted { $0.steps > $1.steps }
    }

    var currentUserStanding: Int {
        (leaderboard.firstIndex(where: { $0.name == profile.name }) ?? 0) + 1
    }

    var currentTrendOffset: Int {
        trendOffsets[selectedTrendRange, default: 0]
    }

    var currentTrendSnapshot: TrendSnapshot {
        trendSnapshots[selectedTrendRange] ?? TrendSnapshot.empty(range: selectedTrendRange)
    }

    var trendHourlySteps: [HourStepTotal] {
        currentTrendSnapshot.hourlySteps
    }

    var trendDailySteps: [DayStepTotal] {
        currentTrendSnapshot.dailySteps
    }

    var trendTotalSteps: Int {
        currentTrendSnapshot.totalSteps
    }

    var trendAverageSteps: Int {
        switch selectedTrendRange {
        case .day:
            return Int(Double(trendTotalSteps) / 24.0)
        case .week, .month:
            return trendTotalSteps / max(trendDailySteps.count, 1)
        }
    }

    var canMoveTrendForward: Bool {
        currentTrendOffset < 0
    }

    func prepareIfNeeded() async {
        guard !hasPrepared else { return }
        hasPrepared = true
        refreshAuthState()
        authorizationState = await stepDataService.authorizationState()

        if authorizationState == .readyToQuery {
            await refresh()
            await ensureTrendLoaded(for: selectedTrendRange)
        }
    }

    func requestHealthAccess() async {
        isLoading = true
        errorMessage = nil

        do {
            authorizationState = try await stepDataService.requestAuthorization()
            isLoading = false

            if authorizationState == .readyToQuery {
                await refresh()
                await ensureTrendLoaded(for: selectedTrendRange, force: true)
            }
        } catch {
            isLoading = false
            errorMessage = "Couldn’t connect to Health right now."
        }
    }

    func refresh() async {
        guard authorizationState == .readyToQuery else { return }

        isLoading = true
        errorMessage = nil

        do {
            snapshot = try await stepDataService.fetchSnapshot(for: profile)
            authorizationState = await stepDataService.authorizationState()
            if trendOffsets[.day, default: 0] == 0 {
                trendSnapshots[.day] = TrendSnapshot(
                    range: .day,
                    periodStart: Calendar.current.startOfDay(for: .now),
                    periodEnd: .now,
                    totalSteps: snapshot.todaySteps,
                    hourlySteps: snapshot.hourlySteps,
                    dailySteps: []
                )
            }
        } catch {
            errorMessage = "Unable to load your latest steps."
        }

        isLoading = false
    }

    func toggleSignIn() {
        if !isSignedIn {
            presentAuthFlow()
            return
        }
        Task {
            await toggleSignInAsync()
        }
    }

    func presentAuthFlow() {
        authFlowErrorMessage = nil
        isShowingAuthFlow = true
    }

    func dismissAuthFlow() {
        authFlowErrorMessage = nil
        isShowingAuthFlow = false
    }

    func clearAuthFlowError() {
        authFlowErrorMessage = nil
    }

    private func toggleSignInAsync() async {
        errorMessage = nil
        let authService = resolvedAuthService()
        logAuthState(prefix: "Sign-in tapped")

        if isSignedIn {
            do {
                try authService.signOut()
                isSignedIn = false
                logger.info("Sign-out succeeded. provider=\(self.authProviderName, privacy: .public)")
            } catch {
                logger.error("Sign-out failed: \(String(describing: error), privacy: .public)")
                errorMessage = "Couldn’t sign out right now."
            }
            return
        }

        do {
            _ = try await authService.signInForSocialMode()
            isSignedIn = true
            authProviderName = authService.providerName
            isFirebaseConfigured = FirebaseBootstrap.isConfigured
            logger.info("Sign-in succeeded. provider=\(self.authProviderName, privacy: .public) firebaseConfigured=\(self.isFirebaseConfigured)")
        } catch {
            let nsError = error as NSError
            logger.error(
                """
                Sign-in failed. provider=\(authService.providerName, privacy: .public) \
                firebaseConfigured=\(FirebaseBootstrap.isConfigured) \
                hasGoogleServiceInfo=\(FirebaseBootstrap.hasGoogleServiceInfo) \
                errorDomain=\(nsError.domain, privacy: .public) \
                errorCode=\(nsError.code) \
                description=\(error.localizedDescription, privacy: .public)
                """
            )
            errorMessage = "Couldn’t sign in right now. Check Xcode console for the auth error."
        }
    }

    func signInWithEmail(email: String, password: String) async {
        await performCredentialAuth(action: "Email sign-in") { authService in
            try await authService.signIn(email: email, password: password)
        }
    }

    func createAccount(email: String, password: String) async {
        await performCredentialAuth(action: "Email sign-up") { authService in
            try await authService.createAccount(email: email, password: password)
        }
    }

    func signInWithGoogle() {
        authFlowErrorMessage = "Google sign-in still needs the GoogleSignIn SDK and URL scheme wiring."
        logger.error("Google sign-in tapped but GoogleSignIn is not wired in this build.")
    }

    private func performCredentialAuth(
        action: String,
        operation: @escaping (AuthProviding) async throws -> AuthSession
    ) async {
        let authService = resolvedAuthService()
        authFlowErrorMessage = nil
        isAuthSubmitting = true
        logAuthState(prefix: action)

        do {
            _ = try await operation(authService)
            isSignedIn = true
            authProviderName = authService.providerName
            isFirebaseConfigured = FirebaseBootstrap.isConfigured
            isShowingAuthFlow = false
            logger.info("\(action, privacy: .public) succeeded. provider=\(self.authProviderName, privacy: .public)")
        } catch {
            let nsError = error as NSError
            authFlowErrorMessage = error.localizedDescription
            logger.error(
                """
                \(action, privacy: .public) failed. provider=\(authService.providerName, privacy: .public) \
                firebaseConfigured=\(FirebaseBootstrap.isConfigured) \
                hasGoogleServiceInfo=\(FirebaseBootstrap.hasGoogleServiceInfo) \
                errorDomain=\(nsError.domain, privacy: .public) \
                errorCode=\(nsError.code) \
                description=\(error.localizedDescription, privacy: .public)
                """
            )
        }

        isAuthSubmitting = false
    }

    private func resolvedAuthService() -> AuthProviding {
        if let authService {
            if FirebaseBootstrap.isConfigured, authService.providerName == "Local" {
                let upgraded = AuthServiceFactory.make()
                self.authService = upgraded
                return upgraded
            }
            return authService
        }

        let created = AuthServiceFactory.make()
        authService = created
        return created
    }

    private func refreshAuthState() {
        let authService = resolvedAuthService()
        authProviderName = authService.providerName
        isFirebaseConfigured = FirebaseBootstrap.isConfigured
        isSignedIn = authService.currentSession() != nil
        logAuthState(prefix: "Auth state refreshed")
    }

    private func logAuthState(prefix: String) {
        logger.info(
            """
            \(prefix, privacy: .public). \
            provider=\(self.authProviderName, privacy: .public) \
            firebaseSDKAvailable=\(FirebaseBootstrap.isFirebaseSDKAvailable) \
            firebaseConfigured=\(FirebaseBootstrap.isConfigured) \
            hasGoogleServiceInfo=\(FirebaseBootstrap.hasGoogleServiceInfo) \
            isSignedIn=\(self.isSignedIn)
            """
        )
    }

    func applyTheme(_ theme: AppTheme) {
        selectedTheme = theme
    }

    func applyCustomTheme(accent: Color, background: Color, surface: Color, secondarySurface: Color, isDark: Bool) {
        customTheme = CustomThemeData(
            accentHex: accent.hexString,
            backgroundHex: background.hexString,
            surfaceHex: surface.hexString,
            secondarySurfaceHex: secondarySurface.hexString,
            isDark: isDark
        )
        usesCustomTheme = true
    }

    func deleteCustomTheme() {
        customTheme = .default
        usesCustomTheme = false
        UserDefaults.standard.removeObject(forKey: Self.customThemeDataKey)
    }

    var customThemeAccent: Color { customTheme.accentColor }
    var customThemeBackground: Color { customTheme.backgroundColor }
    var customThemeSurface: Color { customTheme.surfaceColor }
    var customThemeSecondarySurface: Color { customTheme.secondarySurfaceColor }
    var customThemeIsDark: Bool { customTheme.isDark }

    func ensureTrendLoaded(for range: TrendRange, force: Bool = false) async {
        guard authorizationState == .readyToQuery else { return }
        if !force, trendSnapshots[range] != nil { return }
        await loadTrend(range: range)
    }

    func moveTrendPeriod(by delta: Int) async {
        let nextOffset = min(currentTrendOffset + delta, 0)
        trendOffsets[selectedTrendRange] = nextOffset
        await loadTrend(range: selectedTrendRange)
    }

    func resetTrendPeriodToCurrent() async {
        trendOffsets[selectedTrendRange] = 0
        await loadTrend(range: selectedTrendRange)
    }

    func setTrendPeriod(containing date: Date) async {
        let calendar = Calendar.current
        let now = Date()
        let offset: Int

        switch selectedTrendRange {
        case .day:
            offset = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: date)).day ?? 0
        case .week:
            let nowWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let targetWeekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            offset = calendar.dateComponents([.weekOfYear], from: nowWeekStart, to: targetWeekStart).weekOfYear ?? 0
        case .month:
            let nowMonthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let targetMonthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
            offset = calendar.dateComponents([.month], from: nowMonthStart, to: targetMonthStart).month ?? 0
        }

        trendOffsets[selectedTrendRange] = min(offset, 0)
        await loadTrend(range: selectedTrendRange)
    }

    func loadTrend(range: TrendRange) async {
        guard authorizationState == .readyToQuery else { return }

        isLoading = true
        errorMessage = nil

        do {
            let offset = trendOffsets[range, default: 0]
            trendSnapshots[range] = try await stepDataService.fetchTrendSnapshot(range: range, offset: offset)
        } catch {
            errorMessage = "Unable to load trend data for this period."
        }

        isLoading = false
    }
}
