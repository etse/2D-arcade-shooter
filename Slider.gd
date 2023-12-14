extends VBoxContainer

@export var label: String = ""
@export var maxValue: float = 100.0
@export var value: float = 100.0

signal value_changed

func _ready():
	$HSlider.max_value = self.maxValue
	$HSlider.value = self.value
	$Label.text = self.label

func _on_HSlider_value_changed(value):
	emit_signal("value_changed", value)
