//
//  PlatformSemantics.swift
//  DesignScaffold
//
//  The one file that knows there is more than one platform.
//

import SwiftUI

#if canImport(AppKit)
import AppKit
/// The platform's colour type. Aliased so nothing else in the package needs to know.
public typealias PlatformColor = NSColor
#elseif canImport(UIKit)
import UIKit
public typealias PlatformColor = UIColor
#endif

/// The system semantic colours the tokens are built on, resolved per platform.
///
/// ## Why this file exists, and why it is the ONLY one with a `#if` in it
///
/// The token layer's whole thesis is that a value should come from the platform semantic
/// wherever the semantic provably equals the design value — that is what makes light mode,
/// Increase Contrast and the user's accent work for free. Semantics are exactly the thing
/// that is named differently on each platform, so the divergence is real and has to live
/// somewhere. It lives here, once, and `Tokens.swift` stays platform-free.
///
/// ## ⚠️ Three of these are a LOOKUP. Three are a DESIGN DECISION.
///
/// The label and separator semantics are the same concept on both platforms and map
/// one-to-one. The **surfaces do not**: macOS layers window → control → text backgrounds,
/// while iOS layers a three-tier `systemBackground` family plus a separate `systemFill`
/// family for control interiors. There is no mechanical correspondence, so these were
/// mapped by the ROLE each token documents, not by name similarity:
///
/// | token | role, per its doc comment | macOS | iOS |
/// |---|---|---|---|
/// | `surface` | "panel/card fill on top of a window material" | `controlBackground` | `secondarySystemBackground` |
/// | `surfaceElevated` | "subtler fill for nested content" | `windowBackground` | `tertiarySystemBackground` |
/// | `fieldFill` | the fill Apple's own text fields use | `textBackground` | `tertiarySystemFill` |
///
/// `tertiarySystemFill` rather than a background tier because Apple documents the *fill*
/// family for control interiors specifically — "large shapes such as input fields, search
/// bars, or buttons" — which is what `fieldFill` is for.
///
/// **These three want an eyeball on a device before anyone calls them settled.** They are a
/// defensible reading of two different design systems, not a fact.
enum PlatformSemantics {

    static var tertiaryLabel: SwiftUI.Color {
        #if canImport(AppKit)
        SwiftUI.Color(nsColor: .tertiaryLabelColor)
        #else
        SwiftUI.Color(uiColor: .tertiaryLabel)
        #endif
    }

    static var quaternaryLabel: SwiftUI.Color {
        #if canImport(AppKit)
        SwiftUI.Color(nsColor: .quaternaryLabelColor)
        #else
        SwiftUI.Color(uiColor: .quaternaryLabel)
        #endif
    }

    static var separator: SwiftUI.Color {
        #if canImport(AppKit)
        SwiftUI.Color(nsColor: .separatorColor)
        #else
        SwiftUI.Color(uiColor: .separator)
        #endif
    }

    static var fieldFill: SwiftUI.Color {
        #if canImport(AppKit)
        SwiftUI.Color(nsColor: .textBackgroundColor)
        #else
        SwiftUI.Color(uiColor: .tertiarySystemFill)
        #endif
    }

    static var surface: SwiftUI.Color {
        #if canImport(AppKit)
        SwiftUI.Color(nsColor: .controlBackgroundColor)
        #else
        SwiftUI.Color(uiColor: .secondarySystemBackground)
        #endif
    }

    static var surfaceElevated: SwiftUI.Color {
        #if canImport(AppKit)
        SwiftUI.Color(nsColor: .windowBackgroundColor)
        #else
        SwiftUI.Color(uiColor: .tertiarySystemBackground)
        #endif
    }
}
