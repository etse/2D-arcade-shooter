---
name: shmup-content
description: Project-specific recipes for adding gameplay content to "The invasion" — new enemy types, bullets/weapons, enemy waves, bosses, and levels — following the existing wave protocol and group-based collision model. Use when adding or changing enemies, weapons, waves, bosses or level flow.
---

# Adding content to The invasion

Read `AGENTS.md` (Architecture section) first. Then pick a recipe. After any
recipe: `tools/validate.sh`, a headless run of `Level.tscn`, and a screenshot
if it's visible (skill `godot-validate`). Scene text-editing rules: skill
`godot-scene-editing`.

## Contract every enemy must satisfy

An enemy is an `Area2D` scene that:
1. `add_to_group("enemies")` in `_ready()` — bullets and the player only interact with this group.
2. Implements `on_hit(damage: float)` — called by friendly bullets and on player ramming.
3. On death: disables its `CollisionShape2D` (so it stops taking hits), calls `Score.add_score(points)`, optionally `CameraControl.screen_shake(...)`, plays explosion, then `queue_free()`s.
4. Is freed if it leaves the screen without dying. Current waves do this by ending the movement tween below the screen and `queue_free()`ing on `tween.finished`; a `VisibleOnScreenNotifier2D` + `screen_exited` also works.

## Recipe: new enemy type

1. Copy `components/Enemies/BasicEnemy/` to `components/Enemies/<Name>/`, rename files to `<Name>.tscn` / `<Name>.gd`.
2. In the new `.tscn`: rename the root node, repoint the script ext_resource to the new `.gd`, remove the copied `uid=` values (header + script ext_resource).
3. In the new `.gd`: either `extends BasicEnemy` and override (preferred for small variations — tweak `health`, `points`, add shooting), or change `class_name` to `<Name>`.
4. For a shooting enemy: extend `Gunship` or copy its `_fire()` (`EnemyBullet`s into `Bullet.layer(self)`); older pattern: `SimpleBoss.gd` — `ShootTimer` + `Marker2D` gun(s) + a `Bullets` child; bullets need `friendly = false` and a downward `speed` (`Vector2(0, +N)`).
5. Sprites: frames are in `assets/sprites/enemies/` (see existing `SpriteFrames`/textures in BasicEnemy.tscn).

## Recipe: new bullet / weapon

- Bullet scenes live in `components/Bullets/<Name>/` and use `components/Bullets/bullet.gd` (`class_name Bullet`): `speed: Vector2` (negative y = up), `damage`, `friendly`.
- Required children used by `bullet.gd`: `Sprite2D`, `HitSound`, `Timer` (wired to `_on_Timer_timeout`), `Particles`. Easiest is to copy `FireBullet/`.
- Weapons are `WeaponData` resources (`components/Weapons/<Name>/<Name>.tres`, script `components/Weapons/WeaponData.gd`) with per-level stat arrays and upgrade prices; all arrays must have the same length (= max level). Also set `price` and `fire_pattern` (and `spread_angle` for SPREAD). Copy `PulseFire.tres` or `SpreadFire.tres` for a new weapon, and add it to `Loadout.WEAPONS` so the shop lists it.
- The equipped weapon + level live in the `Loadout` autoload; `WeaponGun.fire()` (`components/Weapons/WeaponGun.gd`, used by both `Player` and the shop preview) dispatches on `WeaponData.fire_pattern` (`PULSE`, `SPREAD`) and returns the delay until the next shot. A new firing pattern (e.g. homing) = new enum value + a `_fire_<pattern>()` function there.
- The shop UI (`components/Menu/WeaponShop/`) reads everything from `Loadout`/`WeaponData`; balance changes need no UI work, and a weapon added to `Loadout.WEAPONS` shows up in the shop list and preview automatically.

## Recipe: new wave (preferred: TimelineWave)

For straight / gunship / squad / path spawns, extend `TimelineWave`
(`screens/Level/levels/TimelineWave.gd`) and override `beats()` — see the
Level 2 waves (`screens/Level/levels/Level2/*.gd`) for examples. Add a `Node`
with the script (and `beat_time`) under the level's `Waves`; no other nodes
needed. Add new spawn kinds to `TimelineWave._spawn()` so every level gets them.

## Recipe: new wave (hand-written)

Waves are plain `Node`s under the level's `Waves` implementing:

```gdscript
extends Node

func start() -> void:        # begin spawning
	pass

func update(delta: float) -> bool:   # return true when finished → Level1 advances
	return false

func exit() -> void:         # stop timers, clean up
	pass
```

Steps:
1. Write `screens/Level/levels/Level1/<WaveName>.gd` (copy `01_SimpleFighters.gd` for timer + tween spawning or `Formation.gd` for `Path2D` paths).
2. In `Level1.tscn`, attach the script to a node under `Waves` (placeholders exist: `HordeEvade`, `CalmBeforeBoss`). Add its children: a `Timer` (connect `timeout` → `_on_Timer_timeout`), `Points/` `Marker2D`s and/or `Path2D`s, and an `Enemies` node to parent spawns.
3. Add the node to the `waves` array in `Level1.gd` at the right position.
4. Make `update()` return true eventually (by spawn count, by time, or when `$Enemies.get_child_count() == 0` after spawning ends). A wave that never returns true stalls the level.
5. Coordinates: the play area is the 1920×1080 viewport; y < 0 is above the screen (spawn there), the player sits near y ≈ 950.

## Recipe: boss

Follow `components/Bosses/SimpleBoss/` + `screens/Level/levels/Level1/BossBattle.gd` (simple), or `components/Bosses/Dreadnought/` + `Level2/BossBattle.gd` (boss runs its own phases and bullet patterns; `Bullet.layer(self)` for its bullets):
boss scene emits `destroyed` when its death sequence finishes; the battle wave
drives movement with tweens (created on the boss) in a loop while the boss is
alive, and its `update()` returns true once `destroyed` has fired (it then
`queue_free()`s the boss). Do the same for new bosses so the level can end.

## Recipe: new level

Copy `screens/Level/levels/Level2/` (generic `Level2.gd` runs `$Waves` children
in order) to `LevelN/`, rename the root node/script, and append the scene path
to `Campaign.LEVELS` (`components/Singletons/Campaign.gd`). `Level.gd`
instances `Campaign.level_scene()`; the root must have `signal completed`.
Background is built from `InfinityScroll` instances (`texture`,
`scroll_speed`, `alpha`, `tint`). Jump straight to it in demos/tests with
`goto_level(n)` from the record-demo `demo_base.gd`.

## Balancing reference (current values)

| Thing | Value |
| --- | --- |
| Player health / regen | 60 / 2 per s (0.5 while shooting); ramming costs 15, a boss fireball 20 |
| Pulse fire lvl 1 → 10 | price $300; dmg 2 → 6, bullets 2 → 5, interval 0.4 → 0.2 s, DPS 10 → 150; upgrades $500 … $19000, each ~1.6× the last ($51250 total) — `PulseFire.tres` |
| Spread fire lvl 1 → 10 | price $400; dmg 1.5 → 3, bullets/volley 2 → 12, interval 0.24 → 0.2 s, fan 4° → 76°, DPS 12.5 → 180; upgrades $650 … $24000, ~1.3× Pulse fire per step ($64350 total) — `SpreadFire.tres` |
| Ramming | player takes 15, enemy takes 2 |
| BasicEnemy | health 6, points 5 |
| Level income target | perfect Level 1 run ≈ $800–1000 (currently $825); later levels pay more |
| Gunship | health 14, points 15; 3-bullet fan straight down (8° apart) every 1 s at 560 px/s, 10 dmg |
| Dreadnought (Level 2 boss) | health 600, 400 points; orbs 190–340 px/s, 10 dmg |
| Level 2 income | perfect run ≈ $1535 |
| HeavyEnemy | health 24, points 25, flies 7.5 s vs 5 s for basics in `DifferentStrength` |
| SimpleBoss | health 230, 250 points; volley every 0.75 s: twin fireballs (500 px/s) or, every 3rd (every 2nd below half health), a 7-ball 70° fan (360 px/s); 15 dmg |
