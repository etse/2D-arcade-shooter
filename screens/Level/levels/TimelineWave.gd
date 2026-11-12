## Data-driven wave (implements the wave protocol of AGENTS.md): every
## `beat_time` seconds it spawns the next entry of `beats()`. Subclasses only
## override `beats()` (and `curves()` for path spawns), using the spawn
## helpers below. Finishes once every beat has spawned and the screen is clear.
##
##     extends TimelineWave
##     func beats() -> Array:
##         return [
##             [basic(500), basic(1400)],
##             [],                                  # a pause
##             [heavy(960), gunship(400, 250)],
##         ]
extends Node
class_name TimelineWave

const BASIC := preload("res://components/Enemies/BasicEnemy/BasicEnemy.tscn")
const HEAVY := preload("res://components/Enemies/HeavyEnemy/HeavyEnemy.tscn")
const GUNSHIP := preload("res://components/Enemies/Gunship/Gunship.tscn")
const SCENES := {"basic": BASIC, "heavy": HEAVY, "gunship": GUNSHIP}

const START_Y := -150.0
const END_Y := 1250.0

## Seconds between beats.
@export var beat_time := 1.0

var _beat := 0
var _timer: Timer
var _enemies: Node2D
var _beats: Array


# --- override these ------------------------------------------------------------------

## One entry per beat: an Array of spawn specs (from the helpers below).
func beats() -> Array:
	return []


## Curves used by path() specs, indexed by `curve`.
func curves() -> Array[Curve2D]:
	return []


# --- spawn specs ----------------------------------------------------------------------

## Straight down at `x`, crossing the screen in `time` s.
func basic(x: float, time := 4.0) -> Dictionary:
	return {"kind": "straight", "scene": "basic", "x": x, "time": time}


func heavy(x: float, time := 6.0) -> Dictionary:
	return {"kind": "straight", "scene": "heavy", "x": x, "time": time}


## Gunship: flies in to (x, stop_y), shoots for `shoot` s, then leaves
## towards `exit_x` (default: straight down).
func gunship(x: float, stop_y := 250.0, shoot := 3.0, exit_x := NAN) -> Dictionary:
	return {"kind": "gunship", "x": x, "stop_y": stop_y, "shoot": shoot,
		"exit_x": x if is_nan(exit_x) else exit_x}


## Two basics side by side with a heavy right behind them, moving as one.
func squad(x: float, time := 6.0) -> Dictionary:
	return {"kind": "squad", "x": x, "time": time}


## An enemy ("basic"/"heavy") following curves()[curve] in `time` s.
func path(curve: int, scene := "basic", time := 8.0) -> Dictionary:
	return {"kind": "path", "curve": curve, "scene": scene, "time": time}


# --- wave protocol ----------------------------------------------------------------------

func start() -> void:
	if _timer == null:
		_timer = Timer.new()
		_timer.timeout.connect(_on_beat)
		add_child(_timer)
		_enemies = Node2D.new()
		_enemies.name = "Enemies"
		add_child(_enemies)
	_beats = beats()
	_beat = 0
	_timer.start(beat_time)
	_on_beat()   # first beat right away


func update(_delta: float) -> bool:
	return _beat >= _beats.size() and _enemies.get_child_count() == 0


func exit() -> void:
	_timer.stop()


func _on_beat() -> void:
	if _beat >= _beats.size():
		_timer.stop()
		return
	for spec in _beats[_beat]:
		_spawn(spec)
	_beat += 1


# --- spawning ----------------------------------------------------------------------------

func _spawn(spec: Dictionary) -> void:
	match spec.kind:
		"straight":
			var enemy: Node2D = SCENES[spec.scene].instantiate()
			enemy.position = Vector2(spec.x, START_Y)
			_enemies.add_child(enemy)
			_move_down_and_free(enemy, spec.time)
		"gunship":
			var ship: Gunship = GUNSHIP.instantiate()
			ship.position = Vector2(spec.x, START_Y)
			_enemies.add_child(ship)
			ship.fly(Vector2(spec.x, spec.stop_y), Vector2(spec.exit_x, END_Y), 1.3, spec.shoot)
		"squad":
			var group := Node2D.new()
			group.position = Vector2(spec.x, START_Y - 150.0)
			for offset in [Vector2(-65, 0), Vector2(65, 0)]:
				var b: Node2D = BASIC.instantiate()
				b.position = offset
				group.add_child(b)
			var h: Node2D = HEAVY.instantiate()
			h.position = Vector2(0, -105)
			group.add_child(h)
			_enemies.add_child(group)
			_move_down_and_free(group, spec.time, END_Y + 100.0)
		"path":
			var p := Path2D.new()
			p.curve = curves()[spec.curve]
			var follow := PathFollow2D.new()
			follow.rotates = false
			follow.loop = false
			follow.add_child(SCENES[spec.scene].instantiate())
			p.add_child(follow)
			_enemies.add_child(p)
			var t := follow.create_tween()
			t.tween_property(follow, "progress_ratio", 1.0, spec.time)
			# Free the whole path (and its enemy) once it has left the screen.
			t.finished.connect(p.queue_free)


## Tween lives on the node so it dies with it; free it below the screen.
func _move_down_and_free(node: Node2D, time: float, end_y := END_Y) -> void:
	var t := node.create_tween()
	t.tween_property(node, "position:y", end_y, time)
	t.finished.connect(node.queue_free)
