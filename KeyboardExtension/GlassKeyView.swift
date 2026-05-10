import SwiftUI

// MARK: - GlassKeyView (text label key)

struct GlassKeyView: View {
    let label: String
    var isModifier: Bool = false
    var fontSize: CGFloat = 18
    var alts: [String] = []          // long-press alternatives
    var onTap: () -> Void = {}
    var onAlt: ((String) -> Void)? = nil

    @Environment(\.colorScheme) private var scheme
    @State private var pressed      = false
    @State private var didLongPress = false
    @State private var longTask: Task<Void, Never>?

    private var tokens: AppearanceTokens { AppearanceTokens(scheme: scheme) }

    var body: some View {
        ZStack(alignment: .top) {
            keyBody
                .overlay(
                    RoundedRectangle(cornerRadius: 8.5)
                        .fill(Color.white.opacity(pressed ? 0.20 : 0))
                        .allowsHitTesting(false)
                )
                .scaleEffect(pressed ? 0.94 : 1.0)
                .animation(.spring(response: 0.08, dampingFraction: 0.75), value: pressed)

            if pressed {
                callout
                    .offset(y: -54)
                    .allowsHitTesting(false)
                    .zIndex(100)
                    .transition(.opacity)
            }
        }
        .contentShape(Rectangle())
        .gesture(mainGesture)
    }

    // MARK: Key face

    private var keyBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8.5)
                .fill(tokens.keyMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8.5)
                        .fill(isModifier ? tokens.modifierOverlay : tokens.keyOverlay)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8.5)
                        .strokeBorder(tokens.keyBorder, lineWidth: 0.5)
                )
                .shadow(color: tokens.keyShadow,
                        radius: tokens.keyShadowRadius, x: 0, y: 1)

            Text(label)
                .font(.system(size: fontSize, weight: .regular))
                .foregroundColor(tokens.glyphColor)
        }
    }

    // MARK: Callout bubble

    @ViewBuilder
    private var callout: some View {
        if alts.isEmpty {
            Text(label)
                .font(.system(size: 26, weight: .regular))
                .foregroundColor(tokens.glyphColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground(cornerRadius: 8.5))
        } else {
            HStack(spacing: 2) {
                ForEach([label] + alts, id: \.self) { opt in
                    Text(opt)
                        .font(.system(size: 22, weight: .regular))
                        .foregroundColor(tokens.glyphColor)
                        .frame(width: 40, height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(opt == label ? tokens.modifierOverlay : Color.clear)
                        )
                }
            }
            .padding(6)
            .background(bubbleBackground(cornerRadius: 8.5))
        }
    }

    private func bubbleBackground(cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(tokens.keyMaterial)
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).fill(tokens.keyOverlay))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(tokens.keyBorder, lineWidth: 0.5))
            .shadow(color: tokens.keyShadow, radius: 4, x: 0, y: 2)
    }

    // MARK: Gesture
    // Uses a single DragGesture + async Task so there are no competing gesture recognisers.

    private var mainGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !pressed else { return }
                pressed = true
                HapticEngine.shared.keyTap()
                guard !alts.isEmpty else { return }
                longTask = Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        didLongPress = true
                        onAlt?(alts[0])
                        pressed = false
                    }
                }
            }
            .onEnded { _ in
                longTask?.cancel(); longTask = nil
                if !didLongPress { onTap() }
                pressed = false
                didLongPress = false
            }
    }
}

// MARK: - GlassIconKeyView (SF Symbol key)

struct GlassIconKeyView: View {
    let systemName: String
    var pointSize:  CGFloat      = 18
    var isModifier: Bool         = true
    var customFill: Color?       = nil
    var glowColor:  Color?       = nil
    var onTap: () -> Void        = {}

    @Environment(\.colorScheme) private var scheme
    @State private var pressed = false

    private var tokens: AppearanceTokens { AppearanceTokens(scheme: scheme) }

    var body: some View {
        ZStack {
            keyBackground
            Image(systemName: systemName)
                .font(.system(size: pointSize, weight: .regular))
                .foregroundColor(customFill != nil ? .white : tokens.glyphColor)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8.5)
                .fill(Color.white.opacity(pressed ? 0.20 : 0))
                .allowsHitTesting(false)
        )
        .scaleEffect(pressed ? 0.94 : 1.0)
        .animation(.spring(response: 0.08, dampingFraction: 0.75), value: pressed)
        .contentShape(Rectangle())
        .gesture(tapGesture)
    }

    @ViewBuilder
    private var keyBackground: some View {
        if let fill = customFill {
            RoundedRectangle(cornerRadius: 8.5)
                .fill(fill)
                .shadow(color: glowColor ?? fill.opacity(0.5), radius: 4)
        } else {
            RoundedRectangle(cornerRadius: 8.5)
                .fill(tokens.keyMaterial)
                .overlay(RoundedRectangle(cornerRadius: 8.5).fill(tokens.modifierOverlay))
                .overlay(RoundedRectangle(cornerRadius: 8.5).strokeBorder(tokens.keyBorder, lineWidth: 0.5))
                .shadow(color: tokens.keyShadow, radius: tokens.keyShadowRadius, x: 0, y: 1)
        }
    }

    private var tapGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in guard !pressed else { return }; pressed = true }
            .onEnded   { _ in pressed = false; onTap() }
    }
}
