#!/usr/bin/env python3
"""Generate Docs/COMPONENTS.md — the fleet's canonical component catalog.

Derived, never hand-written: the product list and its one-line descriptions come from
Package.swift (the comment line above each `.library`), and each row links to its doc
page by convention (Docs/<Component>.md). Run it in the same change that ships a
component, so the catalog cannot drift from the package.

Candidates (things observed but not yet settled) are hand-kept in
Docs/component-candidates.md and included verbatim — they have no manifest to derive from.
"""
import re, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# product name -> doc page basename (only where they differ from the product suffix)
DOC_OVERRIDES = {"DesignScaffoldLoading": "LoadingModal",
                 "DesignScaffoldPlaylist": "PlaylistIterator"}

def products():
    text = (ROOT / "Package.swift").read_text()
    # each product is preceded by a // comment line describing it
    out = []
    lines = text.splitlines()
    for i, line in enumerate(lines):
        m = re.search(r'\.library\(name:\s*"([^"]+)"', line)
        if not m:
            continue
        name = m.group(1)
        desc = ""
        for back in range(i - 1, max(i - 4, 0) - 1, -1):
            s = lines[back].strip()
            if s.startswith("//"):
                desc = s.lstrip("/ ").strip() + (" " + desc if desc else "")
            elif desc:
                break
        out.append((name, desc.rstrip(".")))
    return out

def doc_for(product):
    base = DOC_OVERRIDES.get(product) or product.replace("DesignScaffold", "") or None
    if not base:
        return None
    p = ROOT / "Docs" / f"{base}.md"
    return f"{base}.md" if p.exists() else None

def latest_tag():
    try:
        return subprocess.run(["git", "describe", "--tags", "--abbrev=0"], cwd=ROOT,
                              capture_output=True, text=True, check=True).stdout.strip()
    except Exception:
        return "unreleased"

def main():
    tag = latest_tag()
    rows = []
    for name, desc in products():
        doc = doc_for(name)
        link = f"[{name}]({doc})" if doc else f"`{name}`"
        rows.append(f"| {link} | {desc} |")

    candidates = (ROOT / "Docs" / "component-candidates.md")
    candidates_md = candidates.read_text().strip() if candidates.exists() else "_None open._"

    md = f"""# DesignScaffold components — the fleet catalog

**Generated from `Package.swift` by `Tools/generate-components-catalog.py` — do not hand-edit.**
Current release: **{tag}** · `https://github.com/xocialize/DesignScaffold` (public, MIT).

> **Before building any macOS UI surface, look here first.** DesignScaffold is the fleet's
> single design authority (AB-D-0040 / AB-D-0041): the token vocabulary and every shared
> component live here, so apps stop re-deriving spacing, radii, and type by eye. If what you
> need is listed, adopt it. If it is close but not right, ask for the change. If it does not
> exist and more than one app would use it, propose it.

## Available now

| Library product | What it is |
|---|---|
{chr(10).join(rows)}

Every component product re-exports `DesignScaffold`, so one import brings `Tokens` and
`cardSurface()` along. Each wears the scaffold look **by default** — no theme call at the
call site — and exposes a `*Theme` whose initializer defaults are the token values, so a
custom theme that only overrides colours still inherits the scaffold geometry.

## Adopting

```swift
// Package.swift
.package(url: "https://github.com/xocialize/DesignScaffold.git", from: "0.1.0")
// then select ONLY the products you use, e.g.
.product(name: "DesignScaffoldStageStepper", package: "DesignScaffold")
```

In Xcode: *File ▸ Add Package Dependencies…*, paste the URL, and tick the libraries you
want. Pin to the tag; `from:` picks up later releases automatically.

**The house rule travels with the tokens:** no view hardcodes a colour, font size, or
spacing value. If a value you need is missing, it gets **added to `Tokens` here first**
(by ask) rather than invented locally — that constraint is what keeps a Figma refresh a
one-file change instead of a fleet-wide hunt.

## Where the boundary sits

| Layer | Source |
|---|---|
| Design vocabulary — colour, type, spacing, radii, `cardSurface()` | **DesignScaffold** (authoritative) |
| Shared components — calendar, playlist, loading, stepper | **DesignScaffold** |
| Engine-management panels — settings, model storage, model state | **MLXEngineUI** (should consume DesignScaffold tokens — AB-A-0018) |
| App-specific product UI (chat views, editors, composites) | the app |

## Requesting a component

Open a bridge ask to the `DesignScaffold` area:

```
bridge ask --to DesignScaffold --title "Propose <Name> into DesignScaffold" --body "..."
```

The intake bar — all four of these, drawn from the accepted AB-A-0017:

1. **The shape has settled** — it survived repeated real use, not one screen.
2. **It is already data-driven and dependency-free** — no engine, model, or app types in
   the view; hosts pass values in. Correlation/formatting stays app-side.
3. **No new tokens needed** — or say exactly which are missing, and they get added here.
4. **There is a written contract to generalise against** — measured behaviour beats a
   description of the pixels.

A fifth signal short-circuits debate: **two independent apps want it.** If a candidate
below matches something you need, say so on its ask — that is the strongest evidence there is.

## Candidates — observed, not yet settled

{candidates_md}
"""
    (ROOT / "Docs" / "COMPONENTS.md").write_text(md)
    print(f"wrote Docs/COMPONENTS.md ({len(rows)} products, tag {tag})")

if __name__ == "__main__":
    sys.exit(main())
