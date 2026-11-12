## A dense stream of fighters zig-zagging down two mirrored curves; every
## fifth one is a heavy.
extends TimelineWave

const COUNT := 22

func curves() -> Array[Curve2D]:
	var left := Curve2D.new()
	left.add_point(Vector2(300, -120), Vector2.ZERO, Vector2(0, 300))
	left.add_point(Vector2(1600, 380), Vector2(0, -250), Vector2(0, 250))
	left.add_point(Vector2(350, 760), Vector2(0, -250), Vector2(0, 250))
	left.add_point(Vector2(1500, 1250), Vector2(0, -250), Vector2.ZERO)
	var right := Curve2D.new()
	for i in left.point_count:
		var mirror := func(v: Vector2) -> Vector2: return Vector2(-v.x, v.y)
		var p := left.get_point_position(i)
		right.add_point(Vector2(1920 - p.x, p.y), mirror.call(left.get_point_in(i)), mirror.call(left.get_point_out(i)))
	return [left, right]

func beats() -> Array:
	var list := []
	for i in COUNT:
		list.append([path(i % 2, "heavy" if i % 5 == 4 else "basic", 7.0)])
	return list
