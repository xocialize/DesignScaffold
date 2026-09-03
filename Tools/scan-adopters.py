#!/usr/bin/env python3
"""Scan the dev volumes for DesignScaffold adoption and write Docs/component-adopters.md.

Adoption is DETECTED, not announced. A hand-kept adopters list rots: ours claimed Audio8
Demo as an adopter when that app had forked the vocabulary into its own `enum Tokens`.

Three things get reported, because they are genuinely different states:
  · ADOPTERS      — source imports the package (ground truth), with the resolved pin
  · LINKED ONLY   — a pin exists but nothing imports it (dead dependency)
  · FORKS         — a local `enum Tokens` or copied Tokens.swift outside this repo, i.e. a
                    second design authority in the making (AB-D-0042)
"""
import json, re, subprocess, sys
from pathlib import Path

ROOTS = [Path("/Volumes/Satechi/Development"), Path("/Volumes/DEV_VOL1")]

# Directories that can never contain an adopter and dominate the volume: build output holds
# dependency CHECKOUTS (every package's mlx-swift, swift-nio, …) — ~97% of the Swift files on
# both roots. `Path.rglob` cannot prune, so the first version walked all of them and filtered
# afterwards. Fine at seconds, until the trees grew and a run took 3m46s.
PRUNE = [".build", "DerivedData", "node_modules", ".git", ".swiftpm", "xcuserdata"]

def walk(root: Path, *patterns: str):
    """Yield paths under `root` whose filename matches any of `patterns`, pruning PRUNE dirs.

    Delegates to `find`, and the reason is MEASURED, not stylistic. Pruning by name was only
    half the problem: even pruned, `/Volumes/Satechi/Development` has ~77 000 directories
    (`mlxengine-image` alone ~30 000 — oracle and dataset trees with no code in them). The
    per-file work (`app_of`, reading the source, git) is ~3 s in total and was never the cost,
    which is worth recording because it was the first suspect and the profile disagreed:
    `os.walk` was 151.7 s of a 157.8 s run.

    What the enumeration of that tree costs on this external volume, measured (2026-09-03):

        os.walk, pruned          84 s  per pass
        find, same prunes        58 s  per pass COLD  ·  11 s WARM

    The 5× between cold and warm is the volume's metadata cache, not this script — and it is
    why a standalone `find` timed right after another `find` looks five times faster than the
    same command inside a cold run. Hence the one rule that IS this script's to keep: enumerate
    each root ONCE and dispatch by name (`scan()` used to walk once per pattern, doubling it).
    DEV_VOL1 is ~1 s either way.
    """
    import subprocess
    prune = []
    for i, name in enumerate(PRUNE):
        if i: prune.append("-o")
        prune += ["-name", name]
    match = []
    for i, pat in enumerate(patterns):
        if i: match.append("-o")
        match += ["-name", pat]
    cmd = ["find", str(root), "(", *prune, ")", "-prune", "-o", "(", *match, ")", "-type", "f", "-print0"]
    out = subprocess.run(cmd, capture_output=True).stdout
    for raw in out.split(b"\0"):
        if raw:
            yield Path(raw.decode("utf-8", errors="surrogateescape"))

SELF = Path("/Volumes/Satechi/Development/DesignScaffold")
SKIP = re.compile(r"/\.build/|/\.git/|/DerivedData/|AgentBridge-Store/retired/|/checkouts/")

# Vocabularies that are NOT ours and must stop being reported as forks. An anomaly needs a
# disposition, never a re-flag ignored forever (AB-L-0038) — so each entry carries its reason
# and is printed as sanctioned rather than silently dropped.
SANCTIONED_FORKS = {
    "fleetlock-selfservice": (
        "A different product's design system, not a copy of ours: a 1:1 mapping of the "
        "Figma file `hz46ViMGoMIpwBUKnjZhrQ` (\"FleetLock Self-Service\"), hex copied from "
        "that source, on the off-corpus volume. AB-D-0042 governs this fleet's macOS apps; "
        "it does not reach another product with its own design authority. (AB-T-0087)"
    ),
}

def rel(p: Path) -> str:
    for r in ROOTS:
        try:
            return str(p.relative_to(r))
        except ValueError:
            continue
    return str(p)

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout.splitlines()

def latest_tag():
    if "--tag" in sys.argv:
        return sys.argv[sys.argv.index("--tag") + 1]
    return subprocess.run(["git", "describe", "--tags", "--abbrev=0"], cwd=SELF,
                          capture_output=True, text=True).stdout.strip()

def norm(name: str) -> str:
    """ML[X]-LTX-Studio / ML[X] LTX Studio / *.xcodeproj all key to one app."""
    for ext in (".xcodeproj", ".xcworkspace"):
        name = name.replace(ext, "")
    return re.sub(r"[^a-z0-9]", "", name.lower())

def dirty_files(repo: Path) -> set:
    """Paths with uncommitted changes, so in-flight work is not reported as shipped."""
    out = subprocess.run(["git", "status", "--porcelain"], cwd=repo,
                         capture_output=True, text=True).stdout.splitlines()
    return {line[3:].strip() for line in out}

def repo_of(p: Path):
    for parent in p.parents:
        if (parent / ".git").exists():
            return parent
    return None

def scope_root(manifest_dir: Path) -> Path:
    """The directory a Package.resolved actually governs.

    An Xcode pin lives at `<root>/Foo.xcworkspace/xcshareddata/swiftpm/Package.resolved` —
    four levels below the root it serves — so testing containment against the manifest's own
    directory makes every workspace pin look orphaned. Climb out past the OUTERMOST
    `.xcworkspace`/`.xcodeproj` bundle; a plain SwiftPM manifest governs its own directory.
    """
    parts = manifest_dir.parts
    for i, part in enumerate(parts):
        if part.endswith(".xcworkspace") or part.endswith(".xcodeproj"):
            return Path(*parts[:i])
    return manifest_dir

def project_of(p: Path) -> str:
    parts = rel(p).split("/")
    return parts[0] if parts else "?"

def app_of(p: Path) -> str:
    """Nearest enclosing .xcodeproj/.xcworkspace/Package.swift owner, for a readable name."""
    for parent in p.parents:
        if any(parent.glob("*.xcodeproj")) or any(parent.glob("*.xcworkspace")) \
           or (parent / "Package.swift").exists():
            return parent.name
    return p.parent.name

def scan():
    pins, imports, forks, exact_pins, all_pins = {}, {}, [], [], {}
    for root in ROOTS:
        if not root.exists():
            continue
        # resolved pins
        # ONE enumeration per root — see walk(). Both patterns ride the same find.
        found = list(walk(root, "Package.resolved", "*.swift"))
        resolved = [f for f in found if f.name == "Package.resolved"]
        swifts = [f for f in found if f.suffix == ".swift"]
        for f in resolved:
            if SKIP.search(str(f)):
                continue
            try:
                data = json.loads(f.read_text())
            except Exception:
                continue
            for pin in data.get("pins", []):
                if "designscaffold" in pin.get("identity", "").lower():
                    all_pins.setdefault(app_of(f), []).append(
                        (pin["state"].get("version", "?"), rel(f), project_of(f), scope_root(f.parent)))
        # source imports (ground truth) + vocabulary forks
        for f in swifts:
            s = str(f)
            if SKIP.search(s) or s.startswith(str(SELF)):
                continue
            try:
                text = f.read_text(errors="ignore")
            except Exception:
                continue
            if "import DesignScaffold" in text:
                mods = sorted(set(re.findall(r"import (DesignScaffold\w*)", text)))
                key = app_of(f)
                imports.setdefault(key, {"mods": set(), "files": 0, "project": project_of(f),
                                         "paths": [], "name": key})
                imports[key]["mods"].update(mods)
                imports[key]["files"] += 1
                imports[key]["paths"].append(f)
            if re.search(r"^\s*(public )?enum Tokens\b", text, re.M):
                forks.append((app_of(f), rel(f), project_of(f), len(text.splitlines())))
            # exact pins are the only version drift that does NOT self-correct
            if re.search(r'exactVersion|\.exact\(', text) and "DesignScaffold" in text:
                exact_pins.append(rel(f))
    # The governing pin is the OUTERMOST scope (a workspace beats the project inside it). A
    # second file for the same app that disagrees is a SHADOW pin: harmless while the workspace
    # is what gets opened, and a silent downgrade for whoever opens the project directly.
    # Audio Studio found one at 0.15.0 under a 0.21.0 workspace (AB-A-0060); the sweep after
    # it found MarqueeStudio at 0.11.0 under 0.22.0. Before this, the dict slot per app meant
    # whichever file the walk reached LAST won — this scanner was hiding the very thing.
    #
    # ⚠️ Keyed by ANCESTRY, not by app name — the first cut compared pins that shared an
    # `app_of` key and reported zero, while MarqueeStudio's two files sat in plain sight:
    # they key as `MarqueeStudio_WS.xcworkspace` and `MarqueeStudio.xcodeproj`, so they never
    # met. What they do share is that the workspace's scope root is a strict ancestor of the
    # project's. A pin governs every pin whose scope root lies beneath its own.
    for app, entries in all_pins.items():
        pins[app] = min(entries, key=lambda e: len(e[3].parts))
    flat = [e for entries in all_pins.values() for e in entries]
    shadow = []
    for inner in flat:
        governors = [g for g in flat if g is not inner and g[3] != inner[3]
                     and g[3] in inner[3].parents]
        if not governors:
            continue
        governing = min(governors, key=lambda g: len(g[3].parts))   # outermost wins
        if governing[0] != inner[0]:
            shadow.append((inner[3].name, governing, inner))
    return pins, imports, forks, exact_pins, shadow

def main():
    tag = latest_tag()
    pins, imports, forks, exact_pins, shadow = scan()
    lines = []

    lines.append("| Adopter | Project | Products used | Files | Pin | |")
    lines.append("|---|---|---|---|---|---|")
    pins_by_norm = {norm(k): v for k, v in pins.items()}

    def pin_covers(root: Path, info) -> bool:
        """A pin serves an adopter when an importing file lives beneath the root it governs."""
        for p in info["paths"]:
            try:
                p.relative_to(root)
                return True
            except ValueError:
                continue
        return False
    for app in sorted(imports):
        info = imports[app]
        matched = pins_by_norm.get(norm(app))
        if matched is None:
            # fall back to containment: workspace pins sit above the project that imports
            for candidate in pins.values():
                if pin_covers(candidate[3], info):
                    matched = candidate
                    break
        version = matched[0] if matched else "—"
        # in-flight adoption must not read as shipped
        uncommitted = False
        repo = repo_of(info["paths"][0]) if info["paths"] else None
        if repo:
            dirty = dirty_files(repo)
            uncommitted = any(str(p.relative_to(repo)) in dirty for p in info["paths"])
        if uncommitted:
            drift = "🚧 in progress (uncommitted)"
        elif version == tag:
            drift = "✅"
        elif version != "—":
            drift = f"behind ({tag})"
        else:
            drift = "no pin found"
        mods = ", ".join(f"`{m}`" for m in sorted(info["mods"]))
        lines.append(f"| **{app}** | {info['project']} | {mods} | {info['files']} | {version} | {drift} |")
    if not imports:
        lines.append("| _none detected_ | | | | | |")

    imported_norms = {norm(a) for a in imports}
    linked_only = sorted(
        app for app, meta in pins.items()
        if norm(app) not in imported_norms
        and not any(pin_covers(meta[3], info) for info in imports.values()))
    if linked_only:
        lines.append("")
        lines.append("**Linked but unused** (a pin with no import — dead dependency): "
                     + ", ".join(f"`{a}`" for a in linked_only))

    lines.append("")
    if shadow:
        lines.append("")
        lines.append("### ⚠️ Shadow pins — a second `Package.resolved` that disagrees with the governing one")
        lines.append("")
        lines.append("The workspace-level file governs when the workspace is opened; the project-level file")
        lines.append("governs when the `.xcodeproj` is opened directly. When they disagree, the second is a")
        lines.append("silent downgrade for anyone who does that. Resolve with the project open and commit both.")
        lines.append("")
        lines.append("| Adopter | governs | shadowed by |")
        lines.append("|---|---|---|")
        for app, gov, other in sorted(shadow):
            lines.append(f"| **{app}** | {gov[0]} — `{gov[1]}` | **{other[0]}** — `{other[1]}` |")

    if exact_pins:
        lines.append("⚠️ **Exact pins** (these do NOT resolve forward): "
                     + ", ".join(f"`{p}`" for p in sorted(exact_pins)))
    else:
        lines.append("_A version behind the latest is a resolved snapshot, not a defect: no "
                     "adopter declares an exact pin, so every one moves forward on its next "
                     "resolve._" + (" _Except the shadowed project files above, which move only "
                                    "when someone resolves with the project itself open._"
                                    if shadow else ""))

    sanctioned = [f for f in forks if f[0] in SANCTIONED_FORKS]
    forks = [f for f in forks if f[0] not in SANCTIONED_FORKS]

    if forks:
        lines.append("")
        lines.append("### ⚠️ Vocabulary forks — a second design authority in the making")
        lines.append("")
        lines.append("A local `enum Tokens` outside this package. Per AB-D-0042 these should adopt")
        lines.append("the package; anything genuinely missing gets added to `Tokens` here by ask.")
        lines.append("")
        lines.append("| Where | Project | File | Lines |")
        lines.append("|---|---|---|---|")
        for app, path, project, n in sorted(forks):
            lines.append(f"| {app} | {project} | `{path}` | {n} |")

    if sanctioned:
        lines.append("")
        lines.append("### Sanctioned — not ours, and deliberately not flagged")
        lines.append("")
        for app, path, project, _ in sorted(sanctioned):
            lines.append(f"- **{app}** (`{path}`) — {SANCTIONED_FORKS[app]}")

    body = "\n".join(lines)
    (SELF / "Docs" / "component-adopters.md").write_text(
        f"<!-- Generated by Tools/scan-adopters.py — do not hand-edit. Release {tag}. -->\n\n{body}\n")
    print(f"adopters: {len(imports)} · linked-only: {len(linked_only)} · "
          f"forks: {len(forks)} · sanctioned: {len(sanctioned)} · exact pins: {len(exact_pins)} · "
          f"shadow pins: {len(shadow)}")

if __name__ == "__main__":
    sys.exit(main())
