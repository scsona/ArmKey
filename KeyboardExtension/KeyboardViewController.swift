import UIKit
import SwiftUI
import Combine

// MARK: - KeyboardViewModel

final class KeyboardViewModel: ObservableObject {
    @Published var isShifted    = false
    @Published var isCapsLocked = false

    var onInsert:       (String) -> Void = { _ in }
    var onDelete:       () -> Void       = {}
    var onNextKeyboard: () -> Void       = {}

    func insertLetter(_ text: String) {
        onInsert(text)
        if isShifted && !isCapsLocked { isShifted = false }
    }

    func insertControl(_ text: String) {
        onInsert(text)
    }

    func deleteBackward() { onDelete() }
}

// MARK: - PressableKey
//
// Touch-down firing pressable wrapper. Replaces `Button` for typing speed:
// `Button` only fires on touch-up after recognising a tap, which inserts a
// noticeable delay during fast typing. Native iOS keyboards fire on touch-down.

private struct PressableKey<Content: View>: View {
    var repeating: Bool = false
    var cornerRadius: CGFloat = 10
    let onPress: (_ isInitial: Bool) -> Void
    var onRelease: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    @State private var isPressed = false
    @State private var repeatTask: Task<Void, Never>? = nil

    var body: some View {
        content()
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(isPressed ? 0.20 : 0))
                    .allowsHitTesting(false)
            )
            .scaleEffect(isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.08, dampingFraction: 0.75), value: isPressed)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !isPressed else { return }
                        isPressed = true
                        onPress(true)
                        if repeating {
                            repeatTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 400_000_000)
                                var interval: UInt64 = 80_000_000
                                var iter = 0
                                while !Task.isCancelled {
                                    onPress(false)
                                    iter += 1
                                    if iter == 12 { interval = 35_000_000 }  // accelerate after ~1s
                                    try? await Task.sleep(nanoseconds: interval)
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        repeatTask?.cancel()
                        repeatTask = nil
                        onRelease?()
                    }
            )
    }
}

// MARK: - KeyboardView

private struct KeyboardView: View {
    @ObservedObject var model: KeyboardViewModel
    @Environment(\.colorScheme) private var scheme
    private var tokens: AppearanceTokens { AppearanceTokens(scheme: scheme) }

    @State private var lastShiftTap: Date? = nil

    private let rowH:   CGFloat = 42
    private let rowGap: CGFloat = 9
    private let keyGap: CGFloat = 6
    private let keyRadius: CGFloat = 10
    private let keyFontSize: CGFloat = 18
    private let edgeInset: CGFloat = 6.5
    private let bottomInset: CGFloat = 0
    private let topInset: CGFloat = 0
    private let specialKeyWidth: CGFloat = 43

    var body: some View {
        VStack(spacing: rowGap) {
            rowView(KeyboardLayout.rows[1])
            rowView(KeyboardLayout.rows[2])
            rowView(KeyboardLayout.rows[3])
            rowView(KeyboardLayout.rows[4])
            bottomRow
        }
        .padding(.horizontal, edgeInset)
        .padding(.top, topInset)
        .padding(.bottom, bottomInset)
        .background(Color.clear)
    }

    // MARK: - Generic row

    private func rowView(_ keys: [KeyModel]) -> some View {
        HStack(spacing: keyGap) {
            ForEach(keys) { key in keyCell(key) }
        }
        .frame(height: rowH)
    }

    // MARK: - Key cell

    private func keyCell(_ key: KeyModel, height: CGFloat? = nil) -> some View {
        let label       = (model.isShifted || model.isCapsLocked) ? key.shifted : key.base
        let h           = height ?? rowH
        let isShiftKey  = key.type == .shift
        let shiftActive = isShiftKey && (model.isShifted || model.isCapsLocked)
        let capsActive  = isShiftKey && model.isCapsLocked

        return PressableKey(
            repeating: key.type == .backspace,
            onPress: { isInitial in tap(key, isInitial: isInitial) }
        ) {
            Group {
                if key.type == .media {
                    Image(systemName: label)
                        .font(.system(size: 13))
                        .foregroundColor(tokens.glyphColor)
                } else {
                    Text(label)
                        .font(.system(size: keyFontSize, weight: .regular))
                        .foregroundColor(tokens.glyphColor)
                }
            }
            .frame(maxWidth: .infinity, minHeight: h, maxHeight: h)
            .background(
                KeyBlendBackground(cornerRadius: keyRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: keyRadius)
                            .fill(
                                capsActive  ? Color.white.opacity(0.28) :
                                shiftActive ? Color.white.opacity(0.16) :
                                Color.clear
                            )
                    )
                    .shadow(color: tokens.keyShadow, radius: tokens.keyShadowRadius, x: 0, y: 1)
            )
        }
    }

    // MARK: - Bottom row (123 · emoji · space · return)

    private func modifierKeyBg(_ cornerRadius: CGFloat) -> some View {
        KeyBlendBackground(cornerRadius: cornerRadius)
            .shadow(color: tokens.keyShadow, radius: tokens.keyShadowRadius, x: 0, y: 1)
    }

    private var bottomRow: some View {
        HStack(spacing: keyGap) {
            PressableKey(onPress: { _ in HapticEngine.shared.keyTap() }) {
                Text("123")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(
                onPress: { _ in HapticEngine.shared.keyTap() },
                onRelease: { model.onNextKeyboard() }
            ) {
                Image(systemName: "globe")
                    .font(.system(size: keyFontSize))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(onPress: { _ in
                HapticEngine.shared.spaceTap()
                model.insertLetter(" ")
            }) {
                Text("space")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(maxWidth: .infinity, minHeight: rowH, maxHeight: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(onPress: { _ in
                HapticEngine.shared.returnTap()
                model.insertControl("\n")
            }) {
                Text("return")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: 90, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }
        }
        .frame(height: rowH)
    }

    // MARK: - Actions

    private func tap(_ key: KeyModel, isInitial: Bool) {
        switch key.type {
        case .letter:
            let text = (model.isShifted || model.isCapsLocked) ? key.shifted : key.base
            model.insertLetter(text)
            HapticEngine.shared.keyTap()

        case .backspace:
            model.deleteBackward()
            if isInitial { HapticEngine.shared.deleteTap() }

        case .returnKey:
            model.insertControl("\n")
            HapticEngine.shared.returnTap()

        case .tab:
            model.insertControl("\t")
            HapticEngine.shared.keyTap()

        case .shift:
            handleShiftTap()

        case .capsLock:
            model.isCapsLocked.toggle()
            if !model.isCapsLocked { model.isShifted = false }
            HapticEngine.shared.shiftToggle()

        case .modifier, .media:
            HapticEngine.shared.keyTap()
        }
    }

    /// Single tap → one-shot shift toggle. Two taps within 300ms → caps lock.
    private func handleShiftTap() {
        let now = Date()
        if let last = lastShiftTap, now.timeIntervalSince(last) < 0.3 {
            model.isCapsLocked = true
            model.isShifted    = true
            lastShiftTap       = nil
        } else {
            if model.isCapsLocked {
                model.isCapsLocked = false
                model.isShifted    = false
            } else {
                model.isShifted.toggle()
            }
            lastShiftTap = now
        }
        HapticEngine.shared.shiftToggle()
    }
}

// MARK: - KeyboardViewController

class KeyboardViewController: UIInputViewController {
    private let model = KeyboardViewModel()

    private let desiredKeyboardHeight: CGFloat = 5 * 42 + 4 * 12
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.isOpaque = false
        wireModel()
        embedKeyboardView()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        if heightConstraint == nil {
            let c = view.heightAnchor.constraint(equalToConstant: desiredKeyboardHeight)
            c.priority = .required - 1
            c.isActive = true
            heightConstraint = c
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        HapticEngine.shared.configure(hasFullAccess: hasFullAccess)
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previous) {
            HapticEngine.shared.configure(hasFullAccess: hasFullAccess)
        }
    }

    private func wireModel() {
        model.onInsert       = { [weak self] t in self?.textDocumentProxy.insertText(t) }
        model.onDelete       = { [weak self] in  self?.textDocumentProxy.deleteBackward() }
        model.onNextKeyboard = { [weak self] in  self?.advanceToNextInputMode() }
    }

    private func embedKeyboardView() {
        let hvc = UIHostingController(rootView: KeyboardView(model: model))
        hvc.view.backgroundColor = .clear
        hvc.view.isOpaque = false
        hvc.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hvc)
        view.addSubview(hvc.view)
        NSLayoutConstraint.activate([
            hvc.view.topAnchor.constraint(equalTo: view.topAnchor),
            hvc.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hvc.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hvc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hvc.didMove(toParent: self)
    }
}
