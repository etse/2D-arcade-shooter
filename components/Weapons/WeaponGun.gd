## Fires a WeaponData at a given level: owns the firing patterns and timing.
## Add it as a child of a ship at the ship's origin. Used by the Player and by
## the weapon shop's preview, so both shoot exactly the same way.
class_name WeaponGun
extends Node2D

## Extra row width (px) per bullet beyond two, so bullets don't overlap.
const PULSE_FIRE_EXTRA_WIDTH = 16.0
## How far (px) each bullet is pushed ahead of its outer neighbour, so volleys
## of 3+ bullets form an arrowhead (middle bullets in front) instead of a line.
const PULSE_FIRE_STAGGER = 20.0
## Random extra angle (degrees, +/-) on each spread fire bullet.
const SPREAD_FIRE_JITTER = 1.0
## Spread fire bullets leave from near the nose (+/- this many px), not the
## wide-set guns, so the fan is centred and low levels hit what's ahead.
const SPREAD_FIRE_MUZZLE_OFFSET = 8.0
## Longest catch-up (s) after a frame hitch, so a lag spike can't dump a burst.
const MAX_SHOT_BACKLOG = 0.1

var weapon: WeaponData:
	set(value):
		if value != weapon:
			_spread_queue.clear()
		weapon = value
var level: int = 1
## Gun positions in the ship's local space.
var left_muzzle := Vector2(-25, -28)
var right_muzzle := Vector2(25, -28)
## Where bullets are added (a plain Node, so they don't move with the ship).
var bullet_parent: Node
## Played once per volley; optional.
var sound: AudioStreamPlayer

var _cooldown := 0.0
## Spread fire: lane indices still to fire in the current volley.
var _spread_queue: Array[int] = []
var _spread_left := true


## Call every physics frame; fires as many shots as are due while `firing`.
func tick(delta: float, firing: bool):
	_cooldown -= delta
	if not firing or weapon == null:
		_cooldown = maxf(_cooldown, 0.0)
		return
	# Fast weapons can fire several bullets per frame; keep the timing exact.
	_cooldown = maxf(_cooldown, -MAX_SHOT_BACKLOG)
	while _cooldown <= 0:
		_cooldown += fire()


## Fires once and returns the seconds until the next shot.
func fire() -> float:
	match weapon.fire_pattern:
		WeaponData.FirePattern.SPREAD:
			return _fire_spread()
		_:
			return _fire_pulse()


## Pulse fire: the whole volley at once, spread evenly between the guns
## (widening a little per extra bullet), straight ahead. Inner bullets spawn
## further ahead than outer ones, so the volley forms an arrowhead.
func _fire_pulse() -> float:
	var count := weapon.get_bullet_count(level)
	var left := left_muzzle
	var right := right_muzzle
	var extra_width: float = PULSE_FIRE_EXTRA_WIDTH * maxi(count - 2, 0)
	left.x -= extra_width / 2.0
	right.x += extra_width / 2.0
	var center := (count - 1) / 2.0
	for i in count:
		var t := 0.5 if count == 1 else float(i) / (count - 1)
		var offset := left.lerp(right, t)
		# Rings from the edge: 0 for the outermost bullets, highest in the middle.
		offset.y -= PULSE_FIRE_STAGGER * floorf(center - absf(i - center))
		_spawn_bullet(offset, 0.0)
	_play_sound()
	return weapon.get_fire_interval(level)


## Spread fire: a minigun. Fires ONE bullet per call, alternating sides; the
## volley's `bullet_count` bullets are fanned out over `spread_angle` in lanes,
## fired in shuffled order (left/right lanes alternating) over `fire_interval`.
func _fire_spread() -> float:
	var count := weapon.get_bullet_count(level)
	if _spread_queue.is_empty():
		_spread_queue = _spread_volley_order(count)
		_play_sound()
	var lane: int = mini(_spread_queue.pop_front(), count - 1)
	var spread := weapon.get_spread_angle(level)
	var angle := 0.0 if count == 1 else lerpf(-spread / 2.0, spread / 2.0, float(lane) / (count - 1))
	angle += randf_range(-SPREAD_FIRE_JITTER, SPREAD_FIRE_JITTER)
	# Left lanes come out of the left muzzle, right lanes out of the right one.
	var left_side := angle < 0.0 if absf(angle) > SPREAD_FIRE_JITTER else _spread_left
	_spread_left = not left_side
	var muzzle := left_muzzle.lerp(right_muzzle, 0.5)
	muzzle.x += -SPREAD_FIRE_MUZZLE_OFFSET if left_side else SPREAD_FIRE_MUZZLE_OFFSET
	_spawn_bullet(muzzle, angle)
	return weapon.get_fire_interval(level) / count


## Shuffled lane order for one spread volley, alternating left and right lanes.
func _spread_volley_order(count: int) -> Array[int]:
	var left: Array[int] = []
	var right: Array[int] = []
	for lane in floori(count / 2.0):
		left.append(lane)
		right.append(count - 1 - lane)
	left.shuffle()
	right.shuffle()
	var order: Array[int] = []
	for k in left.size():
		order.append(left[k])
		order.append(right[k])
	if count % 2 == 1:
		order.insert(randi_range(0, order.size()), floori(count / 2.0))
	return order


func _spawn_bullet(local_pos: Vector2, angle_deg: float):
	var bullet = weapon.bullet_scene.instantiate()
	bullet.damage = weapon.get_damage(level)
	bullet.position = get_global_transform() * local_pos
	bullet.rotation = global_rotation + deg_to_rad(angle_deg)
	bullet_parent.add_child(bullet)


func _play_sound():
	if sound:
		sound.play()
