## Stats, upgrade levels and shop info for one weapon type.
## Arrays are indexed by level - 1, so their length is the weapon's max level.
class_name WeaponData
extends Resource

## How the player's ship fires this weapon (see Player.gd fire_weapon()).
enum FirePattern {
	## Whole volley at once, side by side, straight ahead, in an arrowhead.
	PULSE,
	## One bullet at a time, alternating guns, fanned out over `spread_angle`
	## (a volley of `bullet_count` bullets is spread over `fire_interval`).
	SPREAD,
}

@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
## Bullet scene to spawn; must use components/Bullets/bullet.gd.
@export var bullet_scene: PackedScene
@export var fire_pattern: FirePattern = FirePattern.PULSE
## Shop price of the weapon itself (at level 1).
@export var price: int = 0

@export_group("Per level")
## Damage per bullet.
@export var damage: PackedFloat32Array = []
## Bullets fired per volley.
@export var bullet_count: PackedInt32Array = []
## Seconds between volleys.
@export var fire_interval: PackedFloat32Array = []
## Total fan width in degrees (SPREAD only; may be left empty otherwise).
@export var spread_angle: PackedFloat32Array = []
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


func get_spread_angle(level: int) -> float:
	if spread_angle.is_empty():
		return 0.0
	return spread_angle[_index(level)]


## Damage per second if every bullet hits.
func get_dps(level: int) -> float:
	return get_damage(level) * get_bullet_count(level) / get_fire_interval(level)


## Price to upgrade from `level` to `level + 1`, or -1 if already at max level.
func get_upgrade_cost(level: int) -> int:
	if level >= max_level():
		return -1
	return upgrade_cost[_index(level)]


## Everything paid for this weapon at `level`: its price plus all upgrades.
## This is what the player gets back when trading the weapon in.
func get_total_value(level: int) -> int:
	var total := price
	for i in clampi(level, 1, max_level()) - 1:
		total += upgrade_cost[i]
	return total


func _index(level: int) -> int:
	return clampi(level, 1, max_level()) - 1
