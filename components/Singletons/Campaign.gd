## Level progression and New Game+.
## - Which level "Start next level" plays; advances when a level is completed.
## - Dying restores the money you had when the level started (no farming).
## - Beating the last level shows the victory screen and starts New Game+ at
##   Level 1 with `difficulty` × NG_PLUS_STEP: enemy health, enemy damage and
##   money rewards all scale with it.
## In memory only, like Score and Loadout.
extends Node

const LEVELS: Array[String] = [
	"res://screens/Level/levels/Level1/Level1.tscn",
	"res://screens/Level/levels/Level2/Level2.tscn",
]
const NG_PLUS_STEP := 1.5

## Index into LEVELS of the next level to play.
var level_index := 0
## Completed runs through the whole game (0 = first playthrough).
var ng_plus := 0
## Multiplier for enemy health, enemy damage and money rewards.
var difficulty := 1.0
## Set when the last level was just beaten; the menu shows the victory panel.
var victory_pending := false
var _money_at_level_start := 0


func level_number() -> int:
	return level_index + 1


func level_scene() -> PackedScene:
	return load(LEVELS[level_index])


func is_last_level() -> bool:
	return level_index == LEVELS.size() - 1


## Called by Level.gd when a level starts.
func begin_level() -> void:
	_money_at_level_start = Score.score


## Called by Level.gd when the player dies: money earned in the level is lost.
func fail_level() -> void:
	Score.set_score(_money_at_level_start)


## Called by Level.gd when the level's boss is beaten.
func complete_level() -> void:
	if is_last_level():
		ng_plus += 1
		difficulty *= NG_PLUS_STEP
		level_index = 0
		victory_pending = true
	else:
		level_index += 1


# --- scaling helpers (use these instead of raw numbers) ------------------------------

## Money for destroying something worth `points`.
func reward(points: int) -> int:
	return roundi(points * difficulty)


func enemy_health(health: float) -> float:
	return health * difficulty


func enemy_damage(damage: float) -> float:
	return damage * difficulty


## "1.5", "2.25", … for UI text.
func difficulty_text() -> String:
	return String.num(difficulty, 2)
