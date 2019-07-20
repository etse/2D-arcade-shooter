extends Label

signal selected
export var initial_focus = false

func _ready():
	$AnimationPlayer.play("Reset")
	if initial_focus:
		grab_focus()

func _on_Label_mouse_entered():
	grab_focus()
	
func set_focus():
	self.grab_focus()

func _on_Label_mouse_exited():
	$AnimationPlayer.play("Deselect")

func _on_Label_gui_input(event: InputEvent):
	if event.is_action_pressed("mouse_click") or event.is_action_pressed("ui_accept"):
		$AnimationPlayer.play("Accept")
		yield($AnimationPlayer, "animation_finished")
		emit_signal("selected")

func _on_Label_focus_entered():
	$AnimationPlayer.play("Select")

func _on_Label_focus_exited():
	$AnimationPlayer.play("Deselect")