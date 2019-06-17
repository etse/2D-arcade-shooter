extends Area2D

signal hit_enemy(bullet, enemy, damage)

func _ready():
	$Fire
	$Fire.play()
	add_to_group("bullets")

func _process(delta):
	move_local_y(-1250 * delta)
	for body in get_overlapping_bodies():
		if body.is_in_group("enemies"):
			emit_signal("hit_enemy", $Self, body, 2)
			queue_free()
	
	if position[1] < -10:
		queue_free()