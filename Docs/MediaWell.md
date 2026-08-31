# Media Well

A drop target that also opens a file panel when clicked, and shows what it is holding.

```swift
import DesignScaffoldMedia

MediaWell("Drop an image, or click to choose", isEmpty: image == nil) { urls in
    load(urls[0])
} content: {
    Image(nsImage: image!).resizable().scaledToFit()
}

MediaWell("Audio only", systemImage: "waveform", allowing: [.audio]) { urls in
    import(urls[0])
} onReject: { urls in
    status = "\(urls.count) file(s) are not audio"
}
```

## Promoted from six copies

| where | height | targeted state | click to browse |
|---|---|---|---|
| BiRefNet Demo `DemoContentView.swift` | 150 | ✔ | — |
| Mage Demo `ContentView.swift` | 180 | ✔ | ✔ |
| Qwen Image Demo `UI/ContentView.swift` | — | ✔ | ✔ |
| MLX MageVL Demo `UI/ImageTab.swift` | — | — | ✔ |
| Trellis2 Demo `UI/InputPanel.swift` | 260 | ✔ | ✔ |
| SenseNova-U1.5 Demo `UI/Components.swift` | — | — | ✔ (multi) |

## ⚠️ A claim I made about these, and had to retract

I first reported that Qwen Image's decoder was **broken** — that it read the `.fileURL` data
representation as a UTF-8 string and passed it to `URL(string:)`, which "returns nil for any
path containing a space". I asserted that from reading the code.

**It is false.** The `.fileURL` representation is already a percent-encoded `file://`
absolute string, not a raw POSIX path, so `URL(string:)` is the correct API for it and a
spaced path round-trips fine. Measuring it took four minutes and would have saved a wrong
claim reaching a commit message, a doc comment and a test control.

The only decoder finding that survived is dull: Mage's `loadItem(forTypeIdentifier:)` is
deprecated as of macOS 27.

## What is actually wrong with the six

**None of them validated anything.** Whatever was dropped went straight to the loader. A
`.txt` on an image well returns nil from `NSImage(contentsOf:)`, falls through a bare
`else { return }`, and **nothing happens at all** — no image, no message, no sign the app
noticed the drop.

**`NSOpenPanel.allowedContentTypes` is an affordance, not a guarantee.** Measured in the
Component Lab rather than assumed: a panel restricted to `[.audio]` still returned a PNG,
because ⌘⇧G (Go to Folder) with an explicit path bypasses the type filter and enables
**Open**. Every copy trusted the panel on the browse path and checked nothing on the drop
path, so all six would have handed that PNG to an audio loader.

`MediaWell` routes **both** paths through one gate — `MediaAcceptance.partition` — which is
why the panel's leak was caught at all.

**Half drew no drag-over state**, so dragging over those wells gave no feedback until you
let go.

## The decode is removed rather than reimplemented

`.dropDestination(for: URL.self)` hands over decoded URLs. There is no parsing to get
wrong — not one correct implementation of it, but none. That also retires the
macOS-27-deprecated call.

## Acceptance reads the file, not the extension

`MediaAcceptance.contentType(of:)` uses `URLResourceValues.contentType`, falling back to the
path extension only when that fails. `UTType(filenameExtension:)` alone is a table lookup
that knows nothing about the file in front of it: it answers confidently for a `.png` that
is really a renamed PDF, and answers nothing for an extensionless file the system types
correctly.

Matching is by **conformance**, not equality — a PNG is not `UTType.image`, it conforms to
it, and `==` would reject every real file.

## Themes

`.scaffold` (180pt, the median of the six), `.tall` (260, Trellis2's hero panel),
`.compact` (150, BiRefNet's thumbnail). Height, symbol and prompt were the three things the
copies disagreed on and none of the disagreements meant anything.
