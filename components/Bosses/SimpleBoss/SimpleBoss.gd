extends Area2D

@export var health: float = 230
## Money awarded when the boss is destroyed.
@export var points: int = 250
var exploded = false
var explosionSound = 0
signal destroyed;
@onready var fireball = preload('res://components/Bullets/FireBall/FireBall.tscn')

func _ready():
	add_to_group("enemies")
	max_health = health

func _process(delta):
	if health <= 0 and not exploded:
		$ShootTimer.stop()
		self.playExplosion()
	
func playExplosion():
	self.exploded = true
	var tween = create_tween()
	Score.add_score(points)
	CameraControl.screen_shake(14, 25, 1.2)
	$CollisionShape2D.disabled = true
	$Explosion/ExplosionSoundTimer.start()
	$Explosion/ExplosionAnim.visible = true
	$Explosion/ExplosionAnim.play()
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.7).set_trans(Tween.TRANS_EXPO)
	tween.play()
	
func startShooting():
	if not self.exploded:
		$ShootTimer.start(VOLLEY_INTERVAL)

func _on_ExplosionAnim_animation_finished():
	$Explosion/ExplosionAnim.visible = false

func _on_ExplosionSoundTimer_timeout():
	self.explosionSound += 1
	match self.explosionSound:
		1:
			$Explosion/ExplosionSound1.play()
		2:
			$Explosion/ExplosionSound2.play()
		3:
			$Explosion/ExplosionSound3.play()
		_:
			$Explosion/ExplosionSoundTimer.stop()

func _on_ExplosionSound3_finished():
	destroyed.emit()
	
func on_hit(damage: float):
	if not exploded:
		self.health -= damage
		$AnimationPlayer.play("Hit")
		CameraControl.screen_shake(2, 12, 0.2)

## Tutorial boss: a steady, predictable rhythm. Twin shots straight down from
## the wing guns, and every FAN_EVERY-th volley a wide fan from the nose instead
## (dodge through the gaps). Below half health the fans come twice as often.
const VOLLEY_INTERVAL := 0.75
const FAN_EVERY := 3
const FAN_COUNT := 7
const FAN_ANGLE := 70.0        # degrees covered by the fan, centred straight down
const FIREBALL_SPEED := 500.0
const FAN_SPEED := 360.0
const FIREBALL_DAMAGE := 15.0
var volley := 0
var max_health: float

func createFireball(speed: float, angle_deg := 0.0):
	var bullet = fireball.instantiate()
	bullet.friendly = false
	bullet.speed = Vector2(0, speed)
	bullet.rotation = deg_to_rad(angle_deg)   # bullets fly along local +y
	bullet.damage = FIREBALL_DAMAGE
	return bullet

func _on_ShootTimer_timeout():
	volley += 1
	var fan_every := FAN_EVERY if health > max_health / 2 else 2
	if volley % fan_every == 0:
		_fire_fan()
	else:
		_fire_twin()

func _fire_twin():
	for gun in [$LeftGun, $RightGun]:
		var bullet = createFireball(FIREBALL_SPEED)
		bullet.position = get_global_transform() * gun.position
		$Bullets.add_child(bullet)

func _fire_fan():
	var nose = get_global_transform() * Vector2(0, 150)
	for i in FAN_COUNT:
		var angle = -FAN_ANGLE / 2 + i * FAN_ANGLE / (FAN_COUNT - 1)
		var bullet = createFireball(FAN_SPEED, angle)
		bullet.position = nose
		bullet.scale = Vector2(0.75, 0.75)
		$Bullets.add_child(bullet)
