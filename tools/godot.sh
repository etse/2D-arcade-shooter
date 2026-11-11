#!/usr/bin/env bash
# Locate the Godot 4 binary and forward all arguments to it.
# Resolution order: $GODOT, `godot4`/`godot` on PATH, ~/Applications/Godot_v4*.
set -euo pipefail
if [[ -n "${GODOT:-}" ]]; then
  bin="$GODOT"
elif command -v godot4 >/dev/null 2>&1; then
  bin="$(command -v godot4)"
elif command -v godot >/dev/null 2>&1; then
  bin="$(command -v godot)"
else
  bin="$(ls -1 "$HOME"/Applications/Godot_v4*linux*.x86_64 2>/dev/null | sort -V | tail -n1 || true)"
fi
if [[ -z "${bin:-}" || ! -x "$bin" ]]; then
  echo "godot.sh: no Godot 4 binary found. Set GODOT=/path/to/godot." >&2
  exit 127
fi
exec "$bin" "$@"
