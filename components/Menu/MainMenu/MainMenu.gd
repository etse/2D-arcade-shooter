extends VBoxContainer

signal StartGame
signal UpgradeWeapon
signal UpgradeShip
signal Options

func _ready():
	pass


func _on_StartGame_selected():
	emit_signal("StartGame")

func _on_UpgradeWeapon_selected():
	emit_signal("UpgradeWeapon")

func _on_UpgradeShip_selected():
	emit_signal("UpgradeShip")

func _on_Options_selected():
	emit_signal("Options")
