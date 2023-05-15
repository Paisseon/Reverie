import Jinx

private let prefs: JinxPreferences = .init(for: "lilliana.reverie")

struct Preferences {
    static let canFastCharge: Bool = prefs.get(for: "canFastCharge", default: true)
    static let isEnabled: Bool     = prefs.get(for: "isEnabled",     default: true)
    static let sleepLevel: Int     = prefs.get(for: "sleepLevel",    default: 7)
    static let wakeLevel: Int      = prefs.get(for: "wakeLevel",     default: 20)
}
