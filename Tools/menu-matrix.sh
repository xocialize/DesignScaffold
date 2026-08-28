#!/bin/zsh
# Walks the clip context-menu matrix in the Component Lab and captures every cell.
#
# Three rules this encodes, each from a run that produced a wrong answer:
#   1. Activate immediately before EVERY synthetic click. A click into a window that is not
#      frontmost is consumed activating it, and the result reads as "the feature is broken".
#   2. Every cell carries a POSITIVE CONTROL — a right-click on the gap, whose menu must open.
#      A cell whose control is dead is INCONCLUSIVE, never a null result.
#   3. Name each capture from the STATE line the APP printed, never from the loop variable.
#      A control click that misses leaves the loop confident and every later file mislabelled.
set -e
APP="$1"; OUT="$2"; shift 2; EXTRA=("$@")   # extra app launch args, e.g. -MainMenu
D="$(dirname "$0")/InputDriver/.build/release/inputdriver"
LOG="$OUT/lab.log"

pkill -f "DesignWorkspace.app/Contents/MacOS/DesignWorkspace" 2>/dev/null || true
sleep 0.5
mkdir -p "$OUT"; rm -f "$LOG"
"$APP/Contents/MacOS/DesignWorkspace" -ComponentLab "${EXTRA[@]}" > "$LOG" 2>&1 &
sleep 2.5

probe() { grep "PROBE $1 " "$LOG" | tail -1 | sed -E 's/.*centre=\(([0-9-]+),([0-9-]+)\).*/\1 \2/'; }
state() { grep '^STATE ' "$LOG" | tail -1 | sed 's/^STATE //;s/ /_/g'; }
act()   { "$D" activate DesignWorkspace >/dev/null; sleep 0.7; }
shot()  { screencapture -x -R"$SHOT_RECT" "$OUT/$1.png"; }
dismiss() { act; "$D" click ${=NEUTRAL} >/dev/null; sleep 0.4; }

act
CLIP=$(probe "clip-A"); GAP=$(probe "gap")
OUTER_BTN=$(probe "outer-cycle"); INNER_BTN=$(probe "inner-cycle")
echo "clip-A=($CLIP) gap=($GAP) outer-btn=($OUTER_BTN) inner-btn=($INNER_BTN)"
NEUTRAL="${CLIP% *} $(( ${CLIP#* } + 260 ))"
SHOT_RECT="$(( ${CLIP% *} - 350 )),$(( ${CLIP#* } - 105 )),760,300"

# Click a control and REFUSE to continue unless the app reports a new state.
advance() {
  local before=$(state)
  act; "$D" click ${=1} >/dev/null; sleep 0.5
  local after=$(state)
  [[ "$before" != "$after" ]] || { echo "ABORT: control click did not change state ($before)"; exit 1; }
}

cell() {
  local name=$(state)
  act; "$D" rightclick ${=CLIP} >/dev/null; sleep 0.9; shot "$name"
  dismiss
  act; "$D" rightclick ${=GAP} >/dev/null; sleep 0.9; shot "$name--control"
  dismiss
}

for _ in 1 2; do
  for _ in 1 2 3 4; do
    cell
    advance "$INNER_BTN"
  done
  advance "$OUTER_BTN"
done
echo "--- state trail ---"; grep '^STATE ' "$LOG"
