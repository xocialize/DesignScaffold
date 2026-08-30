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
        // The design vocabulary itself: Tokens (colour · type · spacing · radii · layout)
        // + cardSurface(). Zero dependencies; every component product re-exports it.
        .library(name: "DesignScaffold", targets: ["DesignScaffold"]),
        // Month calendar (single/multiple/range selection) in the scaffold house style.
        .library(name: "DesignScaffoldCalendar", targets: ["DesignScaffoldCalendar"]),
        // Sortable playlist list (thumbnail · name · metadata, drag-reorder, active marker).
        .library(name: "DesignScaffoldPlaylist", targets: ["DesignScaffoldPlaylist"]),
        // Model/product loading modal (hero percentage · status · detail fields · bar).
        .library(name: "DesignScaffoldLoading", targets: ["DesignScaffoldLoading"]),
        // Run-progress stepper for multi-phase operations (planned nodes · pulse · counters).
        .library(name: "DesignScaffoldStageStepper", targets: ["DesignScaffoldStageStepper"]),
        // Media-agnostic multi-track timeline (ruler · headers · clip lanes · playhead).
        .library(name: "DesignScaffoldTimeline", targets: ["DesignScaffoldTimeline"]),
        // Capsule filter chips, single-select, wrapping.
        .library(name: "DesignScaffoldChips", targets: ["DesignScaffoldChips"]),
        // Three-panel app shell (navigation rail · work area · inspector) with hairlines.
        .library(name: "DesignScaffoldWorkspace", targets: ["DesignScaffoldWorkspace"]),
        // Opt-in pointer gate: report where a view DREW, and what a gesture actually did.
        .library(name: "DesignScaffoldProbe", targets: ["DesignScaffoldProbe"]),
        // Findable selection list for large libraries (search · tag scoping · sort · multi-select).
        .library(name: "DesignScaffoldPicker", targets: ["DesignScaffoldPicker"]),
        // Status pill: a dot, a label, a capsule — idle · working · ready · failed.
        .library(name: "DesignScaffoldStatus", targets: ["DesignScaffoldStatus"]),
        // Audio waveform: a live input level meter and a track visualiser, one Canvas renderer.
        .library(name: "DesignScaffoldWaveform", targets: ["DesignScaffoldWaveform"]),
        // Metric tile and grid: one headline measurement — value · unit · label · caption.
        .library(name: "DesignScaffoldMetrics", targets: ["DesignScaffoldMetrics"]),
        // Labeled form controls: a parameter slider with a live readout.
        //
        // Named for the topic rather than for `LabeledSlider` alone, matching how the other
        // products are scoped (Status holds Status + StatusFormat + StatusPill; Waveform
        // holds three views and a bucketer). A labeled toggle and a labeled stepper are the
        // obvious neighbours if the evidence for them ever arrives — and this way they do
        // not force a product rename, which would break every adopter's import.
        .library(name: "DesignScaffoldControls", targets: ["DesignScaffoldControls"]),
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
        .target(
            name: "DesignScaffoldLoading",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldLoading"
        ),
        .target(
            name: "DesignScaffoldStageStepper",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldStageStepper"
        ),
        .target(
            name: "DesignScaffoldTimeline",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldTimeline"
        ),
        .testTarget(
            name: "DesignScaffoldCalendarTests",
            dependencies: ["DesignScaffoldCalendar"]
        ),
        .testTarget(
            name: "DesignScaffoldLoadingTests",
            dependencies: ["DesignScaffoldLoading"]
        ),
        .testTarget(
            name: "DesignScaffoldStageStepperTests",
            dependencies: ["DesignScaffoldStageStepper"]
        ),
        .target(
            name: "DesignScaffoldMetrics",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldMetrics"
        ),
        .target(
            name: "DesignScaffoldWaveform",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldWaveform"
        ),
        .target(
            name: "DesignScaffoldStatus",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldStatus"
        ),
        .target(
            name: "DesignScaffoldPicker",
            dependencies: ["DesignScaffold", "DesignScaffoldChips"],
            path: "Sources/DesignScaffoldPicker"
        ),
        .target(
            name: "DesignScaffoldProbe",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldProbe"
        ),
        .target(
            name: "DesignScaffoldWorkspace",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldWorkspace"
        ),
        .target(
            name: "DesignScaffoldChips",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldChips"
        ),
        .testTarget(
            name: "DesignScaffoldTimelineTests",
            dependencies: ["DesignScaffoldTimeline"]
        ),
        .testTarget(
            name: "DesignScaffoldTests",
            dependencies: ["DesignScaffold"],
            path: "Tests/DesignScaffoldTests"
        ),
        .testTarget(
            name: "DesignScaffoldWaveformTests",
            dependencies: ["DesignScaffoldWaveform"],
            path: "Tests/DesignScaffoldWaveformTests"
        ),
        .testTarget(
            name: "DesignScaffoldStatusTests",
            dependencies: ["DesignScaffoldStatus"],
            path: "Tests/DesignScaffoldStatusTests"
        ),
        .testTarget(
            name: "DesignScaffoldPickerTests",
            dependencies: ["DesignScaffoldPicker"],
            path: "Tests/DesignScaffoldPickerTests"
        ),
        .testTarget(
            name: "DesignScaffoldWorkspaceTests",
            dependencies: ["DesignScaffoldWorkspace"],
            path: "Tests/DesignScaffoldWorkspaceTests"
        ),
        .target(
            name: "DesignScaffoldControls",
            dependencies: ["DesignScaffold"],
            path: "Sources/DesignScaffoldControls"
        ),
        .testTarget(
            name: "DesignScaffoldControlsTests",
            dependencies: ["DesignScaffoldControls"],
            path: "Tests/DesignScaffoldControlsTests"
        ),
        .testTarget(
            name: "DesignScaffoldChipsTests",
            dependencies: ["DesignScaffoldChips"]
        ),
        .testTarget(
            name: "DesignScaffoldPlaylistTests",
            dependencies: ["DesignScaffoldPlaylist"]
        ),
    ]
)
