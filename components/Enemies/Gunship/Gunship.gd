## Flies in, stops, flashes (telegraph) and fires bursts straight down (a
## narrow fan) for a while, then flies on. Waves drive it with fly(). Otherwise a BasicEnemy.
extends BasicEnemy
class_name Gunship

const BULLET := preload("res://components/Bullets/EnemyBullet/EnemyBullet.tscn")

@export var bullet_speed := 560.0
@export var bullet_damage := 10.0
## Bullets per volley, fanned `burst_spread` degrees apart around straight down.
@export var burst := 3
@export var burst_spread := 8.0
@export var shot_interval := 1.0
## Warning flash before the first volley.
const TELEGRAPH_TIME := 0.5

var _shooting := false
var _cooldown := 0.0


## Move to `stop`, shoot for `shoot_time` s, then leave to `exit` (below the
## screen) and free itself. The tween lives on the ship, so it dies with it.
func fly(stop: Vector2, exit: Vector2, enter_time := 1.3, shoot_time := 3.0, exit_time := 2.5) -> void:
	var t := create_tween()
	t.tween_property(self, "position", stop, enter_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_callback(_begin_shooting)
	t.tween_interval(shoot_time)
	t.tween_callback(func(): _shooting = false)
	t.tween_property(self, "position", exit, exit_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)


func _begin_shooting() -> void:
	_shooting = true
	_cooldown = TELEGRAPH_TIME
	var flash := create_tween()
	flash.tween_property($Sprite2D, "modulate", Color(2.2, 1.2, 1.2), TELEGRAPH_TIME * 0.5)
	flash.tween_property($Sprite2D, "modulate", Color.WHITE, TELEGRAPH_TIME * 0.5)


func _process(delta):
	super(delta)
	if not _shooting or health <= 0:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = shot_interval
		_fire()


func _fire() -> void:
	var muzzle := global_position + Vector2(0, 40)
	for i in burst:
		var bullet: Bullet = BULLET.instantiate()
		bullet.position = muzzle
		# Bullets fly along local +y, so rotation 0 = straight down.
		bullet.rotation = deg_to_rad((i - (burst - 1) / 2.0) * burst_spread)
		bullet.speed = Vector2(0, bullet_speed)
		bullet.damage = bullet_damage
		Bullet.layer(self).add_child(bullet)
	$ShotSound.play()
