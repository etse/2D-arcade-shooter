## Hardest wave before the boss: squads (two basics in front of a heavy)
## alternating sides, gunships at the edges and fighters on the Swarm curves.
extends "res://screens/Level/levels/Level2/Swarm.gd"

func beats() -> Array:
	return [
		[squad(450, 5.0)], [gunship(1550, 220, 4.0)], [path(0, "basic", 7.0)],
		[squad(1470, 5.0)], [gunship(370, 220, 4.0)], [path(1, "basic", 7.0)],
		[squad(450, 5.0), path(0, "basic", 7.0)], [],
		[squad(1470, 5.0), gunship(960, 160, 3.5)], [path(1, "basic", 7.0)],
		[squad(960, 5.0)], [gunship(400, 240), gunship(1520, 240)],
		[squad(700, 5.0), squad(1220, 5.0)], [], [],
	]
