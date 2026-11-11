---
name: gdscript-godot4
description: GDScript 2.0 (Godot 4.x) idioms, best practices and Godot 3→4 migration pitfalls. Use when writing or reviewing any GDScript in this repo, or when fixing code that still looks like Godot 3.
---

# GDScript for Godot 4

This project was ported from Godot 3, so old idioms appear in existing code.
Write new code in Godot 4 style; fix old idioms when you touch the code.

## Godot 3 → 4 cheat sheet

| Godot 3 | Godot 4 |
| --- | --- |
| `export var x = 1` / `onready var` | `@export var x := 1` / `@onready var` |
| `yield(obj, "signal")` | `await obj.signal` |
| `connect("sig", self, "_method")` | `sig.connect(_method)` |
| `emit_signal("sig", a)` | `sig.emit(a)` |
| `Tween` node + `interpolate_property` + `tween_completed` | `var t := create_tween(); t.tween_property(obj, "prop", to, dur)`; `await t.finished` or `t.finished.connect(...)` |
| `instance()` | `instantiate()` |
| `change_scene("res://...")` | `get_tree().change_scene_to_file("res://...")` |
| `KinematicBody2D` + `move_and_slide(vel)` | `CharacterBody2D`; set `velocity`, call `move_and_slide()` |
| `Position2D` | `Marker2D` |
| `rand_range` | `randf_range` / `randi_range` |
| `db2linear` / `linear2db` | `db_to_linear` / `linear_to_db` |
| `OS.window_fullscreen = true` | `get_window().mode = Window.MODE_FULLSCREEN` |
| `offset` on PathFollow2D | `progress`; `unit_offset` → `progress_ratio` |
| `$Sprite` | `$Sprite2D` |

Tweens in Godot 4 start automatically; calling `.play()` is unnecessary. A
tween created with `create_tween()` is bound to that node and dies with it.
Only one tween should animate a given property at a time — kill the old one
(`if _t and _t.is_valid(): _t.kill()`), see `ScreenShake.gd`.

## Style

- Static typing: `var speed: float = 100.0`, `func on_hit(damage: float) -> void:`. Use `:=` for inferred types.
- snake_case for vars/functions, PascalCase for `class_name` and node names, CONSTANT_CASE for consts.
- Declare signals with typed args: `signal health_changed(health: float)`.
- `class_name` only for types other scripts need to reference/type-check (e.g. `Bullet`, `BasicEnemy`).
- Order: `class_name`/`extends`, signals, enums, consts, `@export`, vars, `@onready`, `_ready`, other virtuals, public methods, `_private` methods, signal handlers.
- Tabs for indentation (Godot default). Don't mix with spaces.

## Practices

- **Physics vs frame**: movement in `_physics_process(delta)`; visuals/UI in `_process`. Always multiply by `delta`.
- **Node references**: cache with `@onready var sprite: Sprite2D = $Sprite2D`. Use `%UniqueName` for nodes that may move in the tree.
- **Call down, signal up**: parents call methods on children; children emit signals to parents. Cross-scene/global events go through an autoload (here `CameraControl`, `Score`).
- **Freeing**: `queue_free()`, never `free()` during physics/signal callbacks. Check `is_instance_valid(node)` before using nodes that may have been freed (e.g. after an `await`).
- **Await gotcha**: after `await`, the node may have left the tree. Guard with `if not is_inside_tree(): return`.
- **Spawning**: `preload()` scenes used at runtime; add bullets to a node that won't move with the shooter (bullets here are added to a `Bullets` child with global position computed via `get_global_transform() * marker.position`).
- **Off-screen cleanup**: anything spawned must eventually `queue_free()` (e.g. `VisibleOnScreenNotifier2D.screen_exited`), or the tree grows forever.
- **Groups** for type-ish checks: `add_to_group("enemies")`, `is_in_group(...)`; duck-type with `has_method("on_hit")`.
- **Timers**: prefer `Timer` nodes or `await get_tree().create_timer(t).timeout` over manual delta counters for one-off delays.
- **Randomness**: `randf_range`, `randi_range`, `pick_random()` on arrays.
- **Don't** put game logic in `_input` for continuous actions — read `Input.is_action_pressed()` in `_physics_process`. Use `_unhandled_input` for gameplay so UI can consume events first.

## Debugging

- `print()`, `print_debug()` (adds file:line), `push_warning()`, `push_error()`, `assert(cond, "msg")` (debug builds only).
- `print_tree_pretty()` on a node to dump its subtree at runtime.
- Errors at runtime show as `SCRIPT ERROR:` with `at: func (res://file.gd:line)` in stdout — run headless (see `godot-validate`).
