import SwiftUI
import UIKit

// MARK: - KeyBlendBackground

/// Lightweight translucent key background. Lets the system-provided keyboard
/// backdrop blur show through with a subtle tint — gives the iOS 26 "glass key"
/// look without instantiating a `UIVisualEffectView` per key (which blows the
/// keyboard extension's tight memory budget and causes the extension to be
/// killed on launch).
struct KeyBlendBackground: UIViewRepresentable {
    var cornerRadius: CGFloat = 8.5

    private static let fill = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor.white.withAlphaComponent(0.55)
    }

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = Self.fill
        v.layer.cornerRadius = cornerRadius
        v.layer.masksToBounds = true
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.backgroundColor = Self.fill
        uiView.layer.cornerRadius = cornerRadius
    }
}

// MARK: - AppearanceTokens

/// Single source of truth for all visual values.
/// Drives both light and dark mode reactively — pass `@Environment(\.colorScheme)`
/// so SwiftUI views update automatically on mid-session appearance changes.
struct AppearanceTokens {
    let scheme: ColorScheme

    // MARK: - Tray
    var trayMaterial: Material {
        scheme == .dark ? .ultraThinMaterial : .regularMaterial
    }

    // MARK: - Letter keys
    var keyMaterial: Material {
        scheme == .dark ? .ultraThinMaterial : .regularMaterial
    }
    var keyOverlay: Color {
        scheme == .dark ? .white.opacity(0.13) : .white.opacity(0.50)
    }
    var keyBorder: Color {
        scheme == .dark ? .white.opacity(0.25) : .black.opacity(0.10)
    }
    var keyShadow: Color {
        .black.opacity(scheme == .dark ? 0.30 : 0.12)
    }
    var keyShadowRadius: CGFloat { scheme == .dark ? 1 : 2 }

    // MARK: - Modifier keys (Shift / Delete / 123 — slightly more opaque)
    var modifierOverlay: Color {
        scheme == .dark ? .white.opacity(0.07) : .black.opacity(0.06)
    }

    // MARK: - Glyphs
    var glyphColor: Color {
        scheme == .dark ? .white.opacity(0.90) : .black.opacity(0.85)
    }

    // MARK: - Return key (solid, no glass treatment)
    static let returnFill = Color(red: 0, green: 122 / 255, blue: 1)       // #007AFF
    static let returnGlow = Color(red: 0, green: 122 / 255, blue: 1).opacity(0.6)
}
