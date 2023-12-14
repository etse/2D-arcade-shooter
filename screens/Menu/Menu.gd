extends Control

@onready var currentPanel = $MenuContainer/MainMenu
@onready var levelScene = "res://screens/Level/Level.tscn"

func _switch_panel(toPanel):
	toPanel.modulate = Color(1, 1, 1, 0)
	toPanel.visible = true
	$TransitionTween.interpolate_property(currentPanel, "modulate", Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$TransitionTween.start()
	$TransitionTween.interpolate_property(toPanel, "modulate", Color(1, 1, 1, 0), Color(1, 1, 1, 1), 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$TransitionTween.start()
	await $TransitionTween.tween_completed
	currentPanel.visible = false
	currentPanel = toPanel

func _on_MainMenu_Options():
	self._switch_panel($MenuContainer/Options)

func _on_MainMenu_UpgradeShip():
	self._switch_panel($MenuContainer/UpgradeShip)

func _on_MainMenu_StartGame():
	get_tree().change_scene_to_file(levelScene)

func _on_Options_saved():
	self._switch_panel($MenuContainer/MainMenu)
