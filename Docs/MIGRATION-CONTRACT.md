# Migrating a demo app onto DesignScaffold

The instruction set for a single-app migration. Every rule here was paid for by one of the
first three — Liquid LFM 2.5, Gepard, Moebius — and most of them are things a fresh session
would not think to check.

**Read this whole file before editing anything.** Half of it is about what to do *before*
the migration.

---

## 0. Before you touch a file: check the repository

⚠️ **This has found something in two of the first three apps.** The move is riskier than the
migration, and a migration rewrites every view file.

```bash
git -C "<app>" log --oneline -3
git -C "<app>" status --short
echo "tracked: $(git -C "<app>" ls-tree -r --name-only HEAD | grep -c '\.swift$')"
echo "on disk: $(find "<app>" -name '*.swift' -not -path '*/.git/*' | wc -l)"
```

- **Tracked count far below on-disk count** → the app is largely uncommitted. *Gepard's only
  commit was the empty Xcode template; all 16 Swift files and ~2 400 lines were untracked.*
  **Commit a labelled baseline first.** Do not push it — publishing someone's work is their
  call.
- **`fatal: not a git repository`** → the move orphaned the repo. *Moebius's root was the
  wrapper directory; moving the app up a level left `.git` behind with an empty tree and
  three commits stranded.* Copy (do not move) `.git` and `.gitignore` to the new root, then
  `git add -A` and confirm git reports **renames, not deletions**, before committing.
- **No `.gitignore`** → copy a sibling demo's.

---

## 1. Tokens

### Apps on `MarqueeColor` / `MarqueeFont` / `MarqueeMetric`

These are **already deprecated forwarders onto `Tokens`** (AB-A-0019). Do not re-derive the
mapping — **read it off the `@available(*, deprecated, message:)` text** in
`MLXEngine/mlx-engine-swift/Sources/MLXEngineUI/MarqueeTokens.swift`. It is authoritative and
it explains the deliberate value changes.

⚠️ **`bgElevated` is a split symbol.** Divider uses → `Tokens.Color.separator`; fill uses →
`Tokens.Color.fillElevated`. Decide per site; forwarding both to one token re-creates the
conflation the split exists to end.

⚠️ **When two symbols map to the same token, check co-occurrence before renaming.**
`accentGold` and `accentBlue` both become `Tokens.Color.accent`, and they appeared together
in three of Liquid LFM's files. Read those sites: the resolution is almost always **rule 2**,
not a second colour.

### Apps with a vendored `enum Tokens`

Diff the fork's *declarations* against the package's before deleting — do not trust a shape
match. Moebius: 60 of 67 byte-identical, none different, 7 fork-only. That turns "should be
fine" into "unchanged by construction", and it takes a minute.

Fork-only symbols that are **not design vocabulary** (iconography, domain thresholds) move to
an app-local `extension Tokens.Symbol` / `extension Tokens` so every call site compiles
verbatim.

### Apps with no vocabulary at all (bare `.system(size:)`)

The hardest class — there is nothing to map *from*, so every value is a judgement call.

- **Snap to the token scale. Do not add tokens to preserve legacy values.** `cornerRadius: 8`
  is the fleet's most-reached-for radius (33 uses, 12 app directories) and still should not
  become a token: the scale is a deliberate 6/12/14, and a value being popular in legacy code
  is not evidence the scale is wrong.
- **A brand palette usually carries semantics.** Read every call site before calling it
  decoration. Gepard's cheetah palette looked like pure branding; `red` meant **failure**,
  `green` meant **ready**, the yellow wash meant **needs action**, `orange` was the **control
  tint**. Those are status tokens, and saying them in brand colours meant they could not
  follow the user's appearance or accent.
- **SF Symbol point sizes and logotypes are NOT type tokens.** Glyph geometry is not a text
  style. Name them in an app-local theme so no view carries a bare literal, and do not add
  icon-size tokens to the authority on one app's evidence.

---

## 2. `.tint(<the accent>)` on a standard control is a no-op — delete it

`.borderedProminent` buttons, `.switch` toggles, `Slider` and `ProgressView` all draw with
the accent already. These calls exist only because the brand colour was a **pinned** value
that had to be re-applied; once it resolves to the user's accent, restating it says nothing.

**12 removed across the first two apps**, and deleting them is what resolves the
gold-vs-blue collision in rule 1.

---

## 3. Components: adopt, never re-implement

Check `Docs/COMPONENTS.md` **before** writing any view. Current products:
`DesignScaffold` (tokens · `cardSurface()` · `Separator` · `SectionHeader` · `Pulse`),
`Calendar`, `Playlist`, `Loading`, `StageStepper`, `Timeline`, `Chips`, `Workspace`, `Probe`,
`Picker`, `Status`, `Waveform`, `Metrics`, `Controls`, `Media`.

⚠️ **Hand-written `Binding<Double>` wrappers around `Int` truncate.** Five apps wrote one;
**four used `Int($0)` and were wrong**. Truncation loses a whole unit at the top of a drag and
hides whenever the step grid lands on integers. Use `LabeledSlider`'s `Int` initializer,
which rounds and clamps. A `CGFloat` bridge is lossless — comment it so it does not read like
the others.

⚠️ **`SectionHeader` uppercases as a display transform.** Pass titles in **sentence case**.
Passing `"DEVELOPER SETTINGS"` defeats the point: VoiceOver reads the string as written, and
an uppercased one gets spelled out letter by letter.

**If something is missing, file a bridge ask. Never vendor.** One agent vendoring a
"temporary" copy is how AB-A-0033 happened, and it outlived its reason by three weeks.

---

## 4. Verify

1. **Build.** For a Marquee app the completeness test is **zero deprecation warnings** — the
   compiler enumerates every remaining forwarder. That is mechanical and unfakeable; a grep
   is neither.
2. **Run it and look.** A build is not a render. Gepard's readout said `1,075` beside a caption
   saying `1075`, and only looking caught it.
3. **Kill stale instances with `pkill -9`** and check the binary's mtime before believing a
   screenshot.

---

## 5. Two habits that are not optional

**Do not assert a mechanism from reading source.** I claimed Qwen Image's drop decoder was
broken on paths with spaces, from reading it. It is not — the `.fileURL` representation is
already a percent-encoded `file://` string. Measuring took four minutes; the wrong claim had
already reached a commit message, a doc comment and a test control. **If you are about to
describe a defect in code you have not run, run it.**

**An instrument that cannot fail is not evidence.** `StatusPill` shipped a bug where the dot
detached from its pill and slid around the window, while the Component Lab was green — every
case held the pill still, so the one axis the bug lived on was the one axis nothing moved.
When you add a case, ask what it *cannot* see and write that down.

---

## Definition of done

- [ ] Baseline commit if the tree needed one; repository intact at the new path
- [ ] Zero `Marquee*` references and zero deprecation warnings, **or** the vendored fork
      deleted after a declaration diff
- [ ] No bare colour / font / spacing / radius literal in any view
- [ ] Components adopted from the catalog; nothing vendored; asks filed for real gaps
- [ ] `BUILD SUCCEEDED`, and the app **driven** with a screenshot of the migrated surface
- [ ] `Tools/scan-adopters.py` shows the app at the current tag with the products it uses
- [ ] Commit message says what changed **visually**, not just structurally
