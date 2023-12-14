extends Node

@export var texture: CompressedTexture2D
@export var scroll_speed: float
@export var alpha: float = 1

func _ready():
	$texture_1.texture = texture
	$texture_2.texture = texture
	$texture_1.modulate = Color(1, 1, 1, alpha)
	$texture_2.modulate = Color(1, 1, 1, alpha)
	$texture_1.position = Vector2(0, -texture.get_height())
	$texture_2.position = Vector2(0, 0)
	
func _physics_process(delta: float):
	var screen_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	
	var movement = delta * scroll_speed;
	$texture_1.position.y += movement
	$texture_2.position.y = $texture_1.position.y + $texture_1.get_rect().size.y
	
	if $texture_2.position.y > screen_height:
		$texture_2.position.y = $texture_1.position.y - $texture_2.get_rect().size.y
		var pos_text1 = $texture_1.position;
		$texture_1.position = $texture_2.position;
		$texture_2.position = pos_text1
