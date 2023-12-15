extends Control

@onready var currentPanel = $MenuContainer/MainMenu
@onready var levelScene = "res://screens/Level/Level.tscn"

func _switch_panel(toPanel: Object):
	toPanel.modulate = Color(1, 1, 1, 0)
	toPanel.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(currentPanel, "modulate:a", 0, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.play()
	tween.tween_property(toPanel, "modulate:a", 1, 0.1).set_trans(Tween.TRANS_LINEAR)
	tween.play()
	await tween.finished
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
