## Labelled slider row in the menu (weapon-shop) style. The HSlider inside
## takes the keyboard focus (Left/Right adjust); the row lights up meanwhile.
extends PanelContainer

@export var label: String = ""
@export var maxValue: float = 100.0
@export var value: float = 100.0:
	set(new_value):
		value = new_value
		if is_node_ready():
			$VBox/HSlider.value = new_value
			_update()
## Shown in the owning menu's hint bar while the slider is focused.
@export var hint: String = "Left/Right: adjust."

signal value_changed(value: float)

@onready var slider: HSlider = $VBox/HSlider


func _ready():
	slider.max_value = self.maxValue
	slider.value = self.value
	$VBox/Header/Label.text = self.label
	slider.focus_entered.connect(_update)
	slider.focus_exited.connect(_update)
	_update()


func _gui_input(event: InputEvent):
	# Hover (real mouse movement) moves the keyboard focus here, like MenuRow.
	if event is InputEventMouseMotion and not slider.has_focus():
		slider.grab_focus()


func _on_HSlider_value_changed(new_value: float):
	value = new_value
	value_changed.emit(new_value)


func _update():
	var lit := slider.has_focus()
	add_theme_stylebox_override("panel", UIStyle.ROW_SELECTED if lit else UIStyle.ROW)
	$VBox/Header/Label.add_theme_color_override("font_color", UIStyle.GOLD if lit else Color.WHITE)
	$VBox/Header/Value.text = "%d%%" % roundi(slider.value)
