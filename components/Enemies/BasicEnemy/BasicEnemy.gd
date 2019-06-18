extends KinematicBody2D

export var health: float = 6

func _ready():
	add_to_group("enemies")
	
func _process(delta):
	if health <= 0 and not $CollisionShape2D.disabled:
		$CollisionShape2D.disabled = true
		$Explosion.visible = true
		$ExplosionSound.play()
		$Explosion.play()
		$Tween.interpolate_property($Sprite, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.5, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.start()

func _on_ExplosionSound_finished():
	queue_free()

func _on_Explosion_animation_finished():
	$Explosion.visible = false
