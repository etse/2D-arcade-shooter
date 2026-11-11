extends VBoxContainer

@export var label: String = ""
@export var maxValue: float = 100.0
@export var value: float = 100.0:
	set(new_value):
		value = new_value
		if is_node_ready():
			$HSlider.value = new_value

signal value_changed(value: float)

func _ready():
	$HSlider.max_value = self.maxValue
	$HSlider.value = self.value
	$Label.text = self.label

func _on_HSlider_value_changed(new_value: float):
	value = new_value
	value_changed.emit(new_value)
