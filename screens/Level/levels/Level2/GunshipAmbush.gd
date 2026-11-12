## Introduces gunships: one alone, then two, then three at once, with a few
## fast basics to deal with while dodging their bursts.
extends TimelineWave

func b(x: float) -> Dictionary:
	return basic(x, 3.5)

func beats() -> Array:
	return [
		[gunship(960, 260, 3.5)], [], [b(400)], [b(1500)], [],
		[gunship(500, 230), gunship(1420, 230)], [], [b(960)], [b(700), b(1220)], [], [],
		[gunship(350, 280), gunship(960, 200), gunship(1570, 280)], [], [b(600)], [b(1320)],
		[heavy(960, 5.5)], [],
	]
