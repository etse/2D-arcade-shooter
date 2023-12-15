extends Area2D

@export var health: float = 230
var exploded = false
var explosionSound = 0
signal destroyed;
@onready var fireball = preload('res://components/Bullets/FireBall/FireBall.tscn')

func _ready():
	add_to_group("enemies")

func _process(delta):
	if health <= 0 and not exploded:
		$ShootTimer.stop()
		self.playExplosion()
	
func playExplosion():
	self.exploded = true
	var tween = create_tween()
	Score.add_score(1000)
	CameraControl.screen_shake(14, 25, 1.2)
	$CollisionShape2D.disabled = true
	$Explosion/ExplosionSoundTimer.start()
	$Explosion/ExplosionAnim.visible = true
	$Explosion/ExplosionAnim.play()
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.7).set_trans(Tween.TRANS_EXPO)
	tween.play()
	
func startShooting():
	if not self.exploded:
		$ShootTimer.start()

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

func createFireball():
	var bullet = fireball.instantiate()
	bullet.friendly = false
	bullet.speed = Vector2(0, 500)
	bullet.damage = 20.0
	return bullet

func _on_ShootTimer_timeout():
	var leftBullet = createFireball()
	var rightBullet = createFireball()
	leftBullet.position = get_global_transform() * ($LeftGun.position)
	rightBullet.position = get_global_transform() * ($RightGun.position)
	$Bullets.add_child(leftBullet)
	$Bullets.add_child(rightBullet)
