import Foundation
import CoreGraphics

struct KeyModel: Identifiable {
    let id    = UUID()
    let base:    String
    let shifted: String
    let type:    KeyType
    let width:   KeyWidth
}

enum KeyType {
    case letter, modifier, backspace, tab,
         capsLock, returnKey, shift, media
}

enum KeyWidth {
    case standard   // 56pt — letter keys
    case wide       // 84pt — Tab, CapsLock, Backspace
    case wider      // 100pt — Shift left/right
    case returnKey  // 56pt wide, 96pt tall (spans rows 2–3)

    var pts: CGFloat {
        switch self {
        case .standard:  return 56
        case .wide:      return 84
        case .wider:     return 100
        case .returnKey: return 56
        }
    }
}

enum KeyboardLayout {
    static let rows: [[KeyModel]] = [row0, row1, row2, row3, row4]

    // MARK: Row 0 — media / function bar

    private static let row0: [KeyModel] = [
        .init(base: "esc",                  shifted: "esc",                  type: .modifier, width: .wide),
        .init(base: "sun.min",              shifted: "sun.min",              type: .media,    width: .standard),
        .init(base: "sun.max",              shifted: "sun.max",              type: .media,    width: .standard),
        .init(base: "square.grid.3x2",      shifted: "square.grid.3x2",      type: .media,    width: .standard),
        .init(base: "magnifyingglass",       shifted: "magnifyingglass",       type: .media,    width: .standard),
        .init(base: "keyboard.badge.eye",   shifted: "keyboard.badge.eye",   type: .media,    width: .standard),
        .init(base: "keyboard",             shifted: "keyboard",             type: .media,    width: .standard),
        .init(base: "backward.fill",        shifted: "backward.fill",        type: .media,    width: .standard),
        .init(base: "playpause.fill",       shifted: "playpause.fill",       type: .media,    width: .standard),
        .init(base: "forward.fill",         shifted: "forward.fill",         type: .media,    width: .standard),
        .init(base: "speaker.slash.fill",   shifted: "speaker.slash.fill",   type: .media,    width: .standard),
        .init(base: "speaker.wave.1.fill",  shifted: "speaker.wave.1.fill",  type: .media,    width: .standard),
        .init(base: "speaker.wave.3.fill",  shifted: "speaker.wave.3.fill",  type: .media,    width: .standard),
    ]

    // MARK: Row 1

    private static let row1: [KeyModel] = [
        .init(base: "է",  shifted: "Է",  type: .letter,    width: .standard),
        .init(base: "թ",  shifted: "Թ",  type: .letter,    width: .standard),
        .init(base: "փ",  shifted: "Փ",  type: .letter,    width: .standard),
        .init(base: "ձ",  shifted: "Ձ",  type: .letter,    width: .standard),
        .init(base: "ջ",  shifted: "Ջ",  type: .letter,    width: .standard),
        .init(base: "ւ",  shifted: "Ւ",  type: .letter,    width: .standard),
        .init(base: "և",  shifted: "Ե",  type: .letter,    width: .standard),
        .init(base: "ր",  shifted: "Վ",  type: .letter,    width: .standard),
        .init(base: "չ",  shifted: "Ր",  type: .letter,    width: .standard),
        .init(base: "ճ",  shifted: "Չ",  type: .letter,    width: .standard),
        .init(base: "ժ",  shifted: "Ժ",  type: .letter,    width: .standard),
    ]

    // MARK: Row 2

    private static let row2: [KeyModel] = [
        .init(base: "ք",  shifted: "Ք",  type: .letter,    width: .standard),
        .init(base: "ո",  shifted: "Ո",  type: .letter,    width: .standard),
        .init(base: "ե",  shifted: "Ե",  type: .letter,    width: .standard),
        .init(base: "ռ",  shifted: "Ռ",  type: .letter,    width: .standard),
        .init(base: "տ",  shifted: "Տ",  type: .letter,    width: .standard),
        .init(base: "ը",  shifted: "Ը",  type: .letter,    width: .standard),
        .init(base: "ի",  shifted: "Ի",  type: .letter,    width: .standard),
        .init(base: "օ",  shifted: "Օ",  type: .letter,    width: .standard),
        .init(base: "պ",  shifted: "Պ",  type: .letter,    width: .standard),
        .init(base: "խ",  shifted: "Խ",  type: .letter,    width: .standard),
        .init(base: "ծ",  shifted: "Ծ",  type: .letter,    width: .standard),
    ]

    // MARK: Row 3

    private static let row3: [KeyModel] = [
        .init(base: "ա",  shifted: "Ա",  type: .letter,   width: .standard),
        .init(base: "ս",  shifted: "Ս",  type: .letter,   width: .standard),
        .init(base: "դ",  shifted: "Դ",  type: .letter,   width: .standard),
        .init(base: "ֆ",  shifted: "Ֆ",  type: .letter,   width: .standard),
        .init(base: "գ",  shifted: "Գ",  type: .letter,   width: .standard),
        .init(base: "հ",  shifted: "Հ",  type: .letter,   width: .standard),
        .init(base: "յ",  shifted: "Յ",  type: .letter,   width: .standard),
        .init(base: "կ",  shifted: "Կ",  type: .letter,   width: .standard),
        .init(base: "լ",  shifted: "Լ",  type: .letter,    width: .standard),
        .init(base: "շ",  shifted: "Շ",  type: .letter,    width: .standard),
    ]

    // MARK: Row 4

    private static let row4: [KeyModel] = [
        .init(base: "⇧",  shifted: "⇧",  type: .shift,  width: .wider),
        .init(base: "զ",  shifted: "Զ",  type: .letter, width: .standard),
        .init(base: "ղ",  shifted: "Ղ",  type: .letter, width: .standard),
        .init(base: "ց",  shifted: "Ց",  type: .letter, width: .standard),
        .init(base: "վ",  shifted: "Վ",  type: .letter, width: .standard),
        .init(base: "բ",  shifted: "Բ",  type: .letter, width: .standard),
        .init(base: "ն",  shifted: "Ն",  type: .letter, width: .standard),
        .init(base: "մ",  shifted: "Մ",  type: .letter,    width: .standard),
        .init(base: "⌫",  shifted: "⌫",  type: .backspace, width: .standard),
    ]
}
