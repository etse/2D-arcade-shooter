#!/usr/bin/env bash
# Re-import assets and compile/load every script, scene and resource headlessly.
# Exit code 0 = everything loads; 1 = at least one failure (listed as FAIL lines).
set -uo pipefail
cd "$(dirname "$0")/.."
./tools/godot.sh --headless --path . --import >/dev/null 2>&1 || true
./tools/godot.sh --headless --path . --script res://tools/validate.gd 2>&1 \
  | grep -vE '^\[|ObjectDB instances were leaked|resources still in use|^   at: (cleanup|clear) '
exit "${PIPESTATUS[0]}"
