extends Node

func _ready():
	pass

func _on_Player_bullet_fired(bullet):
	$Bullets.add_child(bullet)
	
func _on_Level1_spawned_enemy(enemy):
	$Enemies.add_child(enemy)
	print(enemy)