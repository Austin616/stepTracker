//
//  ContentView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        TabView {
            Tab("Home", systemImage: "figure.walk") {
                NavigationStack {
                    HomeView()
                }
            }

            Tab("Trends", systemImage: "chart.xyaxis.line") {
                NavigationStack {
                    TrendsView()
                }
            }

            Tab("Friends", systemImage: "person.2.fill") {
                NavigationStack {
                    FriendsView()
                }
            }

            Tab("Profile", systemImage: "person.crop.circle") {
                NavigationStack {
                    ProfileView()
                }
            }
        }
        .tint(appModel.accentColor)
        .preferredColorScheme(appModel.preferredColorScheme)
        .onAppear {
            configureTabBarAppearance()
        }
        .onChange(of: appModel.themeRefreshKey) { _, _ in
            configureTabBarAppearance()
        }
        .task {
            await appModel.prepareIfNeeded()
        }
    }

    private func configureTabBarAppearance() {
        #if canImport(UIKit)
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.88 : 0.92))
        appearance.shadowColor = UIColor(Color.primary.opacity(appModel.isDarkTheme ? 0.10 : 0.06))

        let normalColor = UIColor.secondaryLabel
        let selectedColor = UIColor(appModel.accentColor)

        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedColor]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        #endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
    }
}
