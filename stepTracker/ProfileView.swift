//
//  ProfileView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var customAccent = Color.teal
    @State private var customBackground = Color.black
    @State private var customSurface = Color(.darkGray)
    @State private var customSecondarySurface = Color.gray
    @State private var customIsDark = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header
                identitySection
                trackerSection
                themeSection
                customThemeSection
                accountSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 36)
        }
        .background(appModel.backgroundColor.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            syncCustomThemeDraft()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profile")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("Your tracker settings and local account state.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var identitySection: some View {
        StepCard {
            HStack(spacing: 16) {
                Circle()
                    .fill(appModel.accentColor)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(appModel.profile.initials)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(appModel.profile.name)
                        .font(.title3.weight(.semibold))
                    Text(appModel.isSignedIn ? "Signed in for social features" : "Guest mode")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var trackerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tracker")
                .font(.title3.weight(.semibold))

            profileRow(title: "Daily goal", value: "\(appModel.dailyGoal.formatted()) steps")
            profileRow(title: "Health status", value: profileHealthStatus)
            profileRow(title: "Tracker mode", value: "Local-first")
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account")
                .font(.title3.weight(.semibold))

            Button(appModel.isSignedIn ? "Sign out" : "Sign in later") {
                appModel.toggleSignIn()
            }
            .buttonStyle(.bordered)
            .tint(appModel.accentColor)
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Theme")
                .font(.title3.weight(.semibold))

            Text("Choose a preset theme or build your own below.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            themeGroup(title: "Light", themes: AppTheme.allCases.filter { !$0.isDark })
            themeGroup(title: "Dark", themes: AppTheme.allCases.filter(\.isDark))
        }
    }

    private func themeGroup(title: String, themes: [AppTheme]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(themes) { theme in
                    themeCard(theme)
                }
            }
        }
    }

    private var customThemeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Theme")
                .font(.title3.weight(.semibold))

            Text("Build a personal palette and apply it across the app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            StepCard {
                VStack(alignment: .leading, spacing: 16) {
                    Picker("Mode", selection: $customIsDark) {
                        Text("Light").tag(false)
                        Text("Dark").tag(true)
                    }
                    .pickerStyle(.segmented)

                    customColorPicker(title: "Accent", color: $customAccent)
                    customColorPicker(title: "Background", color: $customBackground)
                    customColorPicker(title: "Surface", color: $customSurface)
                    customColorPicker(title: "Secondary surface", color: $customSecondarySurface)

                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(customSecondarySurface)
                        .frame(height: 96)
                        .overlay(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(customSurface)
                                .frame(width: 120, height: 64)
                                .padding(12)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Circle()
                                .fill(customAccent)
                                .frame(width: 20, height: 20)
                                .padding(14)
                        }
                        .background(customBackground, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    HStack(spacing: 12) {
                        Button("Apply custom theme") {
                            appModel.applyCustomTheme(
                                accent: customAccent,
                                background: customBackground,
                                surface: customSurface,
                                secondarySurface: customSecondarySurface,
                                isDark: customIsDark
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(appModel.accentColor)

                        if appModel.usesCustomTheme {
                            Text("Active")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(appModel.accentColor)
                        }
                    }
                }
            }
        }
    }

    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(appModel.secondarySurfaceColor)
        )
    }

    private func themeCard(_ theme: AppTheme) -> some View {
        Button {
            appModel.applyTheme(theme)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.background)
                    .frame(height: 72)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 8) {
                            ForEach(Array(theme.previewColors.enumerated()), id: \.offset) { _, color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 14, height: 14)
                            }
                        }
                        .padding(10)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 18, height: 18)
                            .padding(10)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(theme.name)
                            .font(.headline)
                            .foregroundStyle(themeTextColor(for: theme))

                        Spacer()

                        if theme == appModel.selectedTheme {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.accent)
                        }
                    }

                    Text(theme.isDark ? "Dark theme" : "Light theme")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(themeSecondaryTextColor(for: theme))

                    Text(theme == appModel.selectedTheme ? "Active" : "Tap to apply")
                        .font(.caption)
                        .foregroundStyle(theme == appModel.selectedTheme ? theme.accent : themeSecondaryTextColor(for: theme))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.secondarySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(theme == appModel.selectedTheme && !appModel.usesCustomTheme ? appModel.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func customColorPicker(title: String, color: Binding<Color>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
        }
    }

    private func syncCustomThemeDraft() {
        customAccent = appModel.customThemeAccent
        customBackground = appModel.customThemeBackground
        customSurface = appModel.customThemeSurface
        customSecondarySurface = appModel.customThemeSecondarySurface
        customIsDark = appModel.customThemeIsDark
    }

    private func themeTextColor(for theme: AppTheme) -> Color {
        theme.isDark ? Color.white : Color(red: 0.10, green: 0.14, blue: 0.18)
    }

    private func themeSecondaryTextColor(for theme: AppTheme) -> Color {
        theme.isDark ? Color.white.opacity(0.72) : Color(red: 0.36, green: 0.41, blue: 0.46)
    }

    private var profileHealthStatus: String {
        switch appModel.authorizationState {
        case .readyToQuery: return "Ready"
        case .notDetermined: return "Not connected"
        case .unavailable: return "Unavailable"
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
                .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
        }
    }
}
