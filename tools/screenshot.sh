#!/usr/bin/env bash
# Render a scene for N seconds (deterministic 30 fps via Movie Maker) and keep
# the last frame as a PNG. Needs a display ($DISPLAY); does not work headless.
#
# Usage: tools/screenshot.sh [scene=res://screens/Level/Level.tscn] [seconds=3] [out=/tmp/godot-shot.png]
set -euo pipefail
cd "$(dirname "$0")/.."
scene="${1:-res://screens/Level/Level.tscn}"
seconds="${2:-3}"
out="${3:-/tmp/godot-shot.png}"
fps=30
frames=$(( seconds * fps ))
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
./tools/godot.sh --path . --write-movie "$tmp/f.png" --fixed-fps "$fps" \
  --quit-after "$frames" "$scene" >"$tmp/log.txt" 2>&1 || { cat "$tmp/log.txt" >&2; exit 1; }
last="$(ls -1 "$tmp"/f*.png | sort | tail -n1)"
mkdir -p "$(dirname "$out")"
cp "$last" "$out"
grep -E 'SCRIPT ERROR|^ERROR' "$tmp/log.txt" | grep -v 'resources still in use' >&2 || true
echo "$out"
