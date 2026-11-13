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
| **Pulse fire** | Shoots straight ahead | High damage, but covers only a narrow part of the screen | Damage, number of bullets, rate of fire |
| **Spread fire** | Minigun-style stream of small bullets fanned across the screen | Hits much more of the screen and higher total DPS, but less damage per bullet than pulse fire | Spread angle, rate of fire, damage, number of bullets |
| **Homing rockets** | Fires missiles that seek enemies | Area-of-effect (AoE) damage on impact | Damage, AoE radius, rate of fire |

Design implications for code: weapon stats and per-level upgrade values should
be data (e.g. a `Resource` per weapon) rather than hard-coded in `Player.gd`,
so new weapons and upgrade levels can be added without new logic, and so the
shop can read names, prices and stats from the same data.

### Current state

Two levels (waves → boss → back to menu). Beating a level unlocks the next (`Campaign`). Dying sends you back to the menu with the money you had when the level started (no farming). Beating the last level shows a Victory panel and starts **New Game+** at Level 1: enemy health, enemy damage and money rewards are multiplied by `Campaign.difficulty` (1.0, then ×1.5 per completed run). Money and weapons carry over.
The **weapon shop** ("Upgrade weapon" in the main menu) is Tyrian-style: a list
of weapons — **Pulse fire** (starting weapon, $300) and **Spread fire** ($400) —
with a live preview of the highlighted weapon and a 10-step power bar. The player
owns one weapon at a time; buying another trades the current one in for its full
value (price + upgrades paid), and power can be raised (pay) or lowered (full
refund of that step) freely.
Ship upgrades ("Upgrade ship" → `UpgradeShip` / `ShopItem` stubs) are not built yet.

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
- **Don't record demo videos unless the user asks for one.** They take minutes and the user will ask when they want one. To check something visual, prefer a screenshot (`tools/screenshot.sh`); a short throw-away recording is OK only when motion itself must be checked, and delete it afterwards.
- There are no automated tests. "Done" = `tools/validate.sh` passes, the
  affected scene runs headless without `SCRIPT ERROR`, and for visual changes a
  screenshot looks right.

## Project layout

```
project.godot                  engine config, autoloads, input map
components/                    reusable scenes, each folder = Scene.tscn + Scene.gd
  Player/                      CharacterBody2D player ship
  Enemies/BasicEnemy/          basic Area2D enemy (class_name BasicEnemy)
  Enemies/HeavyEnemy/          tanky variant: inherited BasicEnemy scene, bigger sprite, more health/points
  Enemies/Gunship/             stops, telegraphs, fires aimed bursts, flies on (extends BasicEnemy, class_name Gunship)
  Bosses/SimpleBoss/           level-1 "tutorial" boss: twin FireBalls + a downward fan every 3rd volley
  Bosses/Dreadnought/          level-2 boss, 3-phase bullet hell (rings / spiral / enraged)
  Bullets/                     bullet.gd (class_name Bullet) + Bullet/FireBullet/SpreadBullet/FireBall/EnemyBullet scenes
  Weapons/                     WeaponData.gd (class_name WeaponData), WeaponGun.gd (firing patterns) + one folder per weapon with its .tres
  CameraEffects/ScreenShake/   shake effect, child of the level's Camera2D
  HUD/                         CanvasLayer: money + weapon panel, segmented hull bar
  UI/                          shared look: UIStyle.gd (colours, fonts, styles), styles/*.tres, MenuRow
  InfinityScroll/              looping vertical background layer
  Menu/                        menu panels (MainMenu, Options, Slider, WeaponShop + WeaponPreview, ShopItem, UpgradeShip, Victory)
  Singletons/                  autoload scripts (Score, CameraControl, Loadout, Campaign)
screens/
  Menu/                        main menu screen (entry point)
  Level/Level.tscn             gameplay shell: walls, HUD, Player, Camera, Projectiles, fade overlay; instances the current level
  Level/levels/TimelineWave.gd data-driven wave base (class_name TimelineWave)
  Level/levels/Level1/         Level1 scene + wave scripts
  Level/levels/Level2/         Level2 scene + TimelineWave waves + Dreadnought battle
assets/                        3rd-party art/music/sfx/fonts (see README for licences)
tools/                         agent/dev helper scripts (validate, screenshot, godot wrapper)
demo/                          recorded demo videos (git-ignored, see skill record-demo)
```

## Architecture

### Autoloads (`project.godot` → `[autoload]`)
- `Score` (`components/Singletons/Score.gd`): `score: int`, `add_score(points)`, `spend(amount) -> bool`, signal `score_changed(score)`. This is the player's money — intentionally never reset between levels/runs.
- `Loadout` (`components/Singletons/Loadout.gd`): the player's equipment — `WEAPONS` (all weapons sold, in shop order), `weapon: WeaponData` and `weapon_level` (starts at 1). `upgrade_weapon()` pays via `Score.spend()`; `downgrade_weapon()` refunds that level's `upgrade_cost`; `buy_weapon(w)` refunds `trade_in_value()` (= `weapon.get_total_value(level)`) and charges `w.price`, resetting to level 1. Both emit `changed`. In memory only, not saved.
- `Campaign` (`components/Singletons/Campaign.gd`): `LEVELS` (level scene paths in order), `level_index` (next level to play), `ng_plus`, `difficulty` (×`NG_PLUS_STEP` 1.5 per completed run), `victory_pending`. `Level.gd` calls `begin_level()` (snapshots `Score`), `fail_level()` on death (restores it via `Score.set_score()`) and `complete_level()` (next level, or after the last: NG+ — `difficulty` ×1.5, back to Level 1, `victory_pending`). **Scaling helpers — every enemy/boss/bullet must use them:** `enemy_health(h)` (in `_ready`), `reward(points)` (for `Score.add_score`), `enemy_damage(d)` (applied centrally in `bullet.gd` for non-friendly bullets and in `Player.gd` for ramming). In memory only.
- `CameraControl` (`components/Singletons/Camera_control.gd`): global event bus for screen shake. Call `CameraControl.screen_shake(amplitude, frequency, duration)`; `Level.gd` forwards it to `$Camera/ScreenShake`.

### Scene flow
`Menu.tscn` → "Start next level" → `change_scene_to_file("res://screens/Level/Level.tscn")`
→ `Level.gd` instances `Campaign.level_scene()` (as `level`, placed below `Projectiles` and the fade `Overlay`)
→ player dies (→ `Campaign.fail_level()`, money restored; ignored once the boss is beaten), or the level emits `completed` after its last wave (→ `Campaign.complete_level()`) → `Level.gd` fades out → back to `Menu.tscn`, which opens the `Victory` panel instead of the main menu when `Campaign.victory_pending` (last level beaten).
The main menu's "Start next level" row shows `Level N` (and `New Game+ N (enemies xF)`) from `Campaign`.
There is no lose screen (dying just fades back to the menu).

### Levels and waves
A level scene (`Level1.tscn`, `Level2.tscn`) has a `Background`, a `Waves` node and
`signal completed`. `Level1.gd` holds an ordered array of wave nodes (`waves`), `Level2.gd`
simply runs `$Waves` children in order; both are the same small state machine and emit
`completed` after the last wave. Each wave is a child `Node` of `Waves` with a script that
implements this informal protocol (duck-typed, no base class):

```gdscript
func start() -> void          # called when the wave becomes active
func update(delta) -> bool    # called every frame; return true when the wave is finished
func exit() -> void           # called once, before the next wave starts
```

Current order: `Wait → SimpleFighters → DifferentStrength → Formation → Attackers → Wait → BossBattle`.
`DifferentStrength` streams basics straight down with slower `HeavyEnemy`s mixed in (data-driven `BEATS` list; ends when all spawned and the screen is clear).
`Attackers` (hardest, last before the boss) = Formation's S-curve fighters at half density + squads (two basics in front of a `HeavyEnemy`, moved as one `Node2D`) alternating left/right; reuses Formation's `Curve2D` sub-resources.
`HordeEvade`, `CalmBeforeBoss` are empty
placeholder nodes not yet wired in. Waves spawn enemies under their own
`Enemies` child and move them with tweens (`SimpleFighters`) or
`Path2D`/`PathFollow2D` (`Formation`). Spawn/target positions are `Marker2D`s
under each wave's `Points` node. Movement tweens are created on the enemy (or
its `PathFollow2D`) so they die with it, and the enemy is `queue_free()`d when
the tween finishes (end points are below the screen). `BossBattle` finishes
when the boss emits `destroyed`.

Level 2 waves extend `TimelineWave` (`screens/Level/levels/TimelineWave.gd`):
override `beats()` → an Array with one entry per beat (every `beat_time` s),
each an Array of spawn specs built with `basic(x, time)`, `heavy(x, time)`,
`gunship(x, stop_y, shoot, exit_x)`, `squad(x, time)` and `path(curve, scene, time)`
(curves from `curves()`); `[]` is a pause. Nodes are created in code, so the
wave node in the `.tscn` only needs the script (+ `beat_time`). It finishes when
every beat has spawned and its `Enemies` node is empty. Level 2 order:
`Wait → Rush → GunshipAmbush → Swarm → HeavyLine → Crossfire → CalmBeforeBoss → BossBattle`.
Its `BossBattle` flies the `Dreadnought` in and calls `start_fight()`; the boss
runs its own movement and patterns (phases at 66 % / 33 % health, `phase_changed`
signal) and frees its bullets (group `"boss_bullets"`) when it dies.

### Combat / collision model
Collision layers/masks are all default; **filtering is done with groups**:
- `"enemies"` — enemies and bosses (Area2D). Must implement `on_hit(damage: float)`.
- `"bullets"` — all bullets (Area2D, `bullet.gd`). `friendly=true` hits `"enemies"`, `friendly=false` hits `"player"`.
- `"player"` — the player body.
- Enemy bullets: `EnemyBullet.tscn` (magenta orb, `friendly=false`, 10 dmg). Shooters put them in the level's `Projectiles` layer via `Bullet.layer(self)` (group `"projectiles"`), so they survive the shooter and are drawn below the fade overlay. Aim by setting `rotation = angle - PI/2` and `speed = Vector2(0, v)` (bullets move along local +y).
- `Gunship` (`components/Enemies/Gunship/`, illumRed09, 14 HP, 15 points): `fly(stop, exit, enter_time, shoot_time, exit_time)` moves in, flashes (0.5 s telegraph), fires a narrow 3-bullet fan straight down (8° apart, 560 px/s) every `shot_interval` s, then leaves and frees itself.
- Bullets free themselves once they are more than `OFFSCREEN_MARGIN` (200 px) outside the visible screen. The `WorldBounds` walls in `Level.tscn` only keep the player on screen.
- Bullets poll `get_overlapping_areas()/bodies()` in `_process` rather than using signals.
- The player takes ramming damage via its `CollisionArea` overlapping `"enemies"`.
- `HeavyEnemy` (`components/Enemies/HeavyEnemy/HeavyEnemy.tscn`) is an *inherited scene* of `BasicEnemy.tscn` with the same script: only sprite (`illumGreenglow07`, ×1.8), circle collision, explosion scale and `health`/`points` are overridden. Make further variants the same way.
- Enemy death: `health <= 0` → explosion anim + sound, `Score.add_score(points)`, screen shake, `queue_free()` when the sound ends.

### Weapons and the shop
- A weapon is a `WeaponData` resource (`components/Weapons/WeaponData.gd`): name, description, icon, `bullet_scene`, `fire_pattern` (`PULSE`/`SPREAD`), `price`, and per-level arrays `damage`, `bullet_count`, `fire_interval`, `spread_angle` (SPREAD only), `upgrade_cost` (index = level − 1; array length = max level; `upgrade_cost[i]` is the price to go from level i+1 to i+2).
- Pulse fire: `components/Weapons/PulseFire/PulseFire.tres` (10 levels; level 1 = 2 dmg, 2 bullets, 0.4 s). Spread fire: `components/Weapons/SpreadFire/SpreadFire.tres` (level 1 = 1.5 dmg, 2 bullets, 0.24 s, 4° fan → level 10 = 3 dmg, 12 bullets, 0.2 s, 76°; upgrades ~1.3× Pulse fire's). Upgrade prices grow ~1.6× per level (Pulse fire $500 → $19000, $51250 to max; Spread fire $650 → $24000, $64350). Rule of thumb: spread does less damage per bullet but more total DPS. Balance by editing the `.tres` files. Income reference / target: a perfect Level 1 run should pay about $800–1000 (now $825: 60 `BasicEnemy` × 5 + 11 `HeavyEnemy` × 25 + `SimpleBoss.points` 250), i.e. roughly one upgrade per level early on; later levels are meant to pay more, so the expensive top levels take several levels of saving. Keep that in mind when adding waves to Level 1. A perfect Level 2 run pays about $1535 (waves ≈ $1135 + `Dreadnought.points` 400).
- Firing lives in `WeaponGun` (`components/Weapons/WeaponGun.gd`, a Node2D at the ship's origin): set `weapon`, `level`, `left_muzzle`/`right_muzzle`, `bullet_parent`, optional `sound`, and call `tick(delta, firing)` every physics frame. `fire()` dispatches on `fire_pattern` and returns the seconds until the next shot; `tick` loops, so several bullets can fire per frame. `Player.gd` creates one in `_ready()` (`player.gun`) and feeds it `Loadout` each frame; the shop preview reuses it, so the preview always matches the game.
  - `PULSE`: the whole volley at once, spread between `$LeftGun` and `$RightGun` (widens by `PULSE_FIRE_EXTRA_WIDTH` per bullet beyond two), straight ahead. Inner bullets spawn `PULSE_FIRE_STAGGER` px further ahead per step from the edge, so 3+ bullets form an arrowhead.
  - `SPREAD` (minigun): ONE bullet per call, every `fire_interval / bullet_count` s, from just left/right of the nose (`SPREAD_FIRE_MUZZLE_OFFSET`, not the wide guns — otherwise level 1 misses what's straight ahead). Each volley's lanes are evenly fanned over `spread_angle`, fired in shuffled order alternating left/right, with ±`SPREAD_FIRE_JITTER`°. Bullets fly along their rotation (`bullet.gd` moves in local space).
- `components/Menu/WeaponShop/` is the shop panel; `Menu.gd` switches to it from MainMenu's `UpgradeWeapon` signal and back on its `back` signal (DONE / Esc).
  - Layout: left = `WeaponPreview` (SubViewport with scrolling stars and a display-only `Player` instance whose `gun` fires the highlighted weapon nonstop), DPS meter (full = strongest weapon in `Loadout.WEAPONS` at max power), power bar `<` `>`; right = list rows built in code from `Loadout.WEAPONS` + DONE, description, stats; bottom = hint/status bar.
  - It does **not** use GUI focus (focus is released when shown): `_input` handles `ui_up/down` (cursor), `ui_left/right` (downgrade/upgrade the equipped weapon), `ui_accept` (buy / DONE), `ui_cancel`. Mouse: rows follow `InputEventMouseMotion` (deliberately not `mouse_entered`, which fires when the panel appears under a resting pointer and steals the cursor), click = accept; `<`/`>` clickable.
  - Public for scripting: `cursor`, `move_cursor(step)`, `accept()`, `change_power(step)`, `highlighted_weapon()`. It rebuilds from `Loadout` + `Score` whenever shown or changed.

### Player
`components/Player/Player.gd`: acceleration-based movement with dampening
(`acceleration_force`, `dampening`, `max_speed`, slower `max_speed_shooting`
while holding fire). Shooting uses the equipped weapon (see above).
Health 60, regenerates `health_regen` 2/s (`health_regen_shooting` 0.5/s while shooting) — 4 rams or 3 fireballs kill. Hitbox: one 28 px radius circle on the ship's core (smaller than the ~100 px sprite on purpose, so you can slip between bullets); shared by bullet hits, ramming and the walls. Signals
`health_changed(health)` and `destroyed`.

### UI look ("weapon shop style")
All menus and the HUD share one look, defined in `components/UI/`:
- `UIStyle.gd` (`class_name UIStyle`): colours (`GOLD`, `TEXT`, `DIM`, `GREEN`, `RED`, …), fonts (`TITLE_FONT` = Arcade, `BOLD_FONT`/`TEXT_FONT` = 8bitOperatorPlus) and the styleboxes in `styles/`: `Frame` (gold-bordered panel), `Window` (black inset, e.g. preview), `Hint` (bottom hint/status bar), `Row`/`RowSelected` (list rows), `Hud` (small in-game panel). Reference these instead of new hard-coded colours/styles.
- Menu panel recipe: gold Arcade title (110 px) inside a `Frame` panel, optional "Money $X" row, a list of rows, and a `Hint` bar below whose text follows the focused row.
- `MenuRow` (`components/UI/MenuRow/`, `class_name MenuRow`): the menu button — [icon] title / detail, right-hand `tag`, `hint`, `disabled`; focus-based (arrow keys via Godot focus), Enter/click → short flash + sound → `selected`. `press()` triggers it from code, `focus_quietly()` focuses without the move sound. Hover follows mouse *motion* only (see the weapon shop note). `Slider` is the matching volume-slider row.
- Menu sounds play at −25 dB on the `sfx` bus (louder stands out).
- Main menu: one full-width `Frame` panel (same size as the weapon shop, 1520×840) with title, money, rows `%StartGame`, `%UpgradeWeapon` ("Weapon shop"), `%UpgradeShip`, `%Options`. Options = fullscreen ON/OFF row, 3 volume sliders, DONE (Esc also goes back). Upgrade ship = "coming soon" + DONE.
- HUD (`components/HUD/`): bottom-left money + equipped weapon (icon, name, power), bottom-right hull bar of 20 segments (green > 50%, gold > 25%, red). API used by `Level.gd`: `set_max_health()`, `update_health()`.

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
- Harmless Godot editor re-save noise (e.g. newly written default properties, reordered `[connection]` lines, `unique_id`s, new `.uid` files) can always be included in commits — don't leave it out or ask about it. Glance at the diff first to be sure it really is only noise.

## Known issues / gotchas
- "Upgrade ship" (`UpgradeShip`, a "coming soon" panel) and `ShopItem` are stubs; `ShopItem.tscn` and `FireBullet.tscn` are still in Godot 3 text format (`format=2`) but load fine.
- Money (`Score`) and any future purchases/upgrades only live in memory; nothing is saved to disk yet.
- Campaign progress (`Campaign.level_index`) is in memory only, like money; a restart begins at Level 1.

## Skills
Project skills for agents are in `.claude/skills/`:
- `godot-validate` — verify changes (validate, headless run, screenshots).
- `godot-scene-editing` — safely hand-edit `.tscn`/`.tres` files.
- `gdscript-godot4` — GDScript 4 idioms and Godot 3→4 pitfalls.
- `shmup-content` — add enemies, bullets, waves and bosses the way this project does it.
- `record-demo` — record short gameplay videos with a scripted, cheating autoplay; videos go in `demo/`.

<!-- TODO (owner): add design goals, planned features, art/style direction, balancing notes. -->
