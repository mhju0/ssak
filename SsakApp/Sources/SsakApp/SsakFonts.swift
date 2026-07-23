import SwiftUI
import CoreText

/// Round 3 (spec D10): Nanum Myeongjo (SIL OFL, license alongside the files) bundled as
/// package resources and registered through CoreText — no Info.plist dependency, so the
/// same path works in the app, the render harness, and tests on macOS. If registration
/// or lookup fails, `Font.custom` falls back to the system face; layout never breaks.
public enum SsakFonts {
    static let displayKO = "NanumMyeongjoExtraBold"
    static let serifKO = "NanumMyeongjo"

    private static let registerOnce: Void = {
        for file in ["NanumMyeongjo-Regular", "NanumMyeongjo-ExtraBold"] {
            if let url = Bundle.module.url(forResource: file, withExtension: "ttf",
                                           subdirectory: "Fonts") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }()

    public static func register() { _ = registerOnce }
}

public extension Font {
    /// The 압화집 display face (KO-first name lines, spec D1).
    static func myeongjoDisplay(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(SsakFonts.displayKO, size: size, relativeTo: style)
    }
    /// The album's book face (labels, captions).
    static func myeongjo(_ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(SsakFonts.serifKO, size: size, relativeTo: style)
    }
}
