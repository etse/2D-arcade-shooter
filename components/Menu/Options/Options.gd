extends VBoxContainer

signal saved

func _ready():
	$MasterVolume.value = getAudioVolume("Master")
	$MusicVolume.value = getAudioVolume("music")
	$SFXVolume.value = getAudioVolume("sfx")
	
func getAudioVolume(bus: String):
	var bus_index = AudioServer.get_bus_index(bus)
	return db2linear(AudioServer.get_bus_volume_db(bus_index)) * 100
	
func changeAudioVolume(bus: String, volume: float):
	var bus_index = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(bus_index, linear2db(volume / 100))
	if volume == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)
	
func _on_FullScreen_toggled(button_pressed: bool):
	OS.window_fullscreen = button_pressed

func _on_MasterVolume_value_changed(value: float):
	changeAudioVolume("Master", value)

func _on_MusicVolume_value_changed(value: float):
	changeAudioVolume("music", value)

func _on_SFXVolume_value_changed(value: float):
	changeAudioVolume("sfx", value)

func _on_Save_selected():
	emit_signal("saved")
