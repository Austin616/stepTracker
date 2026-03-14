//
//  AppTheme.swift
//  stepTracker
//
//  Created by Austin Tran on 3/13/26.
//

import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case core
    case terminal
    case samurai
    case tide
    case paper
    case olive
    case beach
    case breeze
    case honey
    case dualshot
    case redSamurai
    case retrocast
    case muted
    case vaporwave
    case diner
    case evilEye

    var id: String { rawValue }

    var name: String {
        switch self {
        case .core: return "Core"
        case .terminal: return "Terminal"
        case .samurai: return "Samurai"
        case .tide: return "Tide"
        case .paper: return "Paper"
        case .olive: return "Olive"
        case .beach: return "Beach"
        case .breeze: return "Breeze"
        case .honey: return "Honey"
        case .dualshot: return "Dualshot"
        case .redSamurai: return "Red Samurai"
        case .retrocast: return "Retrocast"
        case .muted: return "Muted"
        case .vaporwave: return "Vaporwave"
        case .diner: return "Diner"
        case .evilEye: return "Evil Eye"
        }
    }

    var preferredColorScheme: ColorScheme {
        switch self {
        case .dualshot, .redSamurai, .retrocast, .muted, .vaporwave, .diner, .evilEye:
            return .dark
        case .core, .terminal, .samurai, .tide, .paper, .olive, .beach, .breeze, .honey:
            return .light
        }
    }

    var isDark: Bool {
        preferredColorScheme == .dark
    }

    var accent: Color {
        switch self {
        case .core: return Color(red: 0.05, green: 0.69, blue: 0.56)
        case .terminal: return Color(red: 0.25, green: 0.74, blue: 0.51)
        case .samurai: return Color(red: 0.80, green: 0.31, blue: 0.24)
        case .tide: return Color(red: 0.12, green: 0.59, blue: 0.78)
        case .paper: return Color(red: 0.21, green: 0.27, blue: 0.34)
        case .olive: return Color(red: 0.53, green: 0.54, blue: 0.36)
        case .beach: return Color(red: 0.38, green: 0.76, blue: 0.82)
        case .breeze: return Color(red: 0.49, green: 0.42, blue: 0.76)
        case .honey: return Color(red: 0.95, green: 0.69, blue: 0.10)
        case .dualshot: return Color(red: 0.80, green: 0.78, blue: 0.72)
        case .redSamurai: return Color(red: 0.80, green: 0.61, blue: 0.38)
        case .retrocast: return Color(red: 0.51, green: 0.86, blue: 0.87)
        case .muted: return Color(red: 0.82, green: 0.73, blue: 0.95)
        case .vaporwave: return Color(red: 0.94, green: 0.35, blue: 0.86)
        case .diner: return Color(red: 0.88, green: 0.74, blue: 0.29)
        case .evilEye: return Color(red: 0.92, green: 0.93, blue: 0.98)
        }
    }

    var background: Color {
        switch self {
        case .core: return Color(red: 0.98, green: 0.99, blue: 0.98)
        case .terminal: return Color(red: 0.95, green: 0.98, blue: 0.95)
        case .samurai: return Color(red: 0.99, green: 0.96, blue: 0.93)
        case .tide: return Color(red: 0.95, green: 0.98, blue: 0.99)
        case .paper: return Color(red: 0.98, green: 0.97, blue: 0.95)
        case .olive: return Color(red: 0.96, green: 0.95, blue: 0.86)
        case .beach: return Color(red: 1.00, green: 0.94, blue: 0.75)
        case .breeze: return Color(red: 0.95, green: 0.88, blue: 0.82)
        case .honey: return Color(red: 0.99, green: 0.88, blue: 0.47)
        case .dualshot: return Color(red: 0.11, green: 0.12, blue: 0.15)
        case .redSamurai: return Color(red: 0.16, green: 0.08, blue: 0.11)
        case .retrocast: return Color(red: 0.10, green: 0.16, blue: 0.18)
        case .muted: return Color(red: 0.20, green: 0.20, blue: 0.22)
        case .vaporwave: return Color(red: 0.17, green: 0.13, blue: 0.27)
        case .diner: return Color(red: 0.21, green: 0.33, blue: 0.44)
        case .evilEye: return Color(red: 0.08, green: 0.23, blue: 0.41)
        }
    }

    var surface: Color {
        switch self {
        case .core: return .white
        case .terminal: return Color(red: 0.97, green: 1.00, blue: 0.97)
        case .samurai: return Color(red: 1.00, green: 0.98, blue: 0.96)
        case .tide: return Color(red: 0.98, green: 1.00, blue: 1.00)
        case .paper: return Color(red: 1.00, green: 0.99, blue: 0.98)
        case .olive: return Color(red: 0.97, green: 0.94, blue: 0.84)
        case .beach: return Color(red: 1.00, green: 0.96, blue: 0.84)
        case .breeze: return Color(red: 0.97, green: 0.90, blue: 0.85)
        case .honey: return Color(red: 1.00, green: 0.91, blue: 0.58)
        case .dualshot: return Color(red: 0.16, green: 0.17, blue: 0.21)
        case .redSamurai: return Color(red: 0.21, green: 0.11, blue: 0.14)
        case .retrocast: return Color(red: 0.13, green: 0.22, blue: 0.24)
        case .muted: return Color(red: 0.25, green: 0.24, blue: 0.28)
        case .vaporwave: return Color(red: 0.23, green: 0.18, blue: 0.36)
        case .diner: return Color(red: 0.27, green: 0.41, blue: 0.55)
        case .evilEye: return Color(red: 0.10, green: 0.30, blue: 0.51)
        }
    }

    var secondarySurface: Color {
        switch self {
        case .core: return Color(red: 0.94, green: 0.96, blue: 0.94)
        case .terminal: return Color(red: 0.90, green: 0.95, blue: 0.90)
        case .samurai: return Color(red: 0.96, green: 0.92, blue: 0.88)
        case .tide: return Color(red: 0.90, green: 0.96, blue: 0.98)
        case .paper: return Color(red: 0.93, green: 0.92, blue: 0.90)
        case .olive: return Color(red: 0.90, green: 0.88, blue: 0.73)
        case .beach: return Color(red: 0.96, green: 0.88, blue: 0.66)
        case .breeze: return Color(red: 0.91, green: 0.84, blue: 0.90)
        case .honey: return Color(red: 0.95, green: 0.78, blue: 0.25)
        case .dualshot: return Color(red: 0.22, green: 0.23, blue: 0.28)
        case .redSamurai: return Color(red: 0.27, green: 0.15, blue: 0.18)
        case .retrocast: return Color(red: 0.18, green: 0.28, blue: 0.30)
        case .muted: return Color(red: 0.31, green: 0.30, blue: 0.35)
        case .vaporwave: return Color(red: 0.30, green: 0.21, blue: 0.43)
        case .diner: return Color(red: 0.35, green: 0.49, blue: 0.64)
        case .evilEye: return Color(red: 0.15, green: 0.37, blue: 0.60)
        }
    }

    var previewColors: [Color] {
        [background, secondarySurface, accent]
    }
}
