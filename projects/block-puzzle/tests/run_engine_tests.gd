extends SceneTree
## Dependency-free headless test runner.
## Run: godot --headless --path projects/block-puzzle --script res://tests/run_engine_tests.gd

const Board = preload("res://scripts/engine/board_model.gd")
const Pieces = preload("res://scripts/engine/piece_definitions.gd")
const Generator = preload("res://scripts/engine/piece_generator.gd")
const Scoring = preload("res://scripts/engine/scoring_rules.gd")
const SpecialResolverScript = preload("res://scripts/engine/special_block_resolver.gd")
const LevelData = preload("res://scripts/engine/level_generator.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
	_test_empty_board()
	_test_custom_board_sizes()
	_test_placement_and_bounds()
	_test_overlap_rejected()
	_test_row_clear()
	_test_column_clear()
	_test_simultaneous_lines()
	_test_seeded_generator()
	_test_scoring()
	_test_special_effect_bounds()
	_test_rainbow_line()
	_test_lightning_connectivity()
	_test_special_resolution()
	_test_special_generator_distribution()
	_test_procedural_levels()
	_test_board_obstacles()
	print("\nBLOCKVERSE ENGINE TESTS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("PASS: " + label)
	else:
		failed += 1
		push_error("FAIL: " + label)

func _test_empty_board() -> void:
	var board = Board.new()
	_check(board.get_cell(0, 0) == Board.EMPTY and board.get_cell(9, 9) == Board.EMPTY, "new board starts empty")
	_check(not board.is_full(), "empty board is not full")

func _test_placement_and_bounds() -> void:
	var board = Board.new()
	var shape: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT]
	_check(board.can_place(shape, Vector2i(0, 0)), "valid placement accepted")
	_check(not board.can_place(shape, Vector2i(9, 0)), "right boundary rejects out-of-range shape")
	_check(not board.can_place(shape, Vector2i(-1, 0)), "negative coordinate rejected")
	var result: Dictionary = board.place(shape, Vector2i(2, 3), 2)
	_check(result.success and board.get_cell(2, 3) == 2 and board.get_cell(3, 3) == 2, "placement writes both cells")

func _test_overlap_rejected() -> void:
	var board = Board.new()
	board.cells[2][2] = 1
	var shape: Array[Vector2i] = [Vector2i.ZERO, Vector2i.RIGHT]
	_check(not board.can_place(shape, Vector2i(1, 2)), "overlapping placement rejected")

func _test_row_clear() -> void:
	var board = Board.new(10)
	for x in range(board.size):
		board.cells[4][x] = 0
	var result: Dictionary = board.clear_completed_lines()
	_check(result.rows == [4], "full row detected")
	_check(board.get_cell(0, 4) == Board.EMPTY and board.get_cell(9, 4) == Board.EMPTY, "full row cleared")

func _test_column_clear() -> void:
	var board = Board.new(10)
	for y in range(board.size):
		board.cells[y][6] = 0
	var result: Dictionary = board.clear_completed_lines()
	_check(result.columns == [6], "full column detected")
	_check(board.get_cell(6, 0) == Board.EMPTY and board.get_cell(6, 9) == Board.EMPTY, "full column cleared")

func _test_simultaneous_lines() -> void:
	var board = Board.new()
	for x in range(board.size):
		board.cells[3][x] = 0
	for y in range(board.size):
		board.cells[y][7] = 1
	var result: Dictionary = board.clear_completed_lines()
	_check(result.rows.size() == 1 and result.columns.size() == 1, "row and column detected in same clear")
	_check(board.get_cell(7, 3) == Board.EMPTY, "intersection cleared once without error")

func _test_seeded_generator() -> void:
	var a = Generator.new()
	var b = Generator.new()
	a.set_seed(12345)
	b.set_seed(12345)
	var first_a: Dictionary = a.next_piece()
	var first_b: Dictionary = b.next_piece()
	_check(first_a.shape_id == first_b.shape_id and first_a.color_id == first_b.color_id, "seeded piece generation is reproducible")
	_check(a.next_tray(3).size() == 3, "piece tray returns requested count")

func _test_scoring() -> void:
	_check(Scoring.placement_points(4) == 40, "placement score is 10 per block")
	_check(Scoring.line_points(2, 3) == 600, "two lines at combo three score 600")
	_check(Scoring.line_points(2, 99) == 1000, "combo multiplier is capped")
	_check(Scoring.line_points(0, 1) == 0, "no line clear awards no line bonus")

func _test_special_effect_bounds() -> void:
	var board = Board.new(10)
	var cells: Array[Vector2i] = SpecialResolverScript.bomb_cells(board, Vector2i.ZERO)
	_check(cells.size() == 4, "corner bomb clips its 3x3 area to board bounds")
	var center_cells: Array[Vector2i] = SpecialResolverScript.bomb_cells(board, Vector2i(5, 5))
	_check(center_cells.size() == 9, "center bomb returns a 3x3 area")

func _test_rainbow_line() -> void:
	var board = Board.new()
	board.cells[2][0] = 1
	board.cells[2][4] = 2
	var cells: Array[Vector2i] = SpecialResolverScript.rainbow_line_cells(board, true, 2)
	_check(cells.size() == 2, "rainbow returns occupied cells in chosen row")
	_check(SpecialResolverScript.rainbow_line_cells(board, false, 12).is_empty(), "rainbow rejects invalid line index")

func _test_lightning_connectivity() -> void:
	var board = Board.new()
	board.cells[1][1] = 1
	board.cells[1][2] = 1
	board.cells[2][2] = 1
	board.cells[8][8] = 1
	var cells: Array[Vector2i] = Specials.lightning_connected_cells(board, Vector2i(1, 1))
	_check(cells.size() == 3, "lightning finds connected orthogonal cluster only")

func _test_special_resolution() -> void:
	var bomb_board = Board.new(10)
	for y in range(3, 8):
		for x in range(3, 8):
			bomb_board.cells[y][x] = 1
	var bomb: Dictionary = Specials.resolve(bomb_board, "bomb", Vector2i(5, 5))
	_check(bomb.cells.size() == 9 and bomb_board.get_cell(5, 5) == Board.EMPTY, "bomb clears bounded 3x3 board area")

	var rainbow_board = Board.new(10)
	for x in range(rainbow_board.size):
		rainbow_board.cells[4][x] = 2
	var rainbow: Dictionary = Specials.resolve(rainbow_board, "rainbow", Vector2i(2, 4))
	_check(rainbow.cells.size() == rainbow_board.size and rainbow_board.get_cell(0, 4) == Board.EMPTY, "rainbow clears its selected row")

	var lightning_board = Board.new(10)
	lightning_board.cells[1][1] = 1
	lightning_board.cells[1][2] = 1
	lightning_board.cells[2][2] = 1
	lightning_board.cells[8][8] = 1
	var lightning: Dictionary = Specials.resolve(lightning_board, "lightning", Vector2i(1, 1))
	_check(lightning.cells.size() == 3 and lightning_board.get_cell(2, 2) == Board.EMPTY, "lightning clears connected cluster only")

	var treasure_board = Board.new()
	treasure_board.cells[0][0] = 3
	var treasure: Dictionary = Specials.resolve(treasure_board, "treasure", Vector2i(0, 0))
	_check(treasure.coins == 25 and treasure_board.get_cell(0, 0) == 3, "treasure awards coins without clearing board")

func _test_special_generator_distribution() -> void:
	var generator = Generator.new()
	generator.set_seed(20261101)
	var seen: Dictionary = {}
	for i in range(500):
		var piece: Dictionary = generator.next_piece()
		seen[str(piece.special_type)] = true
	_check(seen.has("normal"), "generator includes normal pieces")
	_check(seen.has("bomb") and seen.has("rainbow") and seen.has("lightning") and seen.has("treasure"), "seeded generator can produce every special type")

func _test_custom_board_sizes() -> void:
	var default_board = Board.new()
	_check(default_board.size == 5, "default board size is 5x5")
	_check(default_board.cells.size() == 5 and default_board.cells[0].size() == 5, "default board allocates 5x5 cells")
	var ten_board = Board.new(10)
	_check(ten_board.size == 10 and ten_board.cells.size() == 10, "maximum board size is 10x10")
	var clamped_small = Board.new(2)
	_check(clamped_small.size == 5, "board size clamps below minimum to 5")
	var clamped_large = Board.new(20)
	_check(clamped_large.size == 10, "board size clamps above maximum to 10")
	ten_board.set_size(7)
	_check(ten_board.size == 7 and ten_board.get_cell(6, 6) == Board.EMPTY, "changing board size resets to selected dimension")
	var snapshot: Dictionary = ten_board.to_dictionary()
	var restored = Board.new()
	_check(restored.load_dictionary(snapshot) and restored.size == 7, "board snapshot restores custom size")

func _test_procedural_levels() -> void:
	var first: Dictionary = LevelData.configuration(1)
	var fifth_thousand: Dictionary = LevelData.configuration(5000)
	var beyond: Dictionary = LevelData.configuration(5001)
	_check(LevelData.is_supported(5000) and LevelData.is_supported(5001), "procedural campaign supports 5,000+ levels")
	_check(first.seed != fifth_thousand.seed and fifth_thousand.seed == LevelData.configuration(5000).seed, "each level has a stable unique repeatable seed")
	_check(int(fifth_thousand.objective_lines) >= int(first.objective_lines), "level objectives scale with campaign progress")
	_check(int(beyond.world) > int(fifth_thousand.world), "world numbering continues beyond the first 5,000 levels")
	var limited: Dictionary = LevelData.configuration(5)
	var score_trial: Dictionary = LevelData.configuration(7)
	var boss: Dictionary = LevelData.configuration(25)
	_check(str(limited.objective_type) == "limited_moves" and int(limited.move_limit) > 0, "every fifth level introduces a move-limited challenge")
	_check(str(score_trial.objective_type) == "score" and int(score_trial.target_score) > 0, "score-trial levels generate score targets")
	_check(str(boss.objective_type) == "boss" and int(boss.objective_lines) >= 6 and int(boss.move_limit) > 0, "every twenty-fifth level becomes a boss challenge")

func _test_board_obstacles() -> void:
	var board = Board.new(5)
	_check(board.set_obstacle(2, 2, Board.STONE), "stone obstacle can be placed on empty board cell")
	_check(not board.can_place([Vector2i.ZERO], Vector2i(2, 2)), "stone obstacle blocks piece placement")
	_check(not board.set_obstacle(2, 2, Board.ICE), "obstacle cannot overwrite occupied cell")
	_check(board.obstacle_count() == 1 and board.obstacle_count(Board.STONE) == 1, "board counts obstacle types")
	var obstacle_snapshot: Dictionary = board.to_dictionary()
	var obstacle_restore = Board.new()
	_check(obstacle_restore.load_dictionary(obstacle_snapshot) and obstacle_restore.get_cell(2, 2) == Board.STONE, "board snapshot preserves obstacle cell values")
	for x in range(board.size):
		if x != 2:
			board.cells[2][x] = 0
	var cleared: Dictionary = board.clear_completed_lines()
	_check(cleared.rows == [2] and board.obstacle_count() == 0, "completed row clears obstacles occupying that row")
