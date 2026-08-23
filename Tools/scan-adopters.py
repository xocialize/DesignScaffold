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
SELF = Path("/Volumes/Satechi/Development/DesignScaffold")
SKIP = re.compile(r"/\.build/|/\.git/|/DerivedData/|AgentBridge-Store/retired/|/checkouts/")

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
    pins, imports, forks = {}, {}, []
    for root in ROOTS:
        if not root.exists():
            continue
        # resolved pins
        for f in root.rglob("Package.resolved"):
            if SKIP.search(str(f)):
                continue
            try:
                data = json.loads(f.read_text())
            except Exception:
                continue
            for pin in data.get("pins", []):
                if "designscaffold" in pin.get("identity", "").lower():
                    pins[app_of(f)] = (pin["state"].get("version", "?"), rel(f), project_of(f))
        # source imports (ground truth) + vocabulary forks
        for f in root.rglob("*.swift"):
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
    return pins, imports, forks

def main():
    tag = latest_tag()
    pins, imports, forks = scan()
    lines = []

    lines.append("| Adopter | Project | Products used | Files | Pin | |")
    lines.append("|---|---|---|---|---|---|")
    pins_by_norm = {norm(k): v for k, v in pins.items()}
    for app in sorted(imports):
        info = imports[app]
        version, _, _ = pins_by_norm.get(norm(app), ("—", "", ""))
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
            drift = f"⚠️ {tag} available"
        else:
            drift = "⚠️ no pin found"
        mods = ", ".join(f"`{m}`" for m in sorted(info["mods"]))
        lines.append(f"| **{app}** | {info['project']} | {mods} | {info['files']} | {version} | {drift} |")
    if not imports:
        lines.append("| _none detected_ | | | | | |")

    imported_norms = {norm(a) for a in imports}
    linked_only = sorted(a for a in pins if norm(a) not in imported_norms)
    if linked_only:
        lines.append("")
        lines.append("**Linked but unused** (a pin with no import — dead dependency): "
                     + ", ".join(f"`{a}`" for a in linked_only))

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

    body = "\n".join(lines)
    (SELF / "Docs" / "component-adopters.md").write_text(
        f"<!-- Generated by Tools/scan-adopters.py — do not hand-edit. Release {tag}. -->\n\n{body}\n")
    print(f"adopters: {len(imports)} · linked-only: {len(linked_only)} · forks: {len(forks)}")

if __name__ == "__main__":
    sys.exit(main())
