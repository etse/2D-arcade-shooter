extends Node

signal screenshake

func screen_shake(amplitude: float = 16, frequency: float = 16, duration: float = 0.2):
	emit_signal("screenshake", amplitude, frequency, duration)