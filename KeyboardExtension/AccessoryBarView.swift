import SwiftUI

struct AccessoryBarView: View {
    var onShortcut: (String) -> Void = { _ in }

    @Environment(\.colorScheme) private var scheme
    private var tokens: AppearanceTokens { AppearanceTokens(scheme: scheme) }

    private let shortcuts = [":", "-", "/", ".com"]

    var body: some View {
        HStack(spacing: 8) {
            iconPill("mic")
            iconPill("camera")

            Rectangle()
                .fill(tokens.keyBorder)
                .frame(width: 0.5, height: 20)

            shortcutPill
        }
        .frame(height: 44)
    }

    // MARK: - Shortcut pill

    private var shortcutPill: some View {
        HStack(spacing: 0) {
            ForEach(Array(shortcuts.enumerated()), id: \.offset) { i, s in
                Button {
                    HapticEngine.shared.keyTap()
                    onShortcut(s)
                } label: {
                    Text(s)
                        .font(.system(size: 15))
                        .foregroundColor(tokens.glyphColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                }
                if i < shortcuts.count - 1 {
                    Rectangle()
                        .fill(tokens.keyBorder)
                        .frame(width: 0.5, height: 16)
                }
            }
        }
        .background(pillBackground)
    }

    // MARK: - Individual icon button

    private func iconPill(_ systemName: String) -> some View {
        Button {
            HapticEngine.shared.keyTap()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16))
                .foregroundColor(tokens.glyphColor)
                .frame(width: 36, height: 36)
                .background(pillBackground)
        }
    }

    // MARK: - Shared pill background

    private var pillBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(tokens.keyMaterial)
            .overlay(RoundedRectangle(cornerRadius: 8).fill(tokens.modifierOverlay))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(tokens.keyBorder, lineWidth: 0.5))
    }
}
