import UIKit
import SwiftUI
import Combine

// MARK: - KeyboardViewModel

enum KeyboardMode { case alphabetic, numeric, emoji }

final class KeyboardViewModel: ObservableObject {
    @Published var isShifted    = false
    @Published var isCapsLocked = false
    @Published var mode: KeyboardMode = .alphabetic

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

// MARK: - KeyMetrics
//
// Every key owns a gapless touch slot. The visual key face is drawn inset
// inside a slot that reaches halfway into each neighbouring gap — and all the
// way to the screen edge for the outermost keys — so the space between keys is
// still live for touches. This is how the system keyboard behaves: the visual
// gaps exist only for looks, and no point in the keyboard is unclaimed.
//
// Note the slots tile exactly: they neither leave dead zones (which swallow a
// tap outright) nor overlap (which lets the wrong key win an ambiguous touch).

enum KeyMetrics {
    // Gaps are uniform in both axes. Shrinking a gap does not shrink the touch
    // slot — the slot always spans face + gap — it just hands the pixels to the
    // visible key face, so the thing you aim at matches the thing that responds.
    static let keyH:            CGFloat = 48    // visual key height (was 42)
    static let rowGap:          CGFloat = 5     // visual gap between rows (was 9)
    static let keyGap:          CGFloat = 5     // visual gap between keys in a row (was 6)
    static let edgeInset:       CGFloat = 4.5   // visual gap from outer keys to screen edge (was 6.5)
    static let keyRadius:       CGFloat = 10
    static let keyFontSize:     CGFloat = 18
    static let specialKeyWidth: CGFloat = 43
    static let returnKeyWidth:  CGFloat = 90

    /// Height of a row's touch slots: the key face plus its share of both row gaps.
    static let rowSlotH: CGFloat = keyH + rowGap
    static let rowCount: Int     = 5
    static let keyboardHeight: CGFloat = CGFloat(rowCount) * rowSlotH

    /// Slot padding around a key at `index` of a row holding `count` keys.
    /// Outer keys swallow the edge inset so their slots run to the screen edge.
    static func insets(_ index: Int, count: Int) -> EdgeInsets {
        EdgeInsets(top:      rowGap / 2,
                   leading:  index == 0         ? edgeInset : keyGap / 2,
                   bottom:   rowGap / 2,
                   trailing: index == count - 1 ? edgeInset : keyGap / 2)
    }

    /// Width of a key face in a row of `count` equally sized keys.
    static func keyWidth(in rowWidth: CGFloat, count: Int) -> CGFloat {
        let n = CGFloat(count)
        return max(0, (rowWidth - 2 * edgeInset - (n - 1) * keyGap) / n)
    }
}

// MARK: - PressableKey
//
// Touch-down firing pressable wrapper. Replaces `Button` for typing speed:
// `Button` only fires on touch-up after recognising a tap, which inserts a
// noticeable delay during fast typing. Native iOS keyboards fire on touch-down.

private struct PressableKey<Content: View>: View {
    var repeating: Bool = false
    var cornerRadius: CGFloat = KeyMetrics.keyRadius
    /// Padding between the visual key face and the edge of its touch slot.
    /// Applied outside the pressed-state scaling so the target never moves.
    var hitInsets: EdgeInsets = EdgeInsets()
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
            .padding(hitInsets)
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

    private let rowH        = KeyMetrics.keyH
    private let rowSlotH    = KeyMetrics.rowSlotH
    private let keyRadius   = KeyMetrics.keyRadius
    private let keyFontSize = KeyMetrics.keyFontSize
    private let specialKeyWidth = KeyMetrics.specialKeyWidth

    var body: some View {
        Group {
            if model.mode == .emoji {
                EmojiPickerView(
                    tokens: tokens,
                    onInsert: { model.insertLetter($0) },
                    onBack: { model.mode = .alphabetic },
                    onDelete: { model.deleteBackward() }
                )
            } else {
                // No spacing or padding here: the gaps live inside each key's
                // touch slot instead, so nothing between keys is untappable.
                VStack(spacing: 0) {
                    if model.mode == .numeric {
                        numericBody
                    } else {
                        alphabeticBody
                    }
                }
            }
        }
        .background(Color.clear)
    }

    private var alphabeticBody: some View {
        Group {
            rowView(KeyboardLayout.rows[1])
            rowView(KeyboardLayout.rows[2])
            rowView(KeyboardLayout.rows[3])
            rowView(KeyboardLayout.rows[4])
            bottomRow
        }
    }

    private var numericBody: some View {
        Group {
            rowView(KeyboardLayout.numericRows[0])
            rowView(KeyboardLayout.numericRows[1])
            rowView(KeyboardLayout.numericRows[3])
            numericSymbolRow
            numericBottomRow
        }
    }

    // MARK: - Generic row
    //
    // Key faces are sized explicitly from the row width so every key keeps the
    // same visual width while the outer keys still get a wider touch slot that
    // runs to the screen edge.

    private func rowView(_ keys: [KeyModel]) -> some View {
        GeometryReader { geo in
            let keyW = KeyMetrics.keyWidth(in: geo.size.width, count: keys.count)
            HStack(spacing: 0) {
                ForEach(Array(keys.enumerated()), id: \.element.id) { idx, key in
                    keyCell(key,
                            width: keyW,
                            insets: KeyMetrics.insets(idx, count: keys.count))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(height: rowSlotH)
    }

    // MARK: - Key cell

    private func keyCell(_ key: KeyModel, width: CGFloat? = nil, insets: EdgeInsets) -> some View {
        let label       = (model.isShifted || model.isCapsLocked) ? key.shifted : key.base
        let isShiftKey  = key.type == .shift
        let shiftActive = isShiftKey && (model.isShifted || model.isCapsLocked)
        let capsActive  = isShiftKey && model.isCapsLocked

        return PressableKey(
            repeating: key.type == .backspace,
            hitInsets: insets,
            onPress: { isInitial in tap(key, isInitial: isInitial) }
        ) {
            keyFace(width: width) {
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

    /// A key face of `width` points, or one that shares the row's free space
    /// equally with its siblings when `width` is nil.
    @ViewBuilder
    private func keyFace<Content: View>(width: CGFloat?,
                                        @ViewBuilder content: () -> Content) -> some View {
        if let width {
            content().frame(width: width, height: rowH)
        } else {
            content().frame(maxWidth: .infinity, minHeight: rowH, maxHeight: rowH)
        }
    }

    // MARK: - Bottom row (123 · emoji · space · return)

    private func modifierKeyBg(_ cornerRadius: CGFloat) -> some View {
        KeyBlendBackground(cornerRadius: cornerRadius)
            .shadow(color: tokens.keyShadow, radius: tokens.keyShadowRadius, x: 0, y: 1)
    }

    private var bottomRow: some View {
        HStack(spacing: 0) {
            PressableKey(hitInsets: KeyMetrics.insets(0, count: 4), onPress: { _ in
                HapticEngine.shared.keyTap()
                model.mode = .numeric
            }) {
                Text("123")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(hitInsets: KeyMetrics.insets(1, count: 4), onPress: { _ in
                HapticEngine.shared.keyTap()
                model.mode = .emoji
            }) {
                Text("😊")
                    .font(.system(size: 20))
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(hitInsets: KeyMetrics.insets(2, count: 4), onPress: { _ in
                HapticEngine.shared.spaceTap()
                model.insertLetter(" ")
            }) {
                Text("space")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(maxWidth: .infinity, minHeight: rowH, maxHeight: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(hitInsets: KeyMetrics.insets(3, count: 4), onPress: { _ in
                HapticEngine.shared.returnTap()
                model.insertControl("\n")
            }) {
                Text("return")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: KeyMetrics.returnKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }
        }
        .frame(height: rowSlotH)
    }

    // MARK: - Numeric symbol row  ( [#+= no-op]  .  ,  ?  !  '  [⌫] )

    private var numericSymbolRow: some View {
        let symbols = KeyboardLayout.numericRows[2]
        let count   = symbols.count + 2          // flanking #+= and ⌫ keys

        return HStack(spacing: 0) {
            PressableKey(hitInsets: KeyMetrics.insets(0, count: count),
                         onPress: { _ in HapticEngine.shared.keyTap() }) {
                Text("#+= ")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            ForEach(Array(symbols.enumerated()), id: \.element.id) { idx, key in
                keyCell(key, insets: KeyMetrics.insets(idx + 1, count: count))
            }

            PressableKey(
                repeating: true,
                hitInsets: KeyMetrics.insets(count - 1, count: count),
                onPress: { isInitial in
                    model.deleteBackward()
                    if isInitial { HapticEngine.shared.deleteTap() }
                }
            ) {
                Text("⌫")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }
        }
        .frame(height: rowSlotH)
    }

    // MARK: - Numeric bottom row  ( ABC  globe  space  return )

    private var numericBottomRow: some View {
        HStack(spacing: 0) {
            PressableKey(hitInsets: KeyMetrics.insets(0, count: 4), onPress: { _ in
                HapticEngine.shared.keyTap()
                model.mode = .alphabetic
            }) {
                Text("ABC")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(hitInsets: KeyMetrics.insets(1, count: 4), onPress: { _ in
                HapticEngine.shared.keyTap()
                model.mode = .emoji
            }) {
                Text("😊")
                    .font(.system(size: 20))
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(hitInsets: KeyMetrics.insets(2, count: 4), onPress: { _ in
                HapticEngine.shared.spaceTap()
                model.insertLetter(" ")
            }) {
                Text("space")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(maxWidth: .infinity, minHeight: rowH, maxHeight: rowH)
                    .background(modifierKeyBg(keyRadius))
            }

            PressableKey(hitInsets: KeyMetrics.insets(3, count: 4), onPress: { _ in
                HapticEngine.shared.returnTap()
                model.insertControl("\n")
            }) {
                Text("return")
                    .font(.system(size: keyFontSize, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: KeyMetrics.returnKeyWidth, height: rowH)
                    .background(modifierKeyBg(keyRadius))
            }
        }
        .frame(height: rowSlotH)
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

// MARK: - EmojiPickerView

private struct EmojiPickerView: View {
    let tokens: AppearanceTokens
    let onInsert: (String) -> Void
    let onBack: () -> Void
    let onDelete: () -> Void

    @State private var selectedCategory = 0

    private let rowH            = KeyMetrics.keyH
    private let rowSlotH        = KeyMetrics.rowSlotH
    private let keyRadius       = KeyMetrics.keyRadius
    private let specialKeyWidth = KeyMetrics.specialKeyWidth

    private static let categories: [(icon: String, emojis: [String])] = [
        ("😀", ["😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","😉","😊","😇","🥰","😍","🤩","😘","😗","😚","😙","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔","😐","😑","😶","😏","😒","🙄","😬","😌","😔","😪","😴","😷","🤒","🤕","🤢","🤧","🥵","🥶","😵","🤯","🤠","🥳","😎","🤓","😕","😟","🙁","☹️","😮","😲","😳","🥺","😦","😧","😨","😰","😥","😢","😭","😱","😖","😣","😞","😓","😩","😫","😤","😡","😠","🤬","😈","👿","💀","☠️","💩","🤡","👹","👺","👻","👽","👾","🤖"]),
        ("👋", ["👋","🤚","🖐","✋","🖖","👌","✌️","🤞","🤟","🤘","👈","👉","👆","☝️","👇","👍","👎","✊","👊","🤛","🤜","👏","🙌","👐","🤲","🤝","🙏","✍️","💅","🤳","💪","🦵","🦶","👂","🦻","👃","👀","👁","👅","👄","🧠","🦷","🦴"]),
        ("🐶", ["🐶","🐱","🐭","🐹","🐰","🦊","🐻","🐼","🐨","🐯","🦁","🐮","🐷","🐸","🐵","🙈","🙉","🙊","🐔","🐧","🐦","🐤","🦆","🦅","🦉","🦇","🐺","🐗","🐴","🦄","🐝","🐛","🦋","🐌","🐞","🐜","🦟","🦗","🕷","🦂","🐢","🐍","🦎","🐙","🦑","🦐","🦞","🦀","🐡","🐠","🐟","🐬","🐳","🐋","🦈","🐊","🐅","🐆","🦓","🐘","🦛","🦏","🐪","🐫","🦒","🦘","🐃","🐂","🐄","🐎","🐖","🐏","🐑","🐐","🦌","🐕","🐩","🐈","🐓","🦃","🦚","🦜","🦢","🦩","🕊","🐇","🦝","🦨","🦡","🦦","🦥","🐁","🐀","🐿","🦔"]),
        ("🍎", ["🍎","🍐","🍊","🍋","🍌","🍉","🍇","🍓","🫐","🍒","🍑","🥭","🍍","🥥","🥝","🍅","🍆","🥑","🥦","🥬","🥒","🌶","🧄","🧅","🥔","🍠","🥐","🥯","🍞","🥖","🧀","🥚","🍳","🧈","🥞","🧇","🥓","🥩","🍗","🍖","🌭","🍔","🍟","🍕","🥪","🥙","🧆","🌮","🌯","🥗","🥘","🍲","🍛","🍜","🍝","🍣","🍙","🍚","🍱","🥟","🍦","🍧","🍨","🍩","🍪","🎂","🍰","🧁","🥧","🍫","🍬","🍭","🍮","🍯","🍼","🥛","☕","🍵","🧃","🥤","🧋","🍺","🍻","🥂","🍷","🥃","🍸","🍹","🧉","🍾"]),
        ("⚽️", ["⚽️","🏀","🏈","⚾️","🥎","🎾","🏐","🏉","🥏","🎱","🏓","🏸","🥅","⛳️","🎣","🤿","🎽","🥊","🎿","🛷","🥌","⛸","🏆","🥇","🥈","🥉","🏅","🎖","🎪","🎭","🎨","🎬","🎤","🎧","🎼","🎹","🥁","🪘","🎷","🎺","🎸","🎻","🎲","♟","🎯","🎳","🎮","🎰","🧩"]),
        ("✈️", ["✈️","🚀","🛸","🚁","⛵️","🚤","🚢","🚂","🚄","🚅","🚇","🚌","🚑","🚒","🚓","🚕","🚗","🚙","🛻","🚲","🛴","🛹","⛽️","🚨","🚥","🚦","🛑","🚧","⚓️","🗺","🧭","⛰","🏔","🗻","🏕","🏖","🏜","🏝","🏞","🏟","🏛","🏗","🏠","🏡","🏢","🏥","🏦","🏨","🏪","🏫","🏬","🏭","🗼","🗽","⛪️","🕌","🛕","🕍","⛩","🕋","⛲️","🏙","🌁","🌃","🌄","🌅","🌆","🌇","🌉","🌌","🌠","🎇","🎆","🌈","🌊","🌀","⚡️","❄️","🔥","💧","🌍","🌎","🌏","🌙","🌚","🌛","🌜","🌝","🌞","⭐️","🌟","💫","✨","⛅️","🌧","⛈","🌩","🌨","🌪","🌫","🌬"]),
        ("💡", ["💡","🔦","🕯","🧱","🚪","🛋","🛏","🛁","🧴","🧷","🧹","🧺","🧻","🪣","🧼","🧽","🧯","🛒","💊","💉","🩺","🩻","🩹","🔪","⚔️","🛡","🔫","💣","💎","💍","👑","🎁","🎀","🎊","🎉","🎈","🧨","🎃","🎄","🧸","🖼","🎨","🖌","🧵","🧶","📦","📝","💼","📁","📋","📌","📍","📎","✂️","🔒","🔓","🔑","🗝","🔧","🔩","⚙️","🔗","🔮","🎲","🧩","📱","💻","⌨️","🖥","🖨","🖱","💾","💿","📀","📷","📸","📹","🎥","📽","🔭","🔬","📡","🔋","🔌","🔊","📣","📢","🔔","🔕","📻","🎶","🎵","🎼"]),
        ("❤️", ["❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞","💓","💗","💖","💘","💝","💟","☮️","✝️","☪️","🕉","☸️","✡️","☯️","🔱","⚜️","🔰","♻️","✅","❌","⭕️","🛑","⛔️","🚫","💯","💢","♨️","❗️","❕","❓","❔","‼️","⁉️","⚠️","🚸","🟥","🟧","🟨","🟩","🟦","🟪","⬛️","⬜️","🟫","🔈","🔇","🔉","🔊","🔔","🔕","💬","💭","🗯","♠️","♣️","♥️","♦️","🃏","🎴","🀄️","🎲","🆔","🆚","🆎","🆑","🅾️","🆘","🔞","🈶","🈚️","🈸","🈺","🈷️","🈴","🈵","🈹","🈲","🅰️","🅱️"])
    ]

    var body: some View {
        VStack(spacing: 0) {
            categoryTabs
            emojiGrid
            emojiBottomBar
        }
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            // Gapless tabs: the highlight is inset inside a full-height target.
            HStack(spacing: 0) {
                ForEach(Array(Self.categories.enumerated()), id: \.offset) { i, cat in
                    Text(cat.icon)
                        .font(.system(size: 20))
                        .frame(width: 40, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selectedCategory == i ? tokens.modifierOverlay : Color.clear)
                        )
                        .padding(.horizontal, 2)
                        .frame(height: 40)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedCategory = i }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 40)
    }

    private var emojiGrid: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 8)
        // Cells tile with no spacing so every point in the grid hits an emoji.
        // These stay on tap-release rather than touch-down: a touch-down gesture
        // would fire while the user is starting to scroll the grid.
        return ScrollView(showsIndicators: false) {
            LazyVGrid(columns: cols, spacing: 0) {
                ForEach(Self.categories[selectedCategory].emojis, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticEngine.shared.keyTap()
                            onInsert(emoji)
                        }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func modifierBg(_ cornerRadius: CGFloat) -> some View {
        KeyBlendBackground(cornerRadius: cornerRadius)
            .shadow(color: tokens.keyShadow, radius: tokens.keyShadowRadius, x: 0, y: 1)
    }

    private var emojiBottomBar: some View {
        HStack(spacing: 0) {
            PressableKey(hitInsets: KeyMetrics.insets(0, count: 4), onPress: { _ in
                HapticEngine.shared.keyTap()
                onBack()
            }) {
                Text("ABC")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierBg(keyRadius))
            }

            PressableKey(hitInsets: KeyMetrics.insets(1, count: 4), onPress: { _ in }) {
                Text("😊")
                    .font(.system(size: 20))
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(
                        KeyBlendBackground(cornerRadius: keyRadius)
                            .overlay(RoundedRectangle(cornerRadius: keyRadius).fill(tokens.modifierOverlay.opacity(3)))
                            .shadow(color: tokens.keyShadow, radius: tokens.keyShadowRadius, x: 0, y: 1)
                    )
            }

            PressableKey(hitInsets: KeyMetrics.insets(2, count: 4), onPress: { _ in
                HapticEngine.shared.spaceTap()
                onInsert(" ")
            }) {
                Text("space")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(maxWidth: .infinity, minHeight: rowH, maxHeight: rowH)
                    .background(modifierBg(keyRadius))
            }

            PressableKey(repeating: true,
                         hitInsets: KeyMetrics.insets(3, count: 4),
                         onPress: { isInitial in
                onDelete()
                if isInitial { HapticEngine.shared.deleteTap() }
            }) {
                Text("⌫")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(tokens.glyphColor)
                    .frame(width: specialKeyWidth, height: rowH)
                    .background(modifierBg(keyRadius))
            }
        }
        .frame(height: rowSlotH)
    }
}

// MARK: - KeyboardViewController

class KeyboardViewController: UIInputViewController {
    private let model = KeyboardViewModel()

    private let desiredKeyboardHeight = KeyMetrics.keyboardHeight
    private var heightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Without self-sizing the system pins the input view to the standard
        // keyboard height with a required-priority constraint. Our custom
        // height constraint then fights it on every layout pass and the
        // keyboard flickers between the two heights when switched to.
        inputView?.allowsSelfSizing = true
        view.backgroundColor = .clear
        view.isOpaque = false
        wireModel()
        embedKeyboardView()
    }

    override func updateViewConstraints() {
        super.updateViewConstraints()
        // Wait until the view is in the hierarchy with real geometry —
        // activating the constraint against a zero frame breaks the system's
        // encapsulated-layout constraints and flashes during the transition.
        guard view.frame.width != 0, view.frame.height != 0 else { return }
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
        // Re-request a constraints pass now that the view has its real frame,
        // so the guarded height constraint in updateViewConstraints() lands.
        view.setNeedsUpdateConstraints()
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
