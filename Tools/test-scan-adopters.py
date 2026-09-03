#!/usr/bin/env python3
"""Fixture tests for scan-adopters.py — the instrument that was blind to its own case.

The first shadow-pin detector reported ZERO on a volume that held one, because it compared
pins by app name and the two files keyed differently. A synthetic tree pins the rule so a
future refactor cannot quietly restore the blindness. Runs in well under a second; it never
touches the real roots.
"""
import importlib.util, json, sys, tempfile
from pathlib import Path

spec = importlib.util.spec_from_file_location("scan", Path(__file__).with_name("scan-adopters.py"))
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

def resolved(path: Path, version: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"pins": [{"identity": "designscaffold", "kind": "remoteSourceControl",
        "location": "https://github.com/xocialize/DesignScaffold.git",
        "state": {"revision": "0" * 40, "version": version}}], "version": 3}))

def run(tree):
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp) / "Dev"
        for rel, version in tree.items():
            resolved(root / rel, version)
        m.ROOTS[:] = [root]
        _, _, _, _, shadow = m.scan()
        return shadow

failures = 0
def check(name, cond, detail=""):
    global failures
    print(("  ✓ " if cond else "  ✗ ") + name + (f"  — {detail}" if detail and not cond else ""))
    failures += 0 if cond else 1

# 1. The MarqueeStudio shape: workspace at 0.22.0 governing a project inside it at 0.11.0.
shadow = run({
    "MarqueeStudio/MarqueeStudio_WS.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.22.0",
    "MarqueeStudio/MarqueeStudio/MarqueeStudio.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.11.0",
})
check("a disagreeing project pin under a workspace is ONE shadow", len(shadow) == 1, repr(shadow))
if shadow:
    _, gov, inner = shadow[0]
    check("the workspace governs", gov[0] == "0.22.0", gov[0])
    check("the project file is the shadowed one", inner[0] == "0.11.0", inner[0])

# 2. Same shape, versions agree → nothing to report.
check("agreeing pins are not a shadow", run({
    "App/App_WS.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.22.0",
    "App/App/App.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.22.0",
}) == [])

# 3. Two unrelated apps at different versions are NOT each other's shadow (no ancestry).
check("siblings at different versions are not shadows", run({
    "Alpha/Alpha.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.16.0",
    "Beta/Beta.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.22.0",
}) == [])

# 4. The Demos shape: one umbrella workspace over several projects that AGREE with it.
check("an umbrella over agreeing projects reports nothing", run({
    "Demos/MLX_Demos_WS.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.16.0",
    "Demos/A Demo/A Demo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.16.0",
    "Demos/B Demo/B Demo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.16.0",
}) == [])

# 5. …and flags exactly the one that drifted.
shadow = run({
    "Demos/MLX_Demos_WS.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.16.0",
    "Demos/A Demo/A Demo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.16.0",
    "Demos/B Demo/B Demo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved": "0.23.0",
})
check("one drifted project under an umbrella is exactly one shadow", len(shadow) == 1 and shadow[0][2][0] == "0.23.0", repr(shadow))

print(f"\n{'ALL PASSED' if not failures else f'{failures} FAILED'}")
sys.exit(1 if failures else 0)
