#!/usr/bin/env bash
# Record a scripted demo director to demo/<name>.mp4 (1920x1080, 30 fps, AAC audio).
#
# Usage: record.sh [--dry-run] <director.gd> [out.mp4]
#   director.gd  path relative to the repo root (or res://...), extends demo_base.gd
#   out.mp4      default: demo/<director name>.mp4
#   --dry-run    run headless at full speed, no video; just print DEMO/errors lines
#
# Needs $DISPLAY and ffmpeg for recording. Run from anywhere inside the repo.
set -euo pipefail
repo="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"

dry=0
if [[ "${1:-}" == "--dry-run" ]]; then dry=1; shift; fi
director="${1:?usage: record.sh [--dry-run] <director.gd> [out.mp4]}"
if [[ "$director" == res://* ]]; then
  director="$repo/${director#res://}"
fi
[[ -f "$director" ]] || { echo "record.sh: no such director: $director" >&2; exit 1; }
director="$(realpath "$director")"
director="${director#"$repo"/}"   # repo-relative -> res:// path below
name="$(basename "$director" .gd)"
if [[ -n "${2:-}" ]]; then out="$(realpath -m "$2")"; else out="$repo/demo/$name.mp4"; fi
cd "$repo"

# Throw-away launcher scene (hidden dir: Godot won't import it).
run_dir="$(mktemp -d "$repo/.demo_run.XXXXXX")"
tmp="$(mktemp -d)"
trap 'rm -rf "$run_dir" "$tmp"' EXIT
cat > "$run_dir/Demo.tscn" <<TSCN
[gd_scene format=3]

[ext_resource type="Script" path="res://$director" id="1"]

[node name="Demo" type="Node"]
script = ExtResource("1")
TSCN
scene="res://$(basename "$run_dir")/Demo.tscn"
filter() { grep -E 'DEMO|SCRIPT ERROR|^ERROR|^   at: ' | grep -vE 'still in use|at: (clear|cleanup) ' || true; }

if [[ $dry -eq 1 ]]; then
  timeout 300 tools/godot.sh --headless --path . "$scene" 2>&1 | filter
  exit 0
fi

command -v ffmpeg >/dev/null || { echo "record.sh: ffmpeg not found" >&2; exit 1; }
timeout 900 tools/godot.sh --path . --write-movie "$tmp/demo.avi" --fixed-fps 30 "$scene" 2>&1 | filter
mkdir -p "$(dirname "$out")" "$repo/demo"
touch "$repo/demo/.gdignore"   # keep Godot from importing videos/images
ffmpeg -loglevel error -y -i "$tmp/demo.avi" -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \
  -c:a aac -b:a 160k -movflags +faststart "$out"
dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$out")"
LC_ALL=C printf 'recorded %s (%.1f s, %s)\n' "$out" "$dur" "$(du -h "$out" | cut -f1)"
