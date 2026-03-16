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

    private let themeColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                header

                if appModel.authorizationState == .readyToQuery {
                    identitySection
                    trackerSection
                    themeSection
                    customThemeSection
                    accountSection
                } else {
                    identitySection
                    themeSection
                    customThemeSection
                    accountSection
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
        .onAppear {
            syncCustomThemeDraft()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PROFILE")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(appModel.accentColor)

            Text("Your setup")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .kerning(-0.8)

            Text("Account, goals, and theme settings in one clean place.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var identitySection: some View {
        HStack(alignment: .center, spacing: 18) {
            Circle()
                .fill(appModel.accentColor)
                .frame(width: 72, height: 72)
                .overlay {
                    Text(appModel.profile.initials)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(appModel.profile.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .kerning(-0.4)
                Text(appModel.isSignedIn ? "Social mode is active." : "Running in guest mode.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var trackerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("TRACKER")

            VStack(spacing: 12) {
                statRow(title: "Daily goal", value: "\(appModel.dailyGoal.formatted()) steps")
                statRow(title: "Health", value: profileHealthStatus)
                statRow(title: "Mode", value: "Local-first")
            }
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("THEMES")

            Text("Pick a preset palette or build one below.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            themeGroup(title: "Light", themes: AppTheme.allCases.filter { !$0.isDark })
            themeGroup(title: "Dark", themes: AppTheme.allCases.filter(\.isDark))
        }
    }

    private func themeGroup(title: String, themes: [AppTheme]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .kerning(-0.3)

            LazyVGrid(columns: themeColumns, spacing: 12) {
                ForEach(themes) { theme in
                    themeCard(theme)
                }
            }
        }
    }

    private var customThemeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionLabel("CUSTOM")

            Text("Shape your own palette and apply it across the app.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 24) {
                    customModeButton(title: "Light", isSelected: !customIsDark) {
                        customIsDark = false
                    }

                    customModeButton(title: "Dark", isSelected: customIsDark) {
                        customIsDark = true
                    }

                    Spacer()
                }

                customPreview

                VStack(spacing: 12) {
                    customColorRow(title: "Accent", color: $customAccent)
                    customColorRow(title: "Background", color: $customBackground)
                    customColorRow(title: "Surface", color: $customSurface)
                    customColorRow(title: "Secondary", color: $customSecondarySurface)
                }

                HStack(spacing: 14) {
                    Button("Apply custom theme") {
                        appModel.applyCustomTheme(
                            accent: customAccent,
                            background: customBackground,
                            surface: customSurface,
                            secondarySurface: customSecondarySurface,
                            isDark: customIsDark
                        )
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(customIsDark ? Color.white : Color.primary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        Capsule(style: .continuous)
                            .fill(appModel.accentColor)
                    )

                    if appModel.usesCustomTheme {
                        Text("Active")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(appModel.accentColor)
                    }
                }

                if appModel.usesCustomTheme {
                    Button("Delete custom theme") {
                        appModel.deleteCustomTheme()
                        syncCustomThemeDraft()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("ACCOUNT")

            HStack(alignment: .center) {
                Text(appModel.isSignedIn ? "Signed in for social comparisons." : "No account required for local tracking.")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(appModel.isSignedIn ? "Sign out" : "Stay guest") {
                    appModel.toggleSignIn()
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(appModel.accentColor)
            }
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .tracking(2.0)
            .foregroundStyle(appModel.accentColor)
    }

    private func statRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.06))
                .frame(height: 1)
                .offset(y: 10)
        }
        .padding(.bottom, 10)
    }

    private func themeCard(_ theme: AppTheme) -> some View {
        let isActive = theme == appModel.selectedTheme && !appModel.usesCustomTheme

        return Button {
            appModel.applyTheme(theme)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(theme.background)
                    .frame(height: 62)
                    .overlay {
                        HStack(spacing: 0) {
                            theme.background
                            theme.surface
                            theme.secondarySurface
                            theme.accent
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .overlay(alignment: .topTrailing) {
                        if isActive {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(theme.accent)
                                .padding(10)
                        }
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(themeTextColor(for: theme))

                    Text(theme.isDark ? "Dark" : "Light")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(themeSecondaryTextColor(for: theme))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.secondarySurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(isActive ? appModel.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var customPreview: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(customBackground)
            .frame(height: 168)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("CUSTOM")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(customAccent)

                    Text("Preview")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(customIsDark ? Color.white : Color.black)

                    Text("A quick look at your palette.")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle((customIsDark ? Color.white : Color.black).opacity(0.68))
                }
                .padding(18)
            }
            .overlay(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(customSurface)
                    .frame(width: 156, height: 72)
                    .overlay(alignment: .bottomLeading) {
                        HStack(spacing: 8) {
                            Circle().fill(customAccent).frame(width: 10, height: 10)
                            Capsule().fill(customSecondarySurface).frame(width: 64, height: 10)
                        }
                        .padding(14)
                    }
                    .padding(16)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(customAccent)
                    .frame(width: 22, height: 22)
                    .padding(18)
            }
    }

    private func customModeButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.primary : .secondary)

                Capsule(style: .continuous)
                    .fill(isSelected ? appModel.accentColor : Color.primary.opacity(0.10))
                    .frame(width: isSelected ? 30 : 16, height: 3)
            }
        }
        .buttonStyle(.plain)
    }

    private func customColorRow(title: String, color: Binding<Color>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()

            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(.vertical, 2)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.06))
                .frame(height: 1)
                .offset(y: 10)
        }
        .padding(.bottom, 10)
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
