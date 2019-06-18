extends Area2D

func _ready():
	add_to_group("bullets")

func _physics_process(delta):
	move_local_y(-1250 * delta)

func _process(delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies"):
			body.health -= 2
			queue_free()
	
	if position[1] < -10:
		queue_free()