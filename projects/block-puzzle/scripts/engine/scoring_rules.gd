extends RefCounted
class_name BlockverseScoring
## Central score rules; deterministic and independent of presentation.

const POINTS_PER_BLOCK := 10
const POINTS_PER_LINE := 100
const MAX_COMBO_MULTIPLIER := 5

static func placement_points(block_count: int) -> int:
	return maxi(0, block_count) * POINTS_PER_BLOCK

static func line_points(lines_cleared: int, combo_count: int) -> int:
	if lines_cleared <= 0:
		return 0
	var multiplier := clampi(combo_count, 1, MAX_COMBO_MULTIPLIER)
	return lines_cleared * POINTS_PER_LINE * multiplier

static func total_move_points(block_count: int, lines_cleared: int, combo_count: int) -> int:
	return placement_points(block_count) + line_points(lines_cleared, combo_count)
