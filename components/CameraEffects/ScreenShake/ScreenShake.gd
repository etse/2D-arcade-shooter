extends Node2D

onready var camera = get_parent()
var amplitude: float = 0
var duration: float = 0.2
var frequency: float = 16

func start_shake(amplitude: float = 16, frequency: float = 16, duration: float = 0.2):
	if amplitude >= self.amplitude:
		end_shake()
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
	$ShakeTween.interpolate_property(camera, "offset", camera.offset, Vector2(), $ShakeTimer.wait_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ShakeTween.start()
	$ShakeTween.interpolate_property(camera, "rotation_degrees", camera.rotation_degrees, 0, $ShakeTimer.wait_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ShakeTween.start()
	
func _new_shake():
	var trans_shake = Vector2()
	trans_shake.x = rand_range(-self.amplitude, self.amplitude)
	trans_shake.y = rand_range(-self.amplitude, self.amplitude)
	var shake_limit = min(self.amplitude / 10.0, 0.7)
	var shake_rotation = rand_range(-shake_limit, shake_limit)
	
	$ShakeTween.interpolate_property(camera, "offset", camera.offset, trans_shake, $ShakeTimer.wait_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ShakeTween.start()
	$ShakeTween.interpolate_property(camera, "rotation_degrees", camera.rotation_degrees, shake_rotation, $ShakeTimer.wait_time, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$ShakeTween.start()

func _on_EndShakeTimer_timeout():
	end_shake()

func _on_ShakeTimer_timeout():
	_new_shake()
