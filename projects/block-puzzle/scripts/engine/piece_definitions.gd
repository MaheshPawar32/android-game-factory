extends RefCounted
class_name BlockversePieces
## Canonical shape definitions. Coordinates are non-negative and normalized.

const SHAPES: Array[Array] = [
	[Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(0, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)]
]

static func shape_count() -> int:
	return SHAPES.size()

static func get_shape(index: int) -> Array[Vector2i]:
	if index < 0 or index >= SHAPES.size():
		return []
	var result: Array[Vector2i] = []
	for point in SHAPES[index]:
		result.append(point)
	return result

static func get_max_extent(shape: Array[Vector2i]) -> Vector2i:
	var extent := Vector2i.ZERO
	for point in shape:
		extent.x = maxi(extent.x, point.x)
		extent.y = maxi(extent.y, point.y)
	return extent + Vector2i.ONE
