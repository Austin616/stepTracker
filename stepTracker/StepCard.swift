//
//  StepCard.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

struct StepCard<Content: View>: View {
    @EnvironmentObject private var appModel: AppModel
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(appModel.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(appModel.isDarkTheme ? Color.white.opacity(0.05) : Color.clear, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(appModel.isDarkTheme ? 0.22 : 0.06), radius: 18, y: 8)
            )
    }
}
