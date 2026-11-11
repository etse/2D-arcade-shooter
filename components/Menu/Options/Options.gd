## Options panel (weapon-shop style): fullscreen toggle, volume sliders, DONE.
## Changes apply immediately (not saved to disk).
extends VBoxContainer

signal saved

func _ready():
	%MasterVolume.value = getAudioVolume("Master")
	%MusicVolume.value = getAudioVolume("music")
	%SFXVolume.value = getAudioVolume("sfx")
	for row in [%FullScreen, %Save]:
		row.focus_entered.connect(_show_hint.bind(row.hint))
	for slider in [%MasterVolume, %MusicVolume, %SFXVolume]:
		slider.slider.focus_entered.connect(_show_hint.bind(slider.hint))
	visibility_changed.connect(_on_visibility_changed)
	_update_fullscreen_tag()

func _show_hint(text: String):
	%Text.text = "Up/Down: select.   " + text

func _on_visibility_changed():
	if visible:
		_update_fullscreen_tag()
		%FullScreen.focus_quietly()

func getAudioVolume(bus: String):
	var bus_index = AudioServer.get_bus_index(bus)
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100
	
func changeAudioVolume(bus: String, volume: float):
	var bus_index = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume / 100))
	if volume == 0:
		AudioServer.set_bus_mute(bus_index, true)
	else:
		AudioServer.set_bus_mute(bus_index, false)

func _is_fullscreen() -> bool:
	return get_window().mode == Window.MODE_EXCLUSIVE_FULLSCREEN

func _update_fullscreen_tag():
	%FullScreen.tag = "ON" if _is_fullscreen() else "OFF"
	%FullScreen.tag_color = UIStyle.GREEN if _is_fullscreen() else UIStyle.DIM
	
func _on_FullScreen_selected():
	get_window().mode = Window.MODE_WINDOWED if _is_fullscreen() else Window.MODE_EXCLUSIVE_FULLSCREEN
	_update_fullscreen_tag()

func _on_MasterVolume_value_changed(value: float):
	changeAudioVolume("Master", value)

func _on_MusicVolume_value_changed(value: float):
	changeAudioVolume("music", value)

func _on_SFXVolume_value_changed(value: float):
	changeAudioVolume("sfx", value)

func _on_Save_selected():
	saved.emit()

func _input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		saved.emit()
