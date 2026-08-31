# Platforms

`platforms: [.macOS(.v26), .iOS(.v16)]` — iOS added 2026-08-31 for MarqueeSurface (AB-A-0042),
the fleet's first iOS consumer.

Everything below was found by **compiling for `generic/platform=iOS`**, one scheme at a time,
not by reading availability tables.

---

## ⚠️ Compiling is not belonging

Twelve of fifteen products compile for iOS. That is a much weaker statement than "twelve
products are cross-platform", and conflating the two is how a design system ships a 24pt tap
target to a phone.

---

## The tokens are NOT uniformly portable

**Colour — portable.** All six system-semantic bridges live in one file,
`PlatformSemantics.swift`, and it is the only `#if` in the package.

⚠️ **Three of the six are a lookup; three are a design decision.** `tertiaryLabel`,
`quaternaryLabel` and `separator` are the same concept on both platforms. The **surfaces are
not**: macOS layers window → control → text backgrounds, while iOS has a three-tier
`systemBackground` family *plus* a separate `systemFill` family for control interiors. There
is no mechanical correspondence, so `surface` / `surfaceElevated` / `fieldFill` were mapped by
the role each token's own doc comment states. **They want an eyeball on a device before
anyone calls them settled.**

**Type, Space, Radius, Motion — portable as written.**

### ⚠️ `Layout` does not port, and this is the important one

| token | value | on iOS |
|---|---|---|
| `controlHeight` | 24 | **below the 44pt minimum tap target** |
| `rowHeight` | 42 | **below 44pt** |
| `inspectorWidth` | 340 | 87% of an iPhone 15's width |
| `sidebarWidth` | 260 | a desktop split-view concept |
| `minWindowWidth` / `minWindowHeight` | 1080 / 720 | meaningless without windows |

These came from the Figma macOS kit and are correct **for macOS**. Nothing stops an iOS app
importing them, and nothing warns it either. **An iOS consumer must not reach for the geometry
tokens without deciding what they mean on touch** — that is a design question this package has
not answered yet, and pretending otherwise would be worse than leaving it open.

---

## Products, in three tiers

### Tier 1 — portable, no reservations

`DesignScaffold` (Tokens · `cardSurface()` · `Separator` · `SectionHeader` · `Pulse`),
`Status`, `Metrics`, `Waveform`, `StageStepper`, `Loading`.

Presentation only. No pointer interaction, no hit targets, nothing whose meaning changes on
touch. **These are the ones an iOS app can adopt today.**

### Tier 2 — compiles, but the interaction model needs a decision first

`Controls`, `Chips`, `Picker`, `Calendar`, `Playlist`, `Workspace`.

They build. What is unresolved is whether they are *right*:

- **`Controls`, `Chips`, `Picker`, `Calendar`** all size their hit areas from
  `Tokens.Layout.controlHeight` (24) or similar. On touch that is roughly half the minimum.
  They need an iOS theme, not a recompile.
- **`Playlist`** drag-reorders. On macOS a drag begins immediately; on touch it begins after a
  long press, and the affordance for "this is draggable" is different. Same code, different
  idiom.
- **`Workspace`** is a three-pane desktop shell. Plausible on iPad, wrong on iPhone.

**Marked unverified rather than supported** until they have been driven on a device. Building
is not seeing — that distinction has cost this package a shipped bug already (`Pulse`,
AB-L-0077).

### Tier 3 — macOS-only, and should stay so

`Timeline`, `Probe`, `Media`. Wrapped in `#if os(macOS)`, so they compile to nothing on iOS
and the package as a whole still builds.

- **`Timeline`** — `NSCursor`, `NSEvent`, `NSViewRepresentable`, `onHover`, `contextMenu`. A
  precision pointer surface. A touch timeline is a different component, not a port.
- **`Probe`** — a diagnostic reading `NSApp` / `NSScreen`. No iOS need.
- **`Media`** — `NSOpenPanel` / `NSImage`. iOS wants `fileImporter` or `PhotosPicker`; that is
  a rewrite behind the same API, and worth doing only when something asks.

---

## The floor, and what "verified" means here

**iOS 16.** Set by shipping code, found by compiling:

| API | floor | where |
|---|---|---|
| `ProposedViewSize` (custom `Layout`) | 16 | `Chips` |
| `Grid` / `GridRow` | 16 | `Calendar` |
| `tracking`, `contentTransition` | 16 | `Loading` |
| `Color(uiColor:)` | 15 | core |

Two things were **kept out of the floor** rather than allowed to raise it:

- `@Previewable` (iOS 17) is development-only, so the five preview files are `#if os(macOS)`.
  A preview macro should not set the floor for every consumer.
- `.numericText(value:)` (iOS 17) is one rolling-digit animation on the loading percentage.
  Gated behind `#available`; below the floor the number changes without rolling.

⚠️ **You cannot verify a floor below 15 on this toolchain.** Declaring `.iOS(.v13)` still
compiled — the iOS 27 SDK clamps the deployment target and the build ran at
`-target arm64-apple-ios15.0` regardless of the manifest. A lower declaration is silently
ignored, not honoured. The core is clean at 15 and the floor can drop there if a consumer ever
needs it; anything below that is unverifiable here and should not be claimed.

---

## Adding a platform-specific value

Put it in `PlatformSemantics.swift`. That file exists so the rest of the package never needs
to know there is more than one platform, and so the divergence is reviewable in one place
rather than scattered through `#if`s.
