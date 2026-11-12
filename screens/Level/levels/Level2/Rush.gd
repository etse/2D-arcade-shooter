## Fast basics (3.5 s across vs 5 s in Level 1) in pairs and triples, with
## heavies mixed in.
extends TimelineWave

func b(x: float) -> Dictionary:
	return basic(x, 3.5)

func h(x: float) -> Dictionary:
	return heavy(x, 5.0)

func beats() -> Array:
	return [
		[b(500)], [b(1400)], [b(800), b(1120)], [],
		[b(350), b(960), b(1570)], [h(700)], [b(1300), b(1500)], [],
		[b(400), b(600)], [h(1250), b(300)], [b(960)], [b(700), b(1250)], [],
		[h(500), h(1420)], [b(960)], [b(800), b(1120)],
	]
