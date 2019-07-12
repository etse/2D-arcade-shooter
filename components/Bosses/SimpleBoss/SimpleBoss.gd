extends KinematicBody2D

export var health: float = 300
var exploded = false
signal destroyed;
onready var fireball = preload('res://components/Bullets/FireBall/FireBall.tscn')

func _ready():
	add_to_group("enemies")

func _process(delta):
	if health <= 0 and not exploded:
		$ShootTimer.stop()
		playExplosion()
	
func playExplosion():
	exploded = true
	$Explosion/ExplosionSoundTimer.start()
	$Explosion/ExplosionAnim.visible = true
	$Explosion/ExplosionAnim.play()
	$Explosion/Tween.interpolate_property($Sprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.7, Tween.TRANS_EXPO, Tween.EASE_IN)
	$Explosion/Tween.start()
	
func startShooting():
	$ShootTimer.start()

func _on_ExplosionAnim_animation_finished():
	$Explosion/ExplosionAnim.visible = false

var explosionSound = 0
func _on_ExplosionSoundTimer_timeout():
	explosionSound += 1
	match explosionSound:
		1:
			$Explosion/ExplosionSound1.play()
		2:
			$Explosion/ExplosionSound2.play()
		3:
			$Explosion/ExplosionSound3.play()
		_:
			$Explosion/ExplosionSoundTimer.stop()

func _on_ExplosionSound3_finished():
	emit_signal("destroyed")

func createFireball():
	var bullet = fireball.instance()
	bullet.friendly = false
	bullet.speed = Vector2(0, 400)
	return bullet

func _on_ShootTimer_timeout():
	var leftBullet = createFireball()
	var rightBullet = createFireball()
	leftBullet.position = get_global_transform().xform($LeftGun.position)
	rightBullet.position = get_global_transform().xform($RightGun.position)
	$Bullets.add_child(leftBullet)
	$Bullets.add_child(rightBullet)
