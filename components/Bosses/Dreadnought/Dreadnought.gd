## Level-2 boss: a slow bullet-hell fight in three phases (by remaining health).
##   1. Rings    – sways side to side, fires rings of slow orbs with a rotating
##                 gap pattern, plus aimed volleys from the wing guns.
##   2. Spiral   – parks in the middle and spins a 3-armed spiral that reverses
##                 direction now and then; occasional aimed volley.
##   3. Enraged  – glows red, sways faster, alternating offset rings (dodge
##                 through the gaps) + aimed fans.
## Bullets are slow and sparse on purpose: it should feel like a bullet hell,
## not punish a level-2 player. Its bullets vanish when it dies.
## The wave flies it in, then calls start_fight(); emits `destroyed` when the
## death sequence has finished (same contract as SimpleBoss).
extends Area2D

signal destroyed
signal phase_changed(phase: int)

const BULLET := preload("res://components/Bullets/EnemyBullet/EnemyBullet.tscn")

@export var health: float = 600.0
## Money awarded when the boss is destroyed.
@export var points: int = 400
@export var bullet_damage := 10.0

var max_health: float
var phase := 0            # 0 = not fighting yet, then 1..3
var exploded := false
var explosionSound := 0
var _sway: Tween
var _time := 0.0          # time in current phase
var _next := {}           # pattern name -> time of next shot
var _spiral_angle := 0.0
var _spiral_dir := 1.0
var _ring_offset := 0.0


func _ready():
	add_to_group("enemies")
	health = Campaign.enemy_health(health)
	max_health = health


func start_fight() -> void:
	_enter_phase(1)


func _process(delta):
	if health <= 0 and not exploded:
		_explode()
		return
	if phase == 0 or exploded:
		return
	if phase == 1 and health < max_health * 0.66:
		_enter_phase(2)
	elif phase == 2 and health < max_health * 0.33:
		_enter_phase(3)
	_time += delta
	match phase:
		1:
			if _due("ring", 2.2):
				_ring(14, 210.0, _ring_offset)
				_ring_offset += 9.0
			if _due("aimed", 3.1, 1.1):
				_aimed_volley(3, 14.0, 320.0)
		2:
			if _due("spiral", 0.2):
				for arm in 3:
					_shoot($Core.global_position, _spiral_angle + arm * TAU / 3, 190.0)
				_spiral_angle += deg_to_rad(10.0) * _spiral_dir
			if _due("reverse", 4.0, 4.0):
				_spiral_dir = -_spiral_dir
			if _due("aimed", 3.5, 2.0):
				_aimed_volley(1, 0.0, 340.0)
		3:
			if _due("ring", 1.9):
				_ring(14, 230.0, _ring_offset)
				_ring_offset += 180.0 / 14   # half the gap: next ring's holes line up with this ring's orbs
			if _due("aimed", 2.3, 0.8):
				_aimed_volley(5, 11.0, 330.0)


## True once every `interval` s (first time after `first` s in the phase).
func _due(pattern: String, interval: float, first := 0.0) -> bool:
	if not _next.has(pattern):
		_next[pattern] = first
	if _time >= _next[pattern]:
		_next[pattern] += interval
		return true
	return false


func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	_time = -1.2       # short breather while it changes stance
	_next.clear()
	phase_changed.emit(phase)
	if new_phase > 1:
		CameraControl.screen_shake(8, 20, 0.6)
		$PhaseSound.play()
		var flash := create_tween()
		flash.tween_property($Sprite2D, "modulate", Color(3, 3, 3), 0.15)
		flash.tween_property($Sprite2D, "modulate", _phase_tint(), 0.6)
	match new_phase:
		1: _start_sway(560.0, 1360.0, 4.5)
		2: _start_sway(860.0, 1060.0, 5.0)
		3: _start_sway(420.0, 1500.0, 3.2)


func _phase_tint() -> Color:
	return Color(1.5, 0.75, 0.75) if phase == 3 else Color.WHITE


func _start_sway(left: float, right: float, half_period: float) -> void:
	if _sway:
		_sway.kill()
	_sway = create_tween().set_loops()
	_sway.tween_property(self, "position:x", right, half_period).set_trans(Tween.TRANS_SINE)
	_sway.tween_property(self, "position:x", left, half_period).set_trans(Tween.TRANS_SINE)


# --- bullet patterns ---------------------------------------------------------------------

func _shoot(from: Vector2, angle: float, speed: float) -> void:
	var bullet: Bullet = BULLET.instantiate()
	bullet.position = from
	bullet.rotation = angle - PI / 2   # bullets fly along local +y
	bullet.speed = Vector2(0, speed)
	bullet.damage = bullet_damage
	bullet.add_to_group("boss_bullets")
	Bullet.layer(self).add_child(bullet)


## `count` orbs evenly around the core, rotated by `offset_deg`.
func _ring(count: int, speed: float, offset_deg: float) -> void:
	for i in count:
		_shoot($Core.global_position, deg_to_rad(offset_deg) + i * TAU / count, speed)
	$ShotSound.play()


## A fan of `count` orbs from each wing gun, aimed at the player.
func _aimed_volley(count: int, spread_deg: float, speed: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	for gun in [$LeftGun, $RightGun]:
		var from: Vector2 = gun.global_position
		var aim := (player.global_position - from).angle()
		for i in count:
			_shoot(from, aim + deg_to_rad((i - (count - 1) / 2.0) * spread_deg), speed)
	$ShotSound.play()


# --- damage & death -------------------------------------------------------------------------

func on_hit(damage: float):
	if not exploded:
		health -= damage
		$AnimationPlayer.play("Hit")
		CameraControl.screen_shake(2, 12, 0.2)


func _explode():
	exploded = true
	phase = 0
	if _sway:
		_sway.kill()
	# Be nice: its bullets disappear with it.
	for bullet in get_tree().get_nodes_in_group("boss_bullets"):
		bullet.queue_free()
	Score.add_score(Campaign.reward(points))
	CameraControl.screen_shake(16, 25, 1.6)
	$CollisionShape2D.disabled = true
	$Explosion/ExplosionSoundTimer.start()
	$Explosion/ExplosionAnim.visible = true
	$Explosion/ExplosionAnim.play()
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 1.0).set_trans(Tween.TRANS_EXPO)


func _on_ExplosionAnim_animation_finished():
	$Explosion/ExplosionAnim.visible = false


func _on_ExplosionSoundTimer_timeout():
	explosionSound += 1
	match explosionSound:
		1: $Explosion/ExplosionSound1.play()
		2: $Explosion/ExplosionSound2.play()
		3: $Explosion/ExplosionSound3.play()
		_: $Explosion/ExplosionSoundTimer.stop()


func _on_ExplosionSound3_finished():
	destroyed.emit()
