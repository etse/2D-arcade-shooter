extends Control

func _ready():
	pass

func _on_StartGameButton_pressed():
	get_tree().change_scene("res://screens/Level/Level.tscn")

func _on_OptionsButton_pressed():
	$MenuContainer/OptionsPanel.popup_centered()

func changeAudioVolume(bus: String, volume: float):
	var bus_index = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(bus_index, linear2db(volume / 100))
	if volume == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
		
func getAudioVolume(bus: String):
	var bus_index = AudioServer.get_bus_index(bus)
	return db2linear(AudioServer.get_bus_volume_db(bus_index)) * 100

func _on_MasterVolume_changed(value: float):
	changeAudioVolume("Master", value)

func _on_MusicVolume_changed(value: float):
	changeAudioVolume("music", value)

func _on_SFXVolume_changed(value: float):
	changeAudioVolume("sfx", value)

func _on_OptionsPanel_about_to_show():
	$MenuContainer/OptionsPanel/VerticalContainer/MasterVolume/Slider.value = getAudioVolume("Master")
	$MenuContainer/OptionsPanel/VerticalContainer/MusicVolume/Slider.value = getAudioVolume("music")
	$MenuContainer/OptionsPanel/VerticalContainer/SFXVolume/Slider.value = getAudioVolume("sfx")


func _on_Fullscreen_toggled(fullscreen: bool):
	OS.window_fullscreen = fullscreen
