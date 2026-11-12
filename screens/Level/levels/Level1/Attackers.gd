extends Node
# Last and hardest wave before the boss. Two things at once:
# - basic fighters swooping along the Formation wave's S-curves (half as dense),
# - squads of two BasicEnemies flying in front of a HeavyEnemy, straight down,
#   alternating between the left and right side of the screen.

const BASIC := preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
const HEAVY := preload("res://components/Enemies/HeavyEnemy/HeavyEnemy.tscn")

const TICKS := 18              # Timer ticks (1.2 s each) before spawning stops
const PATH_EVERY := 2          # a path fighter every 2nd tick (Formation: every tick)
const PATH_UNTIL := 16         # no path fighters from this tick on (8 in total)
const SQUAD_EVERY := 3         # a squad every 3rd tick, starting at tick 1 (6 in total)
const PATH_TIME := 10.0        # same as Formation
const SQUAD_TIME := 6.0        # whole squad moves together at this speed
const SQUAD_X := [450.0, 1470.0]
const SQUAD_START_Y := -300.0  # heavy sits 105 px behind, so start well above the screen
const SQUAD_END_Y := 1300.0
# Positions inside a squad: two basics in front (lower on screen), heavy behind.
const SQUAD_BASICS := [Vector2(-65, 0), Vector2(65, 0)]
const SQUAD_HEAVY := Vector2(0, -105)

var tick := 0
var path_count := 0
var squad_count := 0

func start() -> void:
	tick = 0
	path_count = 0
	squad_count = 0
	$Timer.start()

func update(_delta: float) -> bool:
	# Done once everything has spawned and nothing is left on screen.
	return tick >= TICKS and $Squads.get_child_count() == 0 \
		and $Paths/LeftPath.get_child_count() == 0 and $Paths/RightPath.get_child_count() == 0

func exit() -> void:
	$Timer.stop()

func _on_Timer_timeout() -> void:
	if tick >= TICKS:
		$Timer.stop()
		return
	if tick % PATH_EVERY == 0 and tick < PATH_UNTIL:
		_spawn_path_fighter()
	if tick % SQUAD_EVERY == 1:
		_spawn_squad()
	tick += 1

func _spawn_path_fighter() -> void:
	var follow := PathFollow2D.new()
	follow.rotates = false
	follow.add_child(BASIC.instantiate())
	var path: Path2D = $Paths/LeftPath if path_count % 2 == 0 else $Paths/RightPath
	path.add_child(follow)
	var tween := follow.create_tween()
	tween.tween_property(follow, "progress_ratio", 1.0, PATH_TIME)
	# Paths end below the screen: free the follower (and its enemy) when done.
	tween.finished.connect(follow.queue_free)
	path_count += 1

func _spawn_squad() -> void:
	var squad := Node2D.new()
	squad.position = Vector2(SQUAD_X[squad_count % SQUAD_X.size()], SQUAD_START_Y)
	for offset in SQUAD_BASICS:
		var basic: Node2D = BASIC.instantiate()
		basic.position = offset
		squad.add_child(basic)
	var heavy: Node2D = HEAVY.instantiate()
	heavy.position = SQUAD_HEAVY
	squad.add_child(heavy)
	$Squads.add_child(squad)
	# Tween on the squad: survivors keep formation; freed below the screen.
	var tween := squad.create_tween()
	tween.tween_property(squad, "position:y", SQUAD_END_Y, SQUAD_TIME)
	tween.finished.connect(squad.queue_free)
	squad_count += 1
