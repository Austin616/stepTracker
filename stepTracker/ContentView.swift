//
//  ContentView.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

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
        .task {
            await appModel.prepareIfNeeded()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
    }
}
