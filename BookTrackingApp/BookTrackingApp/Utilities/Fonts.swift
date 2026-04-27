import SwiftUI
import CoreText

enum AppFonts {
    static let playfairFamily = "Playfair Display"
    static let dmSansFamily = "DM Sans"

    static func registerBundledFonts() {
        let fileNames = [
            "PlayfairDisplay-Regular",
            "PlayfairDisplay-Italic",
            "DMSans-Regular",
            "DMSans-Italic",
        ]
        for name in fileNames {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
    }
}

extension Font {
    static func playfair(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom(AppFonts.playfairFamily, size: size).weight(weight)
    }

    static func playfairItalic(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("\(AppFonts.playfairFamily) Italic", size: size).weight(weight)
    }

    static func dmSans(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(AppFonts.dmSansFamily, size: size).weight(weight)
    }
}
