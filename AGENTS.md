# AGENTS.md — "The invasion" (2D arcade shooter)

Guide for coding agents working in this repo. Keep it current: if you learn
something non-obvious about the project, add it here.

## What the game is

A vertical-scrolling, old-school shoot 'em up inspired by Tyrian 2000. The
player flies a ship at the bottom of the screen, shoots upward at waves of
enemies and finishes the level with a boss fight. Earned score is shown as
money (`$123`); the menu has "Upgrade weapon" / "Upgrade ship" entries meant
for a shop (not implemented yet).

- Engine: **Godot 4.7** (`config/features=PackedStringArray("4.7")`), GDScript only, no addons.
- Originally a Godot 3 project, migrated to Godot 4 (see git history). Watch out
  for Godot 3 idioms in older code (skill `gdscript-godot4`).
- Main scene: `res://screens/Menu/Menu.tscn`.
- Viewport 1920×1080, window 1280×720, stretch mode `viewport`.
- Some commit messages / comments are in Norwegian.

## Commands

All helpers live in `tools/` and find the Godot binary via `tools/godot.sh`
(`$GODOT` → `godot4`/`godot` on PATH → `~/Applications/Godot_v4*linux*.x86_64`).

| Task | Command |
| --- | --- |
| Validate everything (re-import, compile all scripts, load all scenes) | `tools/validate.sh` (exit 0 = OK) |
| Run a scene headless for N frames (catch runtime errors) | `tools/godot.sh --headless --path . --quit-after 600 res://screens/Level/Level.tscn` |
| Screenshot a scene after N seconds (needs `$DISPLAY`) | `tools/screenshot.sh res://screens/Level/Level.tscn 5 /tmp/shot.png` |
| Open the editor | `tools/godot.sh --path . -e` |
| Run the game | `tools/godot.sh --path .` |

Notes:
- `godot --check-only -s <file>` does **not** work for scripts that use the
  autoloads (`Score`, `CameraControl`) — use `tools/validate.sh` instead.
- At exit Godot prints `ObjectDB instances were leaked` / `resources still in use`;
  these are pre-existing noise, not something you broke.
- There are no automated tests. "Done" = `tools/validate.sh` passes, the
  affected scene runs headless without `SCRIPT ERROR`, and for visual changes a
  screenshot looks right.

## Project layout

```
project.godot                  engine config, autoloads, input map
components/                    reusable scenes, each folder = Scene.tscn + Scene.gd
  Player/                      CharacterBody2D player ship
  Enemies/BasicEnemy/          basic Area2D enemy (class_name BasicEnemy)
  Bosses/SimpleBoss/           level-1 boss, fires FireBalls
  Bullets/                     bullet.gd (class_name Bullet) + Bullet/FireBullet/FireBall scenes
  CameraEffects/ScreenShake/   shake effect, child of the level's Camera2D
  HUD/                         CanvasLayer: score label + health bar
  InfinityScroll/              looping vertical background layer
  Menu/                        menu widgets (Label, MainMenu, Options, Slider, ShopItem, UpgradeShip)
  Singletons/                  autoload scripts (Score, CameraControl)
screens/
  Menu/                        main menu screen (entry point)
  Level/Level.tscn             gameplay shell: walls, HUD, Player, Camera, fade overlay, Level1
  Level/levels/Level1/         Level1 scene + wave scripts
assets/                        3rd-party art/music/sfx/fonts (see README for licences)
tools/                         agent/dev helper scripts (validate, screenshot, godot wrapper)
```

## Architecture

### Autoloads (`project.godot` → `[autoload]`)
- `Score` (`components/Singletons/Score.gd`): `score: int`, `add_score(points)`, signal `score_changed(score)`. Never reset between runs.
- `CameraControl` (`components/Singletons/Camera_control.gd`): global event bus for screen shake. Call `CameraControl.screen_shake(amplitude, frequency, duration)`; `Level.gd` forwards it to `$Camera/ScreenShake`.

### Scene flow
`Menu.tscn` → "Start next level" → `change_scene_to_file("res://screens/Level/Level.tscn")`
→ player dies, or `Level1` emits `completed` after its last wave → `Level.gd` fades out → back to `Menu.tscn`.
There is no dedicated win/lose screen yet.

### Levels and waves
`Level1.gd` holds an ordered array of wave nodes and runs them in order as a
simple state machine; after the last wave it emits `completed`. Each wave is a child `Node` of `Level1/Waves` with a script that
implements this informal protocol (duck-typed, no base class):

```gdscript
func start() -> void          # called when the wave becomes active
func update(delta) -> bool    # called every frame; return true when the wave is finished
func exit() -> void           # called once, before the next wave starts
```

Current order: `Wait → SimpleFighters → Formation → Wait → BossBattle`.
`DifferentStrength`, `Attackers`, `HordeEvade`, `CalmBeforeBoss` are empty
placeholder nodes not yet wired in. Waves spawn enemies under their own
`Enemies` child and move them with tweens (`SimpleFighters`) or
`Path2D`/`PathFollow2D` (`Formation`). Spawn/target positions are `Marker2D`s
under each wave's `Points` node. Movement tweens are created on the enemy (or
its `PathFollow2D`) so they die with it, and the enemy is `queue_free()`d when
the tween finishes (end points are below the screen). `BossBattle` finishes
when the boss emits `destroyed`.

### Combat / collision model
Collision layers/masks are all default; **filtering is done with groups**:
- `"enemies"` — enemies and bosses (Area2D). Must implement `on_hit(damage: float)`.
- `"bullets"` — all bullets (Area2D, `bullet.gd`). `friendly=true` hits `"enemies"`, `friendly=false` hits `"player"`.
- `"player"` — the player body.
- Bullets free themselves once they are more than `OFFSCREEN_MARGIN` (200 px) outside the visible screen. The `WorldBounds` walls in `Level.tscn` only keep the player on screen.
- Bullets poll `get_overlapping_areas()/bodies()` in `_process` rather than using signals.
- The player takes ramming damage via its `CollisionArea` overlapping `"enemies"`.
- Enemy death: `health <= 0` → explosion anim + sound, `Score.add_score(points)`, screen shake, `queue_free()` when the sound ends.

### Player
`components/Player/Player.gd`: acceleration-based movement with dampening
(`acceleration_force`, `dampening`, `max_speed`, slower `max_speed_shooting`
while holding fire). Fires two `FireBullet`s every 0.4 s from `$LeftGun`/`$RightGun`.
Health 100, regenerates over time (10× slower while shooting). Signals
`health_changed(health)` and `destroyed`.

### Input map
`move_left/right/up/down` = arrow keys, `shoot` = Space, `mouse_click` = LMB,
plus `ui_focus_next/prev` remapped to Tab/arrows for the menu.

### Audio
Buses in `default_bus_layout.tres`: `Master`, `sfx`, `music`. Options menu
changes bus volumes (not persisted to disk).

## Conventions
- One folder per component: `Name/Name.tscn` + `Name/Name.gd` (+ the `.gd.uid` file Godot generates — commit it).
- Signal handler names follow the Godot 3 style `_on_NodeName_signal_name` (keep consistent, they are wired in the `.tscn` files).
- Existing code uses camelCase for many vars/functions; new code should prefer
  GDScript style (snake_case, static typing) but don't mass-rename existing
  members — names are referenced from `.tscn` connections.
- Use `preload()` for scenes that are instantiated repeatedly (bullets, enemies).
- Use `create_tween()` (Godot 4); there is no `Tween` node anymore.
- Prefer editing scenes in a way that keeps the `.tscn` diff small; see the `godot-scene-editing` skill.
- Commit directly on `main`.

## Known issues / gotchas
- "Upgrade weapon" has no handler in `Menu.gd`; `UpgradeShip` / `ShopItem` are stubs (shop not implemented).
- `Score` persists across runs (never reset). Intentional if score is meant to be shop money — decide when the shop is built.

## Skills
Project skills for agents are in `.claude/skills/`:
- `godot-validate` — verify changes (validate, headless run, screenshots).
- `godot-scene-editing` — safely hand-edit `.tscn`/`.tres` files.
- `gdscript-godot4` — GDScript 4 idioms and Godot 3→4 pitfalls.
- `shmup-content` — add enemies, bullets, waves and bosses the way this project does it.

<!-- TODO (owner): add design goals, planned features, art/style direction, balancing notes. -->
