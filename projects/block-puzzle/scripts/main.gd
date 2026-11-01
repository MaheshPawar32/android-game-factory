extends Control

const GRID_SIZE := 10
const EMPTY := -1
const CELL_GAP := 4

const SHAPES: Array = [
	[Vector2i(0, 0)],
	[Vector2i(0, 0), Vector2i(1, 0)],
	[Vector2i(0, 0), Vector2i(0, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)],
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)],
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]
]

const BLOCK_COLORS: Array[Color] = [
	Color("#62D6C8"),
	Color("#72A7FF"),
	Color("#B18CFF"),
	Color("#FFB86B"),
	Color("#FF7D9C")
]

var board: Array = []
var board_cells: Array[Button] = []
var tray_buttons: Array[Button] = []
var current_pieces: Array = []
var selected_piece := -1
var score := 0
var best_score := 0
var combo := 0
var game_over := false

var score_label: Label
var best_label: Label
var combo_label: Label
var status_label: Label
var board_grid: GridContainer
var tray_container: HBoxContainer

func _ready() -> void:
	_build_board_data()
	_build_ui()
	_new_game()

func _build_board_data() -> void:
	board.clear()
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			row.append(EMPTY)
		board.append(row)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#090D1B")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 18)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var eyebrow := _label("DAILY PUZZLE", 12, Color("#7E8BAF"))
	eyebrow.add_theme_color_override("font_color", Color("#7E8BAF"))
	title_box.add_child(eyebrow)

	var title := _label("BLOCK  BLAST", 27, Color("#F4F6FF"), true)
	title_box.add_child(title)

	var restart := Button.new()
	restart.text = "↻"
	restart.custom_minimum_size = Vector2(54, 54)
	restart.add_theme_font_size_override("font_size", 28)
	_style_button(restart, Color("#1A2340"), Color("#344466"))
	restart.pressed.connect(_new_game)
	header.add_child(restart)

	var score_row := HBoxContainer.new()
	score_row.add_theme_constant_override("separation", 12)
	layout.add_child(score_row)
	var score_card := _stat_card("SCORE", "0")
	score_label = score_card.get_node("Value") as Label
	score_row.add_child(score_card)
	var best_card := _stat_card("BEST", "0")
	best_label = best_card.get_node("Value") as Label
	score_row.add_child(best_card)
	var combo_card := _stat_card("COMBO", "—")
	combo_label = combo_card.get_node("Value") as Label
	score_row.add_child(combo_card)

	var board_panel := PanelContainer.new()
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(board_panel, Color("#121A30"), Color("#283656"))
	layout.add_child(board_panel)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 10)
	board_margin.add_theme_constant_override("margin_right", 10)
	board_margin.add_theme_constant_override("margin_top", 10)
	board_margin.add_theme_constant_override("margin_bottom", 10)
	board_panel.add_child(board_margin)

	board_grid = GridContainer.new()
	board_grid.columns = GRID_SIZE
	board_grid.add_theme_constant_override("h_separation", CELL_GAP)
	board_grid.add_theme_constant_override("v_separation", CELL_GAP)
	board_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_margin.add_child(board_grid)

	board_cells.clear()
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(1, 1)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell.focus_mode = Control.FOCUS_NONE
			cell.text = ""
			_style_cell(cell, false, Color("#202B45"))
			cell.pressed.connect(_on_board_cell_pressed.bind(x, y))
			board_grid.add_child(cell)
			board_cells.append(cell)

	var instruction := _label("CHOOSE A SHAPE  •  TAP THE BOARD TO PLACE", 12, Color("#9AA8C8"))
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(instruction)

	tray_container = HBoxContainer.new()
	tray_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tray_container.add_theme_constant_override("separation", 12)
	layout.add_child(tray_container)

	status_label = _label("Complete rows or columns to clear space.", 13, Color("#9AA8C8"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status_label)

func _label(value: String, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25))
	return label

func _stat_card(caption: String, value: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_panel(panel, Color("#151F38"), Color("#263654"))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var top := _label(caption, 10, Color("#8796B8"))
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(top)
	var number := _label(value, 22, Color("#F4F6FF"), true)
	number.name = "Value"
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(number)
	return panel

func _style_panel(panel: PanelContainer, fill: Color, border_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)

func _style_button(button: Button, fill: Color, border_color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = border_color
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = fill.lightened(0.10)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#F4F6FF"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.focus_mode = Control.FOCUS_NONE

func _style_cell(cell: Button, filled: bool, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color if filled else Color("#202B45")
	style.set_corner_radius_all(5)
	cell.add_theme_stylebox_override("normal", style)
	cell.add_theme_stylebox_override("hover", style)
	cell.add_theme_stylebox_override("pressed", style)
	cell.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _new_game() -> void:
	_build_board_data()
	score = 0
	combo = 0
	selected_piece = -1
	game_over = false
	current_pieces = []
	for i in range(3):
		current_pieces.append(_random_shape())
	_refresh_all()
	_set_status("Choose a shape, then tap a starting cell.")

func _random_shape() -> Array:
	return SHAPES[randi_range(0, SHAPES.size() - 1)].duplicate()

func _on_tray_pressed(index: int) -> void:
	if game_over or index >= current_pieces.size() or current_pieces[index].is_empty():
		return
	selected_piece = index
	_refresh_tray()
	_set_status("Now tap where you want to place the shape.")

func _on_board_cell_pressed(x: int, y: int) -> void:
	if game_over:
		return
	if selected_piece < 0 or selected_piece >= current_pieces.size():
		_set_status("Choose one of the three shapes first.")
		return
	var shape: Array = current_pieces[selected_piece]
	if not _can_place(shape, x, y):
		_set_status("That shape does not fit there. Try another spot.")
		return

	for offset in shape:
		var point: Vector2i = offset
		board[y + point.y][x + point.x] = selected_piece % BLOCK_COLORS.size()
	score += shape.size() * 10
	current_pieces[selected_piece] = []
	selected_piece = -1

	var cleared := _clear_completed_lines()
	if cleared > 0:
		combo += 1
		score += cleared * 100 * combo
		_set_status("NICE! %d line(s) cleared  •  x%d combo" % [cleared, combo])
	else:
		combo = 0
		_set_status("Good placement. Keep building your lines.")

	if score > best_score:
		best_score = score

	if _all_pieces_used():
		for i in range(3):
			current_pieces[i] = _random_shape()

	_refresh_all()
	if not _has_any_move():
		game_over = true
		_set_status("GAME OVER  •  Tap ↻ to play again.")

func _can_place(shape: Array, origin_x: int, origin_y: int) -> bool:
	for offset in shape:
		var point: Vector2i = offset
		var x := origin_x + point.x
		var y := origin_y + point.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
			return false
		if board[y][x] != EMPTY:
			return false
	return true

func _clear_completed_lines() -> int:
	var rows_to_clear: Array[int] = []
	var columns_to_clear: Array[int] = []
	for y in range(GRID_SIZE):
		var full := true
		for x in range(GRID_SIZE):
			if board[y][x] == EMPTY:
				full = false
				break
		if full:
			rows_to_clear.append(y)
	for x in range(GRID_SIZE):
		var full := true
		for y in range(GRID_SIZE):
			if board[y][x] == EMPTY:
				full = false
				break
		if full:
			columns_to_clear.append(x)

	for y in rows_to_clear:
		for x in range(GRID_SIZE):
			board[y][x] = EMPTY
	for x in columns_to_clear:
		for y in range(GRID_SIZE):
			board[y][x] = EMPTY
	return rows_to_clear.size() + columns_to_clear.size()

func _all_pieces_used() -> bool:
	for piece in current_pieces:
		if not piece.is_empty():
			return false
	return true

func _has_any_move() -> bool:
	for piece in current_pieces:
		if piece.is_empty():
			continue
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				if _can_place(piece, x, y):
					return true
	return false

func _refresh_all() -> void:
	_refresh_board()
	_refresh_tray()
	if score_label:
		score_label.text = str(score)
	if best_label:
		best_label.text = str(best_score)
	if combo_label:
		combo_label.text = "x%d" % combo if combo > 0 else "—"

func _refresh_board() -> void:
	if board_cells.is_empty():
		return
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var index := y * GRID_SIZE + x
			var value: int = board[y][x]
			var cell := board_cells[index]
			if value == EMPTY:
				_style_cell(cell, false, Color("#202B45"))
			else:
				_style_cell(cell, true, BLOCK_COLORS[value % BLOCK_COLORS.size()])

func _refresh_tray() -> void:
	if not is_instance_valid(tray_container):
		return
	for child in tray_container.get_children():
		child.queue_free()
	tray_buttons.clear()
	for i in range(current_pieces.size()):
		var piece: Array = current_pieces[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(100, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 21)
		button.text = _shape_text(piece)
		if piece.is_empty():
			button.text = "✓"
			_style_button(button, Color("#11192B"), Color("#202B45"))
			button.disabled = true
		elif selected_piece == i:
			_style_button(button, Color("#263E68"), Color("#72A7FF"))
		else:
			_style_button(button, Color("#151F38"), Color("#344466"))
		button.pressed.connect(_on_tray_pressed.bind(i))
		tray_container.add_child(button)
		tray_buttons.append(button)

func _shape_text(shape: Array) -> String:
	if shape.is_empty():
		return ""
	var max_x := 0
	var max_y := 0
	for offset in shape:
		var point: Vector2i = offset
		max_x = maxi(max_x, point.x)
		max_y = maxi(max_y, point.y)
	var lines: Array[String] = []
	for y in range(max_y + 1):
		var line := ""
		for x in range(max_x + 1):
			var occupied := false
			for offset in shape:
				var point: Vector2i = offset
				if point.x == x and point.y == y:
					occupied = true
					break
			line += "■ " if occupied else "  "
		lines.append(line)
	return "\n".join(lines)

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
