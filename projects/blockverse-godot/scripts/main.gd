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
const EMPTY := -1
const STONE := -2
const ICE := -3
const SAVE_PATH := "user://blockverse_save.cfg"
const THEME_PALETTES := [{"name": "MIDNIGHT", "background": "#111a31", "cell": "#202d49", "accent": "#65d8ff"}, {"name": "SUNSET", "background": "#302039", "cell": "#51334b", "accent": "#ffb36b"}, {"name": "FOREST", "background": "#102c2b", "cell": "#1d4840", "accent": "#75e0b0"}]

var board: Array = []
var obstacle_hp: Array = []
var tray_pieces: Array = []
var selected_piece := -1
var score := 0
var best_score := 0
var coins := 0
var selected_theme := 0
var last_daily_claim := ""
var daily_reward_label: Label
var shop_label: Label
var theme_button: Button
var board_grid: GridContainer
var tray_container: HBoxContainer
var score_label: Label
var status_label: Label
var level_label: Label
var objective_label: Label
var action_button: Button
var current_level := 1
var moves_used := 0
var lines_cleared := 0
var level_finished := false
var move_limit := 18
var line_target := 3

func _ready() -> void:
	randomize()
	_load_save()
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
	score_label.add_theme_color_override("font_color", Color(THEME_PALETTES[selected_theme].accent))
	root.add_child(score_label)

	daily_reward_label = Label.new()
	daily_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(daily_reward_label)
	var reward_button := Button.new()
	reward_button.text = "CLAIM DAILY REWARD"
	reward_button.pressed.connect(_claim_daily_reward)
	root.add_child(reward_button)
	shop_label = Label.new()
	shop_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(shop_label)
	theme_button = Button.new()
	theme_button.text = "THEME SHOP — NEXT THEME"
	theme_button.pressed.connect(_buy_or_select_theme)
	root.add_child(theme_button)

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
	panel_style.bg_color = Color(THEME_PALETTES[selected_theme].background)
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

	var legend := Label.new()
	legend.text = "🪨 Stone: 1 hit     ❄ Ice: 2 hits"
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_color_override("font_color", Color("#aab6d3"))
	root.add_child(legend)

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
	obstacle_hp.clear()
	for y in range(BOARD_SIZE):
		var row: Array = []
		var hp_row: Array = []
		for x in range(BOARD_SIZE):
			row.append(EMPTY)
			hp_row.append(0)
		board.append(row)
		obstacle_hp.append(hp_row)

func _refresh_board() -> void:
	for child in board_grid.get_children():
		child.queue_free()
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			var value: int = board[y][x]
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(1, 1)
			cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
			cell.focus_mode = Control.FOCUS_NONE
			cell.text = "🪨" if value == STONE else ("❄%d" % obstacle_hp[y][x] if value == ICE else "")
			var style := StyleBoxFlat.new()
			if value == STONE:
				style.bg_color = Color("#626b7d")
			elif value == ICE:
				style.bg_color = Color("#78c9ef")
			elif value >= 0:
				style.bg_color = COLORS[value % COLORS.size()]
			else:
				style.bg_color = Color(THEME_PALETTES[selected_theme].cell)
			style.set_corner_radius_all(5)
			cell.add_theme_stylebox_override("normal", style)
			cell.add_theme_stylebox_override("hover", style)
			cell.add_theme_stylebox_override("pressed", style)
			cell.pressed.connect(_on_cell_pressed.bind(x, y))
			board_grid.add_child(cell)

func _refresh_tray() -> void:
	for child in tray_container.get_children():
		child.queue_free()
	for i in range(tray_pieces.size()):
		var piece: Dictionary = tray_pieces[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(90, 96)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = _shape_preview(piece.shape)
		if piece.special != "":
			button.text += "\n" + _special_icon(piece.special)
		button.add_theme_font_size_override("font_size", 18)
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

func _special_icon(kind: String) -> String:
	match kind:
		"bomb": return "💣 BOMB"
		"rainbow": return "🌈 ROW"
		"lightning": return "⚡ COLUMN"
	return ""

func _new_game() -> void:
	_build_board()
	score = 0
	selected_piece = -1
	_seed_obstacles()
	_generate_tray()
	_refresh_board()
	_refresh_tray()
	status_label.text = "Choose a piece, then tap the board"
	_refresh_economy_ui()
	_save_game()

func _seed_obstacles() -> void:
	# Fixed starter layout makes early obstacle testing repeatable.
	board[2][2] = STONE
	board[5][5] = STONE
	board[2][5] = ICE
	obstacle_hp[2][5] = 2

func _generate_tray() -> void:
	tray_pieces.clear()
	for i in range(3):
		var special := ""
		var roll := randi() % 20
		if roll == 0:
			special = "bomb"
		elif roll == 1:
			special = "rainbow"
		elif roll == 2:
			special = "lightning"
		tray_pieces.append({"shape": SHAPES[randi() % SHAPES.size()].duplicate(), "special": special})

func _select_piece(index: int) -> void:
	if index >= 0 and index < tray_pieces.size():
		selected_piece = index
		var kind: String = tray_pieces[index].special
		status_label.text = "Selected %s — tap a starting cell" % (_special_icon(kind) if kind != "" else "piece")

func _on_cell_pressed(x: int, y: int) -> void:
	if selected_piece < 0 or selected_piece >= tray_pieces.size():
		status_label.text = "Select a piece first"
		return
	var piece: Dictionary = tray_pieces[selected_piece]
	var shape: Array = piece.shape
	if not _can_place(shape, x, y):
		status_label.text = "That piece doesn't fit there"
		return
	for p in shape:
		board[y + p.y][x + p.x] = selected_piece % COLORS.size()
		score += 1
	_apply_special(piece.special, x, y)
	var cleared_lines := _clear_completed_lines()
	coins += cleared_lines * 5
	tray_pieces.remove_at(selected_piece)
	selected_piece = -1
	if tray_pieces.is_empty():
		_generate_tray()
	_refresh_board()
	_refresh_tray()
	_save_game()
	_refresh_economy_ui()
	if _has_obstacles():
		status_label.text = "Good move! Clear the remaining obstacles"
	else:
		status_label.text = "Board clear! Keep scoring"

func _can_place(shape: Array, origin_x: int, origin_y: int) -> bool:
	for p in shape:
		var x := origin_x + p.x
		var y := origin_y + p.y
		if x < 0 or y < 0 or x >= BOARD_SIZE or y >= BOARD_SIZE or board[y][x] != EMPTY:
			return false
	return true

func _apply_special(kind: String, x: int, y: int) -> void:
	match kind:
		"bomb":
			for by in range(maxi(0, y - 1), mini(BOARD_SIZE, y + 2)):
				for bx in range(maxi(0, x - 1), mini(BOARD_SIZE, x + 2)):
					_damage_obstacle(bx, by)
					if board[by][bx] >= 0:
						board[by][bx] = EMPTY
			score += 50
			status_label.text = "💣 Bomb blast!"
		"rainbow":
			for bx in range(BOARD_SIZE):
				_damage_obstacle(bx, y)
				if board[y][bx] >= 0:
					board[y][bx] = EMPTY
			score += 50
			status_label.text = "🌈 Rainbow row cleared!"
		"lightning":
			for by in range(BOARD_SIZE):
				_damage_obstacle(x, by)
				if board[by][x] >= 0:
					board[by][x] = EMPTY
			score += 50
			status_label.text = "⚡ Lightning column cleared!"

func _damage_obstacle(x: int, y: int) -> void:
	if board[y][x] == STONE:
		board[y][x] = EMPTY
	elif board[y][x] == ICE:
		obstacle_hp[y][x] -= 1
		if obstacle_hp[y][x] <= 0:
			board[y][x] = EMPTY
			obstacle_hp[y][x] = 0

func _clear_completed_lines() -> int:
	var rows: Array[int] = []
	var columns: Array[int] = []
	for y in range(BOARD_SIZE):
		var full := true
		for x in range(BOARD_SIZE):
			if board[y][x] == EMPTY:
				full = false
				break
		if full:
			rows.append(y)
	for x in range(BOARD_SIZE):
		var full := true
		for y in range(BOARD_SIZE):
			if board[y][x] == EMPTY:
				full = false
				break
		if full:
			columns.append(x)
	for y in rows:
		for x in range(BOARD_SIZE):
			_damage_obstacle(x, y)
			if board[y][x] >= 0:
				board[y][x] = EMPTY
	for x in columns:
		for y in range(BOARD_SIZE):
			_damage_obstacle(x, y)
			if board[y][x] >= 0:
				board[y][x] = EMPTY
	var cleared := rows.size() + columns.size()
	score += cleared * 100
	if cleared > 0:
		status_label.text = "Line cleared! +%d" % (cleared * 100)
	return cleared

func _has_obstacles() -> bool:
	for y in range(BOARD_SIZE):
		for x in range(BOARD_SIZE):
			if board[y][x] == STONE or board[y][x] == ICE:
				return true
	return false

func _update_score() -> void:
	if score_label:
		best_score = maxi(best_score, score)
		score_label.text = "SCORE  %d     BEST  %d     COINS  %d" % [score, best_score, coins]

func _today_key() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

func _claim_daily_reward() -> void:
	var today := _today_key()
	if last_daily_claim == today:
		daily_reward_label.text = "Daily reward already claimed today"
		return
	coins += 100
	last_daily_claim = today
	daily_reward_label.text = "Daily reward claimed: +100 coins!"
	_save_game()
	_refresh_economy_ui()

func _buy_or_select_theme() -> void:
	var next_theme := (selected_theme + 1) % THEME_PALETTES.size()
	if next_theme == 0:
		selected_theme = 0
	elif coins >= 150:
		coins -= 150
		selected_theme = next_theme
		status_label.text = "%s theme unlocked!" % THEME_PALETTES[selected_theme].name
	else:
		status_label.text = "Need 150 coins to unlock this theme"
		return
	_apply_theme()
	_save_game()
	_refresh_economy_ui()

func _apply_theme() -> void:
	if score_label:
		score_label.add_theme_color_override("font_color", Color(THEME_PALETTES[selected_theme].accent))
	_refresh_board()

func _refresh_economy_ui() -> void:
	if not is_instance_valid(shop_label):
		return
	shop_label.text = "COINS: %d  •  THEME: %s" % [coins, THEME_PALETTES[selected_theme].name]
	if last_daily_claim == _today_key():
		daily_reward_label.text = "Daily reward claimed — come back tomorrow"
	else:
		daily_reward_label.text = "Daily reward available: 100 coins"

func _save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "best_score", best_score)
	config.set_value("player", "coins", coins)
	config.set_value("player", "selected_theme", selected_theme)
	config.set_value("player", "last_daily_claim", last_daily_claim)
	config.save(SAVE_PATH)

func _load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_score = int(config.get_value("player", "best_score", 0))
	coins = int(config.get_value("player", "coins", 0))
	selected_theme = clampi(int(config.get_value("player", "selected_theme", 0)), 0, THEME_PALETTES.size() - 1)
	last_daily_claim = str(config.get_value("player", "last_daily_claim", ""))
