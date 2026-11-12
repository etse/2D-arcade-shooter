## Shown in the menu after beating the last level: congratulations + what
## New Game+ means. CONTINUE (or Esc) goes to the main menu.
extends VBoxContainer

signal back

func _ready():
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		%NewGamePlus.text = (
			"New Game+ %d starts at Level 1.\n" % Campaign.ng_plus
			+ "Enemies now have x%s health and hit x%s harder,\n" % [Campaign.difficulty_text(), Campaign.difficulty_text()]
			+ "but every kill pays x%s money.\n" % Campaign.difficulty_text()
			+ "Your money and weapons carry over.")
		%Continue.focus_quietly()

func _input(event: InputEvent):
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back.emit()

func _on_Continue_selected():
	back.emit()
