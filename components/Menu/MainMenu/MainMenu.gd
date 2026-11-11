extends VBoxContainer

signal StartGame
signal UpgradeWeapon
signal UpgradeShip
signal Options

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	# Give keyboard focus back when returning from another panel.
	if visible:
		$StartGame.grab_focus()


func _on_StartGame_selected():
	emit_signal("StartGame")

func _on_UpgradeWeapon_selected():
	emit_signal("UpgradeWeapon")

func _on_UpgradeShip_selected():
	emit_signal("UpgradeShip")

func _on_Options_selected():
	emit_signal("Options")
