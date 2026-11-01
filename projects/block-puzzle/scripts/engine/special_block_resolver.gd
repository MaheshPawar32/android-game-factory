extends RefCounted
class_name BlockverseSpecialResolver
## Deterministic board effects. Visual effects are triggered by the UI after results return.

enum Type { NORMAL, BOMB, RAINBOW, LIGHTNING, TREASURE }

static func bomb_cells(center: Vector2i, radius: int = 1) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			if x >= 0 and x < BlockverseBoard.SIZE and y >= 0 and y < BlockverseBoard.SIZE:
				result.append(Vector2i(x, y))
	return result

static func rainbow_line_cells(board: BlockverseBoard, is_row: bool, line_index: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if line_index < 0 or line_index >= BlockverseBoard.SIZE:
		return result
	for i in range(BlockverseBoard.SIZE):
		var point := Vector2i(i, line_index) if is_row else Vector2i(line_index, i)
		if board.get_cell(point.x, point.y) != BlockverseBoard.EMPTY:
			result.append(point)
	return result

static func lightning_connected_cells(board: BlockverseBoard, origin: Vector2i) -> Array[Vector2i]:
	# Four-direction flood fill; diagonals are intentionally not connected.
	var result: Array[Vector2i] = []
	if board.get_cell(origin.x, origin.y) == BlockverseBoard.EMPTY:
		return result
	var queue: Array[Vector2i] = [origin]
	var visited: Dictionary = {origin: true}
	while not queue.is_empty():
		var point: Vector2i = queue.pop_front()
		result.append(point)
		for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next_point := point + direction
			if not visited.has(next_point) and board.get_cell(next_point.x, next_point.y) != BlockverseBoard.EMPTY:
				visited[next_point] = true
				queue.append(next_point)
	return result

static func treasure_reward(base_coins: int = 25) -> int:
	return maxi(0, base_coins)
