extends Control

const BOARD_SIZE := 8
const COLORS := [Color("#39b9ff"), Color("#ffb547"), Color("#8b6cff"), Color("#42d6a4"), Color("#ff6685")]
const SHAPES := [
	[Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(0, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)]
]

var board: Array = []
var tray_shapes: Array = []
var selected_piece := -1
var score := 0
var best_score := 0
var board_grid: GridContainer
var tray_container: HBoxContainer
var score_label: Label
var status_label: Label

func _ready() -> void:
	_build_board()
	_build_ui()
	_new_game()

func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 14)
	root.add_theme_constant_override("margin_left", 20)
	root.add_theme_constant_override("margin_right", 20)
	root.add_theme_constant_override("margin_top", 26)
	root.add_theme_constant_override("margin_bottom", 20)
	add_child(root)

	var title := Label.new()
	title.text = "BLOCKVERSE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	root.add_child(title)

	score_label = Label.new()
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 22)
	score_label.add_theme_color_override("font_color", Color("#65d8ff"))
	root.add_child(score_label)

	status_label = Label.new()
	status_label.text = "Choose a piece, then tap the board"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("#aab6d3"))
	root.add_child(status_label)

	var board_panel := PanelContainer.new()
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#111a31")
	panel_style.set_corner_radius_all(18)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	board_panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(board_panel)

	board_grid = GridContainer.new()
	board_grid.columns = BOARD_SIZE
	board_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_grid.add_theme_constant_override("h_separation", 4)
	board_grid.add_theme_constant_override("v_separation", 4)
	board_panel.add_child(board_grid)

	var tray_title := Label.new()
	tray_title.text = "YOUR PIECES"
	tray_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tray_title.add_theme_font_size_override("font_size", 18)
	root.add_child(tray_title)

	tray_container = HBoxContainer.new()
	tray_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tray_container.custom_minimum_size.y = 110
	root.add_child(tray_container)

	var reset_button := Button.new()
	reset_button.text = "NEW GAME"
	reset_button.custom_minimum_size.y = 52
	reset_button.pressed.connect(_new_game)
	root.add_child(reset_button)

func _build_board() -> void:
	board.clear()
	for y in range(BOARD_SIZE):
		var row: Array = []
		for x in range(BOARD_SIZE):
			row.append(-1)
		board.append(row)

func _refresh_board() -> void:
	for child in board_grid.get_children():
		child.queue_free()
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(1, 1)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell.focus_mode = Control.FOCUS_NONE
			cell.text = ""
			var style := StyleBoxFlat.new()
			style.bg_color = Color("#202d49") if board[y][x] < 0 else COLORS[board[y][x] % COLORS.size()]
			style.set_corner_radius_all(5)
			cell.add_theme_stylebox_override("normal", style)
			cell.add_theme_stylebox_override("hover", style)
			cell.add_theme_stylebox_override("pressed", style)
			cell.pressed.connect(_on_cell_pressed.bind(x, y))
			board_grid.add_child(cell)

func _refresh_tray() -> void:
	for child in tray_container.get_children():
		child.queue_free()
	for i in range(tray_shapes.size()):
		var button := Button.new()
		button.custom_minimum_size = Vector2(90, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = _shape_preview(tray_shapes[i])
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(_select_piece.bind(i))
		tray_container.add_child(button)
	_update_score()

func _shape_preview(shape: Array) -> String:
	var max_x := 0
	var max_y := 0
	for p in shape:
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)
	var output := ""
	for y in range(max_y + 1):
		for x in range(max_x + 1):
			output += "■ " if shape.has(Vector2i(x, y)) else "  "
		output += "\n"
	return output

func _new_game() -> void:
	_build_board()
	score = 0
	selected_piece = -1
	_generate_tray()
	_refresh_board()
	_refresh_tray()
	status_label.text = "Choose a piece, then tap the board"

func _generate_tray() -> void:
	tray_shapes.clear()
	for i in range(3):
		tray_shapes.append(SHAPES[randi() % SHAPES.size()].duplicate())

func _select_piece(index: int) -> void:
	if index >= 0 and index < tray_shapes.size():
		selected_piece = index
		status_label.text = "Piece %d selected — tap its starting cell" % (index + 1)

func _on_cell_pressed(x: int, y: int) -> void:
	if selected_piece < 0 or selected_piece >= tray_shapes.size():
		status_label.text = "Select a piece first"
		return
	var shape: Array = tray_shapes[selected_piece]
	if not _can_place(shape, x, y):
		status_label.text = "That piece doesn't fit there"
		return
	for p in shape:
		board[y + p.y][x + p.x] = selected_piece % COLORS.size()
	score += shape.size()
	_clear_completed_lines()
	tray_shapes.remove_at(selected_piece)
	selected_piece = -1
	if tray_shapes.is_empty():
		_generate_tray()
	_refresh_board()
	_refresh_tray()
	status_label.text = "Nice move! Choose your next piece"

func _can_place(shape: Array, origin_x: int, origin_y: int) -> bool:
	for p in shape:
		var x := origin_x + p.x
		var y := origin_y + p.y
		if x < 0 or y < 0 or x >= BOARD_SIZE or y >= BOARD_SIZE or board[y][x] >= 0:
			return false
	return true

func _clear_completed_lines() -> void:
	var rows: Array[int] = []
	var columns: Array[int] = []
	for y in range(BOARD_SIZE):
		var full := true
		for x in range(BOARD_SIZE):
			if board[y][x] < 0:
				full = false
				break
		if full:
			rows.append(y)
	for x in range(BOARD_SIZE):
		var full := true
		for y in range(BOARD_SIZE):
			if board[y][x] < 0:
				full = false
				break
		if full:
			columns.append(x)
	for y in rows:
		for x in range(BOARD_SIZE):
			board[y][x] = -1
	for x in columns:
		for y in range(BOARD_SIZE):
			board[y][x] = -1
	var cleared := rows.size() + columns.size()
	score += cleared * 100
	if cleared > 0:
		status_label.text = "Line cleared! +%d" % (cleared * 100)

func _update_score() -> void:
	if score_label:
		score_label.text = "SCORE  %d     BEST  %d" % [score, best_score]
