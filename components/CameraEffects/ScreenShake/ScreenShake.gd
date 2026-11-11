extends Node2D

@onready var camera: Camera2D = get_parent()
var amplitude: float = 0
var duration: float = 0.2
var frequency: float = 16
var _tween: Tween

func start_shake(amplitude: float = 16, frequency: float = 16, duration: float = 0.2):
	if amplitude >= self.amplitude:
		$EndShakeTimer.stop()
		$ShakeTimer.stop()
		self.amplitude = amplitude
		self.duration = duration
		self.frequency = frequency
		$EndShakeTimer.wait_time = duration
		$ShakeTimer.wait_time = 1 / float(frequency)
		$EndShakeTimer.start()
		$ShakeTimer.start()
		_new_shake()

func end_shake():
	$EndShakeTimer.stop()
	$ShakeTimer.stop()
	_reset()

func _reset():
	self.amplitude = 0
	self.duration = 0.2
	self.frequency = 16
	# Ease the camera back to its resting position (zero offset, zero rotation).
	_tween_to(Vector2.ZERO, 0.0, $ShakeTimer.wait_time)

func _new_shake():
	var trans_shake = Vector2(
		randf_range(-self.amplitude, self.amplitude),
		randf_range(-self.amplitude, self.amplitude)
	)
	var shake_limit = min(self.amplitude / 10.0, 0.7)
	var shake_rotation = randf_range(-shake_limit, shake_limit)
	_tween_to(trans_shake, shake_rotation, $ShakeTimer.wait_time)

func _tween_to(target_offset: Vector2, target_rotation: float, time: float):
	# Only one tween may drive the camera at a time, otherwise an old shake
	# tween can keep running after the reset and leave the camera displaced.
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(camera, "offset", target_offset, time)
	_tween.tween_property(camera, "rotation_degrees", target_rotation, time)

func _on_EndShakeTimer_timeout():
	end_shake()

func _on_ShakeTimer_timeout():
	_new_shake()
