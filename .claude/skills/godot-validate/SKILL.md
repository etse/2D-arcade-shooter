---
name: godot-validate
description: Verify Godot changes in this repo — compile all GDScript, load all scenes, run a scene headless to catch runtime errors, and capture screenshots to check visuals. Use after editing any .gd/.tscn/.tres file, before committing, or when asked to run, test or screenshot the game.
---

# Validating Godot changes

There are no unit tests. Verification is layered; do the levels that match the change.

## 1. Static: everything compiles and loads (always)

```bash
tools/validate.sh
```

- Re-imports assets, then runs `tools/validate.gd`, which `load()`s every
  `.gd`, `.tscn` and `.tres` under `res://` with autoloads registered.
- Exit 0 and `validate: checked N files, 0 failure(s)` = pass.
- On failure, read the `SCRIPT ERROR` / `Parse Error` lines above the `FAIL:` summary — they give file and line.
- Do NOT use `godot --check-only -s file.gd`: it reports false errors for
  autoload identifiers like `Score` and `CameraControl`.

## 2. Runtime: the scene actually runs (for logic changes)

```bash
tools/godot.sh --headless --path . --quit-after 900 res://screens/Level/Level.tscn 2>&1 \
  | grep -E 'SCRIPT ERROR|^ERROR|^WARNING|at: ' | grep -vE 'leaked|still in use|cleanup|clear \('
```

- `--quit-after` counts frames (~60/s). 900 ≈ 15 s, enough to reach the first enemy waves. The boss arrives later — wave timings live in `screens/Level/levels/Level1/Level1.tscn` (Timer `wait_time`s).
- To reach specific content quickly, temporarily run a smaller scene or reorder the `waves` array in `Level1.gd` — and revert before committing.
- `print()` output shows on stdout; add temporary prints for debugging, remove afterwards.
- Nobody presses keys in a headless run: the player never moves or shoots. To test shooting, temporarily force it (e.g. `Input.action_press("shoot")` in a `_ready`) and revert.
- Ignore the exit-time `ObjectDB instances were leaked` / `resources still in use` lines — pre-existing.

## 3. Visual: screenshot (for anything that changes what's on screen)

```bash
tools/screenshot.sh res://screens/Level/Level.tscn 5 /tmp/shot.png
```

Then Read the PNG to look at it. Renders deterministically at 30 fps via
Movie Maker, so "5" means 5 seconds of game time (takes longer in wall time).
Requires a display (`$DISPLAY`); it won't work with `--headless`. Use the
scratchpad dir for output when available.

Useful scenes: `res://screens/Menu/Menu.tscn`, `res://screens/Level/Level.tscn`,
or any component scene (e.g. `res://components/Bosses/SimpleBoss/SimpleBoss.tscn`)
to look at it in isolation.

## Reporting

State which levels you ran and their outcome. If something can't be verified
(e.g. needs keyboard input or no display), say so explicitly rather than
implying it was tested.
