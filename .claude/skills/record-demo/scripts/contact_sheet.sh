#!/usr/bin/env bash
# Tile frames from a video into one PNG so an agent can review it with Read.
# Usage: contact_sheet.sh <video.mp4> [out.png] [fps=1] [cols=5]
#   Tip: review just the ending with: ffmpeg -sseof -4 ... or pass a higher fps.
set -euo pipefail
video="${1:?usage: contact_sheet.sh <video.mp4> [out.png] [fps] [cols]}"
out="${2:-${video%.*}_sheet.png}"
fps="${3:-1}"
cols="${4:-5}"
dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$video")"
frames="$(python3 -c "import math;print(max(1, math.ceil($dur*$fps)))")"
rows=$(( (frames + cols - 1) / cols ))
ffmpeg -loglevel error -y -i "$video" -vf "fps=$fps,scale=640:-1,tile=${cols}x${rows}" -frames:v 1 "$out"
echo "$out"
