# Headless project validator.
# Usage: godot --headless --path . --script res://tools/validate.gd
# Loads every .gd script and .tscn/.tres resource under res:// (skipping
# res://addons and res://.godot) and exits with code 1 if anything fails.
extends SceneTree

const SKIP_DIRS := ["res://.godot", "res://addons", "res://.git", "res://.claude"]

var _failures: Array[String] = []
var _checked := 0


func _initialize() -> void:
	# Defer one frame so autoload singletons are registered before scripts
	# referencing them (e.g. Score, CameraControl) are compiled.
	process_frame.connect(_run, CONNECT_ONE_SHOT)


func _run() -> void:
	for path in _collect("res://"):
		_check(path)
	print("validate: checked %d files, %d failure(s)" % [_checked, _failures.size()])
	for f in _failures:
		printerr("  FAIL: " + f)
	quit(1 if _failures.size() > 0 else 0)


func _collect(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	if dir_path in SKIP_DIRS or dir_path.trim_suffix("/") in SKIP_DIRS:
		return out
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for sub in dir.get_directories():
		out.append_array(_collect(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.get_extension() in ["gd", "tscn", "tres"]:
			out.append(dir_path.path_join(file))
	return out


func _check(path: String) -> void:
	if path == get_script().resource_path:
		return  # reloading the running script crashes the engine
	_checked += 1
	var res := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if res == null:
		_failures.append("%s (failed to load)" % path)
		return
	if res is GDScript and not (res as GDScript).can_instantiate():
		_failures.append("%s (script does not compile)" % path)
	elif res is PackedScene and not (res as PackedScene).can_instantiate():
		_failures.append("%s (scene cannot be instantiated)" % path)
