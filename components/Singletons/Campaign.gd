## Level progression: which level "Start next level" plays. Advances when a
## level is completed (Level.gd); after the last level it replays the last one.
## In memory only, like Score and Loadout.
extends Node

const LEVELS: Array[String] = [
	"res://screens/Level/levels/Level1/Level1.tscn",
	"res://screens/Level/levels/Level2/Level2.tscn",
]

## Index into LEVELS of the next level to play.
var level_index := 0


func level_number() -> int:
	return level_index + 1


func level_scene() -> PackedScene:
	return load(LEVELS[level_index])


func complete_level() -> void:
	level_index = mini(level_index + 1, LEVELS.size() - 1)
