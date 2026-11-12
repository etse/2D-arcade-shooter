extends Node
# Basic fighters stream straight down the screen, with a slower, tanky
# HeavyEnemy mixed in now and then — usually on the opposite side of a few
# basics, so the player has to choose: the easy kills or the bigger reward.

const BASIC := preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
const HEAVY := preload("res://components/Enemies/HeavyEnemy/HeavyEnemy.tscn")

const START_Y := -150.0
const END_Y := 1230.0
const BASIC_FLIGHT_TIME := 5.0
const HEAVY_FLIGHT_TIME := 7.5   # slower, so there is time to bring it down

# One entry per Timer tick: [type, x] pairs spawned together. Empty = pause.
const BEATS := [
	[["basic", 500]],
	[["basic", 1400]],
	[["basic", 960]],
	[["heavy", 960]],
	[],
	[["basic", 400], ["basic", 1500]],
	[["heavy", 450], ["basic", 1300], ["basic", 1550]],
	[["basic", 1450]],
	[],
	[["basic", 700], ["basic", 1200]],
	[["heavy", 1450], ["basic", 350], ["basic", 650]],
	[["basic", 500]],
	[],
	[["heavy", 600], ["heavy", 1350], ["basic", 960]],
	[["basic", 400], ["basic", 1500]],
]

var beat := 0

func start() -> void:
	beat = 0
	$Timer.start()

func update(_delta: float) -> bool:
	# Done once everything has spawned and the screen is clear again.
	return beat >= BEATS.size() and $Enemies.get_child_count() == 0

func exit() -> void:
	$Timer.stop()

func _on_Timer_timeout() -> void:
	if beat >= BEATS.size():
		$Timer.stop()
		return
	for spawn in BEATS[beat]:
		_spawn(spawn[0] == "heavy", spawn[1])
	beat += 1

func _spawn(heavy: bool, x: float) -> void:
	var enemy: Node2D = (HEAVY if heavy else BASIC).instantiate()
	enemy.position = Vector2(x, START_Y)
	$Enemies.add_child(enemy)
	# Tween lives on the enemy so it dies with it; free it once it is below the screen.
	var tween := enemy.create_tween()
	tween.tween_property(enemy, "position:y", END_Y, HEAVY_FLIGHT_TIME if heavy else BASIC_FLIGHT_TIME)
	tween.finished.connect(enemy.queue_free)
