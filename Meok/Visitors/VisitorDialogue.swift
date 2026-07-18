import SwiftUI
import GameKernel

/// Hand-authored visitor dialogue (spec §2: a few exchanges deep, EN + KO).
/// Lines are LocalizedStringKeys — the KO is in Localizable.xcstrings. The
/// roster and its dialogue grow post-launch.
enum VisitorDialogue {
    static func displayName(for visitor: Visitor) -> String {
        Locale.current.language.languageCode?.identifier == "ko" ? visitor.nameKO : visitor.nameEN
    }

    /// A greeting and a line of lore, in order.
    static func lines(for visitor: VisitorID) -> [LocalizedStringKey] {
        switch visitor {
        case .oldFisherman:
            ["Ah — you fish these waters too.",
             "The rain wakes the eels. Patience is the only bait that never runs out."]
        case .dokkaebi:
            ["Heh. A mortal, out in my storm?",
             "Odd goods for odd prices. Blink, and I'm gone with the thunder."]
        case .peddler:
            ["Wares from far skies, traveler.",
             "Things your weather never grows — I carry them all. I pass this way but seldom."]
        }
    }
}
