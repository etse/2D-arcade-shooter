## Stats, upgrade levels and shop info for one weapon type.
## Arrays are indexed by level - 1, so their length is the weapon's max level.
class_name WeaponData
extends Resource

@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
## Bullet scene to spawn; must use components/Bullets/bullet.gd.
@export var bullet_scene: PackedScene

@export_group("Per level")
## Damage per bullet.
@export var damage: PackedFloat32Array = []
## Bullets fired per volley.
@export var bullet_count: PackedInt32Array = []
## Seconds between volleys.
@export var fire_interval: PackedFloat32Array = []
## Price to upgrade FROM this level to the next (last entry unused).
@export var upgrade_cost: PackedInt32Array = []


func max_level() -> int:
	return damage.size()


func get_damage(level: int) -> float:
	return damage[_index(level)]


func get_bullet_count(level: int) -> int:
	return bullet_count[_index(level)]


func get_fire_interval(level: int) -> float:
	return fire_interval[_index(level)]


## Price to upgrade from `level` to `level + 1`, or -1 if already at max level.
func get_upgrade_cost(level: int) -> int:
	if level >= max_level():
		return -1
	return upgrade_cost[_index(level)]


func _index(level: int) -> int:
	return clampi(level, 1, max_level()) - 1
