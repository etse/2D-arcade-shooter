extends Area2D
class_name Bullet

export var speed: Vector2 = Vector2(0, -1250)
export var damage: float = 2
export var friendly: bool = true
var destroyed = false

func _ready():
	add_to_group("bullets")

func _physics_process(delta):
	move_local_y(speed[1] * delta)
	move_local_x(speed[0] * delta)

func _process(delta):
	if not destroyed:
		for body in get_overlapping_bodies():
			if body.is_in_group("enemies") and friendly:
				on_collision(body)
			elif body.is_in_group("player") and not friendly:
				on_collision(body)
			elif body.is_in_group("wall"):
				queue_free()
				
				
func on_collision(body):
	body.health -= damage
	destroyed = true
	$Sprite.visible = false
	speed = Vector2(0, 0)
	$Timer.start()
	$Particles.emitting = true

func _on_Timer_timeout():
	queue_free()
