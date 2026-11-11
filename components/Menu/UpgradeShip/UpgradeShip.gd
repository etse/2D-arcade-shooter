## "Upgrade ship" panel — placeholder until ship upgrades exist.
extends VBoxContainer

signal back

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		%GoBack.focus_quietly()

func _input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back.emit()

func _on_GoBack_selected():
	back.emit()
