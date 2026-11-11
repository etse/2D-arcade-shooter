---
name: godot-scene-editing
description: How to safely read and hand-edit Godot 4 text scenes and resources (.tscn, .tres, project.godot) — ext_resource/sub_resource ids, uids, node paths, instancing, signal connections, input map. Use whenever creating or modifying a .tscn/.tres file or project.godot without the editor.
---

# Editing .tscn / .tres by hand

Agents can't use the Godot editor, so scenes are edited as text. The format is
strict; small mistakes make scenes silently lose nodes or fail to load.
Always run `tools/validate.sh` afterwards (see `godot-validate`).

## File anatomy (Godot 4, `format=3`)

```ini
[gd_scene format=3 uid="uid://b1abc..."]          ; load_steps is optional in 4.x; if present keep it = ext+sub count + 1

[ext_resource type="Script" uid="uid://c2def..." path="res://components/Player/Player.gd" id="1_abcd"]
[ext_resource type="PackedScene" path="res://components/Bullets/Bullet.tscn" id="2"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_x1"]
size = Vector2(40, 60)

[node name="Player" type="CharacterBody2D"]        ; root: no parent
script = ExtResource("1_abcd")

[node name="CollisionShape2D" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_x1")

[node name="LeftGun" type="Marker2D" parent="."]
position = Vector2(-20, -30)

[node name="Bullet" parent="Bullets" instance=ExtResource("2")]   ; instanced scene: no type=

[connection signal="timeout" from="Timer" to="." method="_on_Timer_timeout"]
```

Order matters: header → ext_resources → sub_resources → nodes (parents before
children) → connections.

## Rules

- **ids**: `ExtResource("id")`/`SubResource("id")` must match a declared `id` in the same file. Ids are arbitrary strings, unique per file. Pick a new unique one when adding (e.g. `"7_bullet"`); don't renumber existing ones (noisy diffs).
- **uids**: `uid="uid://..."` on ext_resources is optional — `path` is the fallback. When adding a reference by hand, omit `uid` rather than inventing one; Godot fixes it up on the next editor save. Never copy a uid from another resource. For scripts, the real uid is in `<script>.gd.uid`; you may use it.
- **parent paths** are relative to the root: `"."` for direct children, `"Waves/Formation"` for deeper ones. The root node has no `parent`.
- **Instanced scenes**: `instance=ExtResource(...)` and no `type`. Only list properties you override. To edit a child inside an instance, use `parent="InstanceName"` with the existing child's name and only overridden properties (editable children).
- **Connections**: `from`/`to` are node paths relative to the root; `method` must exist on the target's script (wrong names only error at runtime). Method names here use the `_on_NodeName_signal` style — keep script and `.tscn` in sync when renaming.
- **Renaming a node**: update every `parent=` path below it, every `[connection]` `from`/`to`, every `$Path` / `get_node()` / `%Unique` in scripts, and `NodePath(...)` properties (e.g. AnimationPlayer tracks use `"Sprite2D:modulate"`). Grep for the old name first.
- **Default values are omitted** by Godot. Don't add properties set to defaults.
- **Types**: Godot 4 names — `Vector2(x, y)`, `Color(r, g, b, a)`, `PackedStringArray(...)`, `NodePath("..")`, `Rect2`, `Transform2D`. Godot 3 forms (`ExtResource( 1 )` with spaces/int ids, `format=2`, `PoolStringArray`, `Position2D`, `KinematicBody2D`, `Spatial`) are wrong in new content.
- **Never edit** `.import` files or anything in `.godot/` by hand; delete `.godot/` and re-import (`tools/validate.sh` does the import) if the cache seems stale.

## Prefer composition over writing big scenes by hand

To create a new scene similar to an existing one (e.g. a new enemy), copy the
closest existing `.tscn` + `.gd` into a new folder, then:
1. Change the root node name.
2. Point the script `ext_resource` at the new script path and **drop its `uid=`** (and the scene header `uid=`) so they don't collide with the original.
3. Adjust only the properties you need.

Creating nodes from code (`Node.new()`, `add_child`) is also fine and often
simpler for dynamic stuff (see `Formation.gd`).

## project.godot

- Autoloads: `[autoload]` `Name="*res://path.gd"` (the `*` means singleton/global name).
- Input actions in `[input]` are serialized `InputEventKey` objects. Copy an
  existing entry and change `keycode` (e.g. `32` = Space, `4194319..4194322` = Left/Up/Right/Down). Physical keys use `physical_keycode`.
- Keep `config/features` at the current engine version.

## Inspecting scenes quickly

```bash
grep -nE '^\[(node|connection)' path/to/Scene.tscn     # node tree + wiring
grep -rn 'Scene.tscn' --include=*.tscn --include=*.gd . # who uses this scene
```
