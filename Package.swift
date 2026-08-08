// swift-tools-version: 6.2
// DesignScaffold — the shared macOS design vocabulary for the fleet's demo/harness apps.
//
// Exists because the token layer is NOT app-specific: it is Apple's macOS 26/27 UI kit,
// extracted once from Figma (`Demo Apps`, LGwpgABHRfxj47V8uCmkwK) and reused. Before this,
// each demo app re-derived spacing/radii/type by eye and drifted from the others.
//
// PRODUCT POLICY: self-contained, zero external dependencies (SwiftUI only), so any app
// can adopt it without pulling in MLXEngine, a model package, or anything else. Components
// are VENDORED into this package — each as its own target and selectable library product,
// its look resolved through the `DesignScaffold` tokens — so an adopter links only what it
// uses and the package never grows a dependency graph. (The calendar was absorbed from
// SwiftCalendarKit, now deprecated in favour of this copy; future components follow the
// same pattern.)

import PackageDescription

let package = Package(
    name: "DesignScaffold",
    platforms: [.macOS(.v26)],
    products: [
        // Tokens only.
        .library(name: "DesignScaffold", targets: ["DesignScaffold"]),
        // Month calendar (single/multiple/range selection) in the scaffold house style.
        .library(name: "DesignScaffoldCalendar", targets: ["DesignScaffoldCalendar"]),
        // Sortable playlist list (thumbnail · name · metadata, drag-reorder, active marker).
        .library(name: "DesignScaffoldPlaylist", targets: ["DesignScaffoldPlaylist"]),
    ],
    targets: [
        .target(name: "DesignScaffold", path: "Sources/DesignScaffold"),
        .target(
            name: "DesignScaffoldCalendar",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldCalendar"
        ),
        .target(
            name: "DesignScaffoldPlaylist",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldPlaylist"
        ),
        .testTarget(
            name: "DesignScaffoldCalendarTests",
            dependencies: ["DesignScaffoldCalendar"]
        ),
        .testTarget(
            name: "DesignScaffoldPlaylistTests",
            dependencies: ["DesignScaffoldPlaylist"]
        ),
    ]
)
