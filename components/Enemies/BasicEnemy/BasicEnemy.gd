extends Area2D
class_name BasicEnemy

@export var health: float = 6
@export var points = 10

func _ready():
	add_to_group("enemies")
	
func _process(delta):
	if health <= 0 and not $CollisionShape2D.disabled:
		self.on_destroyed()
		
func on_destroyed():
	var tween = create_tween()
	$CollisionShape2D.disabled = true
	$Explosion.visible = true
	$ExplosionSound.play()
	$Explosion.play()
	tween.tween_property($Sprite2D, "modulate", Color(1, 1, 1, 0), 0.3).set_trans(Tween.TRANS_LINEAR)
	tween.play()
	CameraControl.screen_shake(3, 20, 0.3)
	Score.add_score(self.points)
	
func on_hit(damage: float):
	health -= damage
	$AnimationPlayer.play("Hit")
	CameraControl.screen_shake(3, 20, 0.07)

func _on_ExplosionSound_finished():
	queue_free()

func _on_Explosion_animation_finished():
	$Explosion.visible = false
