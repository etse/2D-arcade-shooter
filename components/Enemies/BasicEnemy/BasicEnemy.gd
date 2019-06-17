extends KinematicBody2D

export var health: float = 10
signal destroyed

func _ready():
	add_to_group("enemies")
	
func _process(delta):
	if health <= 0:
		$CollisionShape2D.disabled = true
		$Explosion.visible = true
		$Explosion.play()


func _on_Explosion_animation_finished():
	emit_signal("destroyed")
	queue_free()
