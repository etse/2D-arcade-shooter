extends Area2D
class_name Bullet

@export var speed: Vector2 = Vector2(0, -1600)
@export var damage: float = 2
@export var friendly: bool = true
var destroyed = false

func _ready():
	add_to_group("bullets")


## Where enemies should put the bullets they fire: the level's "projectiles"
## layer (drawn below the fade overlay, survives the shooter), else the scene.
static func layer(from: Node) -> Node:
	var node := from.get_tree().get_first_node_in_group("projectiles")
	return node if node != null else from.get_tree().current_scene

## How far outside the visible screen (in pixels) a bullet may travel before it is freed.
const OFFSCREEN_MARGIN := 200.0

func _physics_process(delta):
	move_local_y(speed[1] * delta)
	move_local_x(speed[0] * delta)
	if not destroyed and _is_far_offscreen():
		queue_free()

func _is_far_offscreen() -> bool:
	# Position in screen space, so camera movement/shake is accounted for.
	var screen_pos := get_global_transform_with_canvas().origin
	return not get_viewport_rect().grow(OFFSCREEN_MARGIN).has_point(screen_pos)

func _process(delta):
	if not destroyed:
		for body in get_overlapping_areas():
			if body.is_in_group("enemies") and friendly:
				on_collision(body)
				
		for body in get_overlapping_bodies():
			if body.is_in_group("player") and not friendly:
				on_collision(body)

func on_collision(body):
	if body.has_method("on_hit"):
		# Enemy bullets hit harder in New Game+.
		body.on_hit(damage if friendly else Campaign.enemy_damage(damage))
	destroyed = true
	$Sprite2D.visible = false
	$HitSound.play()
	speed = Vector2(0, 0)
	$Timer.start()
	$Particles.emitting = true

func _on_Timer_timeout():
	$Particles.emitting = false
	queue_free()
