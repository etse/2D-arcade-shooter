## Weapon shop "show-off" window: a little space scene where the player's ship
## keeps firing a given weapon at a given level, using the real WeaponGun
## (via a non-interactive Player instance), so it looks exactly like in-game.
extends SubViewportContainer

const PLAYER_SCENE := preload("res://components/Player/Player.tscn")
## Scroll speeds (px/s) of the two star layers, for a sense of flight.
const STARS_SMALL_SPEED := 40.0
const STARS_BIG_SPEED := 110.0
## Ship distance from the bottom edge.
const SHIP_BOTTOM_MARGIN := 110.0

@onready var _viewport: SubViewport = $Viewport
@onready var _stars_small: TextureRect = $Viewport/StarsSmall
@onready var _stars_big: TextureRect = $Viewport/StarsBig
@onready var _bullets: Node2D = $Viewport/Bullets

var _ship: Node2D
var _time := 0.0


func _ready():
	_ship = PLAYER_SCENE.instantiate()
	_viewport.add_child(_ship)
	# Display only: no movement, input, collisions or health logic.
	_ship.set_physics_process(false)
	_ship.set_process_input(false)
	_ship.remove_from_group("player")
	_ship.get_node("CollisionShape2D").disabled = true
	_ship.gun.bullet_parent = _bullets
	_ship.gun.sound = null  # the menu has its own music; keep it quiet
	_layout()
	_viewport.size_changed.connect(_layout)


## Show `weapon` firing at `level`. Bullets already in flight are cleared when
## the weapon changes, so the old pattern doesn't linger.
func show_weapon(weapon: WeaponData, level: int):
	if weapon != _ship.gun.weapon:
		for bullet in _bullets.get_children():
			bullet.queue_free()
	_ship.gun.weapon = weapon
	_ship.gun.level = level


func _physics_process(delta: float):
	if is_visible_in_tree():
		_ship.gun.tick(delta, true)


func _process(delta: float):
	_time += delta
	_scroll(_stars_small, STARS_SMALL_SPEED)
	_scroll(_stars_big, STARS_BIG_SPEED)


func _scroll(layer: TextureRect, speed: float):
	var height := float(layer.texture.get_height())
	layer.position.y = -height + fmod(_time * speed, height)


func _layout():
	var view := Vector2(_viewport.size)
	_ship.position = Vector2(view.x / 2.0, view.y - SHIP_BOTTOM_MARGIN)
	for layer: TextureRect in [_stars_small, _stars_big]:
		layer.size = Vector2(view.x, view.y + layer.texture.get_height())
