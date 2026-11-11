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
4. For a shooting enemy: copy the pattern from `SimpleBoss.gd` — `ShootTimer` + `Marker2D` gun(s) + a `Bullets` child; bullets need `friendly = false` and a downward `speed` (`Vector2(0, +N)`).
5. Sprites: frames are in `assets/sprites/enemies/` (see existing `SpriteFrames`/textures in BasicEnemy.tscn).

## Recipe: new bullet / weapon

- Bullet scenes live in `components/Bullets/<Name>/` and use `components/Bullets/bullet.gd` (`class_name Bullet`): `speed: Vector2` (negative y = up), `damage`, `friendly`.
- Required children used by `bullet.gd`: `Sprite2D`, `HitSound`, `Timer` (wired to `_on_Timer_timeout`), `Particles`. Easiest is to copy `FireBullet/`.
- Weapons are `WeaponData` resources (`components/Weapons/<Name>/<Name>.tres`, script `components/Weapons/WeaponData.gd`) with per-level stat arrays and upgrade prices; all arrays must have the same length (= max level). Copy `FocusFire.tres` for a new weapon.
- The equipped weapon + level live in the `Loadout` autoload; `Player.gd` `fire_weapon()` spawns the volley. A new firing pattern (spread, homing) needs code there (or a pattern field on `WeaponData`).
- The shop UI (`components/Menu/WeaponShop/`) reads everything from `Loadout`/`WeaponData`; balance changes need no UI work.

## Recipe: new wave

Waves are plain `Node`s under `Level1/Waves` implementing:

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
2. In `Level1.tscn`, attach the script to a node under `Waves` (placeholders exist: `DifferentStrength`, `Attackers`, `HordeEvade`, `CalmBeforeBoss`). Add its children: a `Timer` (connect `timeout` → `_on_Timer_timeout`), `Points/` `Marker2D`s and/or `Path2D`s, and an `Enemies` node to parent spawns.
3. Add the node to the `waves` array in `Level1.gd` at the right position.
4. Make `update()` return true eventually (by spawn count, by time, or when `$Enemies.get_child_count() == 0` after spawning ends). A wave that never returns true stalls the level.
5. Coordinates: the play area is the 1920×1080 viewport; y < 0 is above the screen (spawn there), the player sits near y ≈ 950.

## Recipe: boss

Follow `components/Bosses/SimpleBoss/` + `screens/Level/levels/Level1/BossBattle.gd`:
boss scene emits `destroyed` when its death sequence finishes; the battle wave
drives movement with tweens (created on the boss) in a loop while the boss is
alive, and its `update()` returns true once `destroyed` has fired (it then
`queue_free()`s the boss). Do the same for new bosses so the level can end.

## Recipe: new level

Duplicate `screens/Level/levels/Level1/` → `Level2/`, then swap the `Level1`
instance in `screens/Level/Level.tscn` (or make `Level.gd` choose the level
dynamically). Background is built from `InfinityScroll` instances
(`texture`, `scroll_speed`, `alpha`).

## Balancing reference (current values)

| Thing | Value |
| --- | --- |
| Player health / regen | 100 / 5 per s (0.5 while shooting) |
| Focus fire lvl 1 → 10 | dmg 2 → 6, bullets 2 → 5, interval 0.4 → 0.2 s; upgrades cost $100 … $2500 ($8700 total) — see `FocusFire.tres` |
| Ramming | player takes 15, enemy takes 2 |
| BasicEnemy | health 6, points 10 |
| SimpleBoss | health 230, 1000 points, fireballs 20 dmg at 500 px/s |
