# AGENTS.md — "The invasion" (2D arcade shooter)

Guide for coding agents working in this repo. Keep it current: if you learn
something non-obvious about the project, add it here.

## What the game is

A vertical-scrolling, old-school shoot 'em up inspired by Tyrian 2000. The
player flies a ship at the bottom of the screen and shoots upward at waves of
enemies.

### Game design (intended)

- **Multiple levels.** The game is a sequence of levels; each level is a series
  of enemy waves and **always ends with a boss fight**.
- **Points are money.** Destroying enemies and bosses earns points, and points
  are the currency (shown as `$123` in the HUD). They carry over between levels.
- **Shopping between levels.** After a level, back in the menu, the player
  spends money in shops to:
  - buy new weapons,
  - upgrade weapons,
  - upgrade other parts of the ship (e.g. health, regen, speed).

### Weapons (intended)

- Every weapon has its **own graphics** (bullet sprite, effects) and its **own
  strengths** — a distinct trade-off, not just bigger numbers.
- Some weapons can simply be **better overall, but cost more**.
- Each weapon has its own **upgrade path**: upgrades raise that weapon's
  stats (damage, number of bullets, rate of fire, …), and which stats can be
  upgraded depends on the weapon.

Example weapons:

| Weapon | Behaviour | Strength / weakness | Upgrades |
| --- | --- | --- | --- |
| **Focus fire** | Shoots straight ahead | High damage, but covers only a narrow part of the screen | Damage, number of bullets, rate of fire |
| **Spread fire** | Shoots in a spread across the screen | Hits much more of the screen, but less damage than focus fire | Spread angle, rate of fire, damage, number of bullets |
| **Homing rockets** | Fires missiles that seek enemies | Area-of-effect (AoE) damage on impact | Damage, AoE radius, rate of fire |

Design implications for code: weapon stats and per-level upgrade values should
be data (e.g. a `Resource` per weapon) rather than hard-coded in `Player.gd`,
so new weapons and upgrade levels can be added without new logic, and so the
shop can read names, prices and stats from the same data.

### Current state

Only Level 1 exists (waves → boss → back to menu). Money is earned and kept.
The **weapon shop** ("Upgrade weapon" in the main menu) sells one item: upgrades
for **Focus fire**, the only weapon, from level 1 to 10. Buying new weapons and
ship upgrades ("Upgrade ship" → `UpgradeShip` / `ShopItem` stubs) is not built yet.

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
| Record a demo video (scripted autoplay, needs `$DISPLAY` + ffmpeg) | `.claude/skills/record-demo/scripts/record.sh .claude/skills/record-demo/scripts/demos/weapon_shop.gd` → `demo/weapon_shop.mp4` |
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
  Weapons/                     WeaponData.gd (class_name WeaponData) + one folder per weapon with its .tres
  CameraEffects/ScreenShake/   shake effect, child of the level's Camera2D
  HUD/                         CanvasLayer: score label + health bar
  InfinityScroll/              looping vertical background layer
  Menu/                        menu widgets (Label, MainMenu, Options, Slider, WeaponShop, ShopItem, UpgradeShip)
  Singletons/                  autoload scripts (Score, CameraControl, Loadout)
screens/
  Menu/                        main menu screen (entry point)
  Level/Level.tscn             gameplay shell: walls, HUD, Player, Camera, fade overlay, Level1
  Level/levels/Level1/         Level1 scene + wave scripts
assets/                        3rd-party art/music/sfx/fonts (see README for licences)
tools/                         agent/dev helper scripts (validate, screenshot, godot wrapper)
demo/                          recorded demo videos (git-ignored, see skill record-demo)
```

## Architecture

### Autoloads (`project.godot` → `[autoload]`)
- `Score` (`components/Singletons/Score.gd`): `score: int`, `add_score(points)`, `spend(amount) -> bool`, signal `score_changed(score)`. This is the player's money — intentionally never reset between levels/runs.
- `Loadout` (`components/Singletons/Loadout.gd`): the player's equipment — `weapon: WeaponData` and `weapon_level` (starts at 1). `upgrade_weapon()` pays via `Score.spend()` and emits `changed`. In memory only, not saved.
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

### Weapons and the shop
- A weapon is a `WeaponData` resource (`components/Weapons/WeaponData.gd`): name, description, icon, `bullet_scene`, and per-level arrays `damage`, `bullet_count`, `fire_interval`, `upgrade_cost` (index = level − 1; array length = max level; `upgrade_cost[i]` is the price to go from level i+1 to i+2).
- Focus fire: `components/Weapons/FocusFire/FocusFire.tres` (10 levels; level 1 = 2 dmg, 2 bullets, 0.4 s). Balance it by editing that file.
- `Player.gd` `fire_weapon()` reads the equipped weapon from `Loadout` and fires `bullet_count` bullets spread between `$LeftGun` and `$RightGun` (widens by `FOCUS_FIRE_EXTRA_WIDTH` per bullet beyond two), all straight ahead. Inner bullets spawn `FOCUS_FIRE_STAGGER` px further ahead per step from the edge, so 3+ bullets form an arrowhead (3 = triangle, 4 = middle pair ahead). Other firing patterns (spread, homing) will need their own logic — likely a fire-pattern field on `WeaponData`.
- `components/Menu/WeaponShop/` is the shop panel; `Menu.gd` switches to it from MainMenu's `UpgradeWeapon` signal and back on its `back` signal. It rebuilds its UI from `Loadout` + `Score` whenever shown or changed.

### Player
`components/Player/Player.gd`: acceleration-based movement with dampening
(`acceleration_force`, `dampening`, `max_speed`, slower `max_speed_shooting`
while holding fire). Shooting uses the equipped weapon (see above).
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
- "Upgrade ship" (`UpgradeShip`) and `ShopItem` are stubs; `ShopItem.tscn` and `FireBullet.tscn` are still in Godot 3 text format (`format=2`) but load fine.
- Money (`Score`) and any future purchases/upgrades only live in memory; nothing is saved to disk yet.
- "Start next level" always starts Level 1; there is no level progression yet.

## Skills
Project skills for agents are in `.claude/skills/`:
- `godot-validate` — verify changes (validate, headless run, screenshots).
- `godot-scene-editing` — safely hand-edit `.tscn`/`.tres` files.
- `gdscript-godot4` — GDScript 4 idioms and Godot 3→4 pitfalls.
- `shmup-content` — add enemies, bullets, waves and bosses the way this project does it.
- `record-demo` — record short gameplay videos with a scripted, cheating autoplay; videos go in `demo/`.

<!-- TODO (owner): add design goals, planned features, art/style direction, balancing notes. -->
