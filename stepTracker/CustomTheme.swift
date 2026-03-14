//
//  CustomTheme.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

struct CustomThemeData: Codable {
    var accentHex: String
    var backgroundHex: String
    var surfaceHex: String
    var secondarySurfaceHex: String
    var isDark: Bool

    static let `default` = CustomThemeData(
        accentHex: "#14B8A6",
        backgroundHex: "#0F172A",
        surfaceHex: "#172033",
        secondarySurfaceHex: "#22304A",
        isDark: true
    )

    var accentColor: Color { Color(hex: accentHex) }
    var backgroundColor: Color { Color(hex: backgroundHex) }
    var surfaceColor: Color { Color(hex: surfaceHex) }
    var secondarySurfaceColor: Color { Color(hex: secondarySurfaceHex) }
}

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&int)
        let red = Double((int >> 16) & 0xFF) / 255.0
        let green = Double((int >> 8) & 0xFF) / 255.0
        let blue = Double(int & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(
            format: "#%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
    }
}
