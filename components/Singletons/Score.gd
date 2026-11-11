## The player's points, which double as money for the shop.
extends Node

signal score_changed
@export var score: int = 0

func add_score(points: int):
	score = score + points
	emit_signal("score_changed", score)

## Deducts `amount` if the player can afford it. Returns whether it was paid.
func spend(amount: int) -> bool:
	if amount < 0 or amount > score:
		return false
	score -= amount
	score_changed.emit(score)
	return true
