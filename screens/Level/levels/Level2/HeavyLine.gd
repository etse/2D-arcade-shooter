## Walls of heavies sweeping down, fast basics darting through the gaps and
## gunships firing from behind the wall.
extends TimelineWave

func b(x: float) -> Dictionary:
	return basic(x, 3.5)

func h(x: float) -> Dictionary:
	return heavy(x, 6.5)

func beats() -> Array:
	return [
		[h(480), h(960), h(1440)], [], [b(720), b(1200)], [gunship(960, 180, 3.5)],
		[b(300), b(1620)], [],
		[h(300), h(720), h(1200), h(1620)], [], [b(960)],
		[gunship(500, 200), gunship(1420, 200)], [b(500), b(1420)], [], [],
	]
