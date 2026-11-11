## In-game HUD in the weapon-shop style: money + equipped weapon bottom-left,
## hull (health) as a segmented bar bottom-right.
extends CanvasLayer

const HEALTH_SEGMENTS := 20
## Seconds the bar takes to slide to a new health value.
const HEALTH_TWEEN_TIME := 0.3

@onready var _money: Label = $Status/HBox/Money/ScoreLabel
@onready var _bar: HBoxContainer = $Hull/VBox/HealthBar
@onready var _value: Label = $Hull/VBox/Header/Value

var _max_health := 100.0
## Health currently drawn (tweened towards the real value).
var _shown_health := 100.0:
	set(value):
		_shown_health = value
		_draw_health()


func _ready():
	for i in HEALTH_SEGMENTS:
		var segment := ColorRect.new()
		segment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bar.add_child(segment)
	Score.score_changed.connect(func(_score): _update_money())
	Loadout.changed.connect(_update_weapon)
	_update_money()
	_update_weapon()
	_draw_health()


func set_max_health(health: float):
	_max_health = maxf(health, 1.0)
	_shown_health = minf(_shown_health, _max_health)


func update_health(health: float):
	create_tween().tween_property(self, "_shown_health", health, HEALTH_TWEEN_TIME)


func _update_money():
	_money.text = "$%d" % Score.score


func _update_weapon():
	$Status/HBox/Icon.texture = Loadout.weapon.icon
	$Status/HBox/Weapon/Name.text = Loadout.weapon.name
	$Status/HBox/Weapon/Power.text = "Power %d / %d" % [Loadout.weapon_level, Loadout.weapon.max_level()]


## Lit segments for the remaining hull; green > 50%, gold > 25%, red below.
func _draw_health():
	if not is_node_ready():
		return
	var fraction := clampf(_shown_health / _max_health, 0.0, 1.0)
	var color := UIStyle.GREEN if fraction > 0.5 else UIStyle.GOLD if fraction > 0.25 else UIStyle.RED
	var lit := ceili(fraction * HEALTH_SEGMENTS)
	var segments := _bar.get_children()
	for i in segments.size():
		segments[i].color = color if i < lit else UIStyle.EMPTY
	_value.text = "%d%%" % ceili(fraction * 100.0)
	_value.add_theme_color_override("font_color", color)
