extends Area2D
class_name Bullet

export var speed: Vector2 = Vector2(0, -1250)
export var damage: float = 2
export var friendly: bool = true

func _ready():
	add_to_group("bullets")

func _physics_process(delta):
	move_local_y(speed[1] * delta)
	move_local_x(speed[0] * delta)

func _process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies") and friendly:
			body.health -= damage
			queue_free()
		elif body.is_in_group("player") and not friendly:
			body.health -= damage
			queue_free()
		elif body.is_in_group("wall"):
			queue_free()