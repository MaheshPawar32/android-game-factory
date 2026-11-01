extends Control

const BoardModel = preload("res://scripts/engine/board_model.gd")
const PieceGenerator = preload("res://scripts/engine/piece_generator.gd")
const ScoringRules = preload("res://scripts/engine/scoring_rules.gd")
const SpecialResolver = preload("res://scripts/engine/special_block_resolver.gd")
const BoardViewScript = preload("res://scripts/ui/board_view.gd")

var board: RefCounted
var generator: RefCounted
var pieces: Array[Dictionary] = []
var selected_piece := -1
var drag_active := false
var score := 0
var combo := 0
var best_score := 0
var board_size_button: Button
var game_over := false
var paused := false
var level_lines := 0
var level_objective := 3

var board_view: Control
var tray: HBoxContainer
var score_label: Label
var best_label: Label
var combo_label: Label
var status_label: Label
var tray_buttons: Array[Button] = []

func _ready() -> void:
	var saved_size := clampi(int(SaveData.get_value("board_size", 5)), 5, 10)
	board = BoardModel.new(saved_size)
	generator = PieceGenerator.new()
	generator.randomize_seed()
	best_score = int(SaveData.get_value("best_score", 0))
	_build_ui()
	_new_game()
	if not bool(SaveData.get_value("tutorial_seen", false)):
		_show_tutorial()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#101426")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)
	title_box.add_child(_label("BLOCKVERSE  •  CLASSIC", 13, Color("#A7B0CC")))
	title_box.add_child(_label("PLACE. CLEAR. COMBO.", 24, Color("#F6F5FF"), true))
	var back := _button("⌂", Color("#293657"))
	back.custom_minimum_size = Vector2(54, 54)
	back.pressed.connect(func(): AppRouter.go_home())
	header.add_child(back)
	var size_button := _button("%d×%d" % [board.size, board.size], Color("#293657"))
	size_button.custom_minimum_size = Vector2(76, 54)
	size_button.pressed.connect(_show_board_size_picker)
	board_size_button = size_button
	header.add_child(size_button)
	var restart := _button("↻", Color("#293657"))
	restart.custom_minimum_size = Vector2(54, 54)
	restart.pressed.connect(_new_game)
	header.add_child(restart)
	var pause := _button("Ⅱ", Color("#293657"))
	pause.custom_minimum_size = Vector2(54, 54)
	pause.pressed.connect(_show_pause_screen)
	header.add_child(pause)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 10)
	layout.add_child(stats)
	score_label = _stat("SCORE", "0")
	best_label = _stat("BEST", str(best_score))
	combo_label = _stat("COMBO", "—")
	stats.add_child(_stat_card("SCORE", score_label))
	stats.add_child(_stat_card("BEST", best_label))
	stats.add_child(_stat_card("COMBO", combo_label))

	var board_panel := PanelContainer.new()
	board_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#18223B")
	panel_style.border_color = Color("#344466")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(20)
	panel_style.content_margin_left = 8
	panel_style.content_margin_right = 8
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8
	board_panel.add_theme_stylebox_override("panel", panel_style)
	layout.add_child(board_panel)

	board_view = BoardViewScript.new()
	board_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board_view.custom_minimum_size = Vector2(300, 300)
	board_view.pointer_moved.connect(_on_board_pointer_moved)
	board_view.pointer_released.connect(_on_board_pointer_released)
	board_panel.add_child(board_view)

	var instruction := _label("DRAG A BLOCK ONTO THE BOARD", 12, Color("#A7B0CC"), true)
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(instruction)

	tray = HBoxContainer.new()
	tray.alignment = BoxContainer.ALIGNMENT_CENTER
	tray.add_theme_constant_override("separation", 12)
	layout.add_child(tray)

	status_label = _label("Make a full row or column to clear it.", 13, Color("#A7B0CC"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status_label)

func _label(value: String, font_size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color("#000000"))
		label.add_theme_constant_override("outline_size", 1)
	return label

func _button(value: String, fill: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#F6F5FF"))
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.focus_mode = Control.FOCUS_NONE
	return button

func _stat(value: String, initial: String) -> Label:
	var label := _label(initial, 22, Color("#F6F5FF"), true)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _stat_card(caption: String, value_label: Label) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#202943")
	style.set_corner_radius_all(14)
	card.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_child(_label(caption, 10, Color("#A7B0CC")))
	box.add_child(value_label)
	card.add_child(box)
	return card

func _show_board_size_picker() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "BOARD SIZE"
	dialog.dialog_text = "Choose your grid size. Smaller boards are faster and more challenging."
	var options := OptionButton.new()
	for value in range(5, 11):
		options.add_item("%d × %d" % [value, value], value)
		if value == board.size:
			options.select(value - 5)
	dialog.add_child(options)
	dialog.confirmed.connect(func():
		var chosen := options.get_selected_id()
		SaveData.set_value("board_size", chosen)
		board.set_size(chosen)
		_new_game()
	)
	add_child(dialog)
	dialog.popup_centered(Vector2i(360, 180))

func _new_game() -> void:
	board.reset()
	score = 0
	combo = 0
	selected_piece = -1
	drag_active = false
	game_over = false
	paused = false
	level_lines = 0
	level_objective = 3 + int(SaveData.get_value("current_level", 1)) / 4
	pieces = generator.next_tray(3)
	_refresh_all()
	_set_status("Drag a shape onto the board.")

func _refresh_all() -> void:
	board_view.set_board(board)
	if is_instance_valid(board_size_button):
		board_size_button.text = "%d×%d" % [board.size, board.size]
	_refresh_tray()
	score_label.text = str(score)
	best_label.text = str(best_score)
	combo_label.text = "x%d" % combo if combo > 0 else "—"

func _refresh_tray() -> void:
	for child in tray.get_children():
		child.queue_free()
	tray_buttons.clear()
	for i in range(pieces.size()):
		var piece: Dictionary = pieces[i]
		var special_type := str(piece.get("special_type", "normal"))
		var prefix := _special_icon(special_type)
		var button := _button(prefix + _piece_text(piece.cells), _special_color(special_type))
		button.custom_minimum_size = Vector2(1, 112)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)
		button.disabled = piece.is_empty()
		button.modulate = Color(1, 1, 1, 0.35) if piece.is_empty() else Color.WHITE
		button.gui_input.connect(_on_piece_gui_input.bind(i))
		button.pressed.connect(_on_piece_tap.bind(i))
		tray.add_child(button)
		tray_buttons.append(button)

func _piece_text(shape: Array) -> String:
	if shape.is_empty():
		return "✓"
	var max_x := 0
	var max_y := 0
	for p in shape:
		max_x = maxi(max_x, p.x)
		max_y = maxi(max_y, p.y)
	var output := ""
	for y in range(max_y + 1):
		for x in range(max_x + 1):
			var occupied := false
			for p in shape:
				if p == Vector2i(x, y):
					occupied = true
					break
			output += "■ " if occupied else "  "
		if y < max_y:
			output += "\n"
	return output

func _special_icon(special_type: String) -> String:
	match special_type:
		"bomb": return "💣\n"
		"rainbow": return "🌈\n"
		"lightning": return "⚡\n"
		"treasure": return "💎\n"
		_: return ""

func _special_color(special_type: String) -> Color:
	match special_type:
		"bomb": return Color("#FF658B")
		"rainbow": return Color("#B18CFF")
		"lightning": return Color("#FFB547")
		"treasure": return Color("#20C8D9")
		_: return Color("#202943")

func _input(event: InputEvent) -> void:
	if paused or game_over or not drag_active or selected_piece < 0:
		return
	if event is InputEventScreenDrag:
		_update_drag_from_screen(event.position)
	elif event is InputEventMouseMotion:
		_update_drag_from_screen(event.position)
	elif event is InputEventScreenTouch and not event.pressed:
		_release_drag_from_screen(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_release_drag_from_screen(event.position)

func _release_drag_from_screen(screen_position: Vector2) -> void:
	var local := board_view.get_global_transform_with_canvas().affine_inverse() * screen_position
	if board_view.is_inside_board(local):
		_try_place_selected(board_view.cell_from_position(local))
	_finish_drag()

func _on_piece_tap(index: int) -> void:
	if paused or game_over or pieces[index].is_empty():
		return
	selected_piece = index
	_set_status("Piece selected. Drag it onto the board.")
	for i in range(tray_buttons.size()):
		tray_buttons[i].modulate = Color("#B9D4FF") if i == index else Color.WHITE

func _on_piece_gui_input(event: InputEvent, index: int) -> void:
	if paused or game_over or pieces[index].is_empty():
		return
	if event is InputEventScreenTouch and event.pressed:
		_start_drag(index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_drag(index)
	elif event is InputEventMouseMotion and drag_active:
		_update_drag_from_screen(event.global_position)
	elif event is InputEventScreenDrag and drag_active:
		_update_drag_from_screen(event.position)

func _start_drag(index: int) -> void:
	selected_piece = index
	drag_active = true
	_set_status("Release over the board to place.")
	for i in range(tray_buttons.size()):
		tray_buttons[i].scale = Vector2.ONE
	tray_buttons[index].scale = Vector2(1.06, 1.06)

func _update_drag_from_screen(screen_position: Vector2) -> void:
	if not drag_active or selected_piece < 0:
		return
	var local := board_view.get_global_transform_with_canvas().affine_inverse() * screen_position
	if board_view.is_inside_board(local):
		var cell: Vector2i = board_view.cell_from_position(local)
		var shape: Array[Vector2i] = pieces[selected_piece].cells
		board_view.set_preview(shape, cell, board.can_place(shape, cell))
	else:
		board_view.clear_preview()

func _on_board_pointer_moved(local_position: Vector2) -> void:
	if paused or game_over or not drag_active or selected_piece < 0:
		return
	if board_view.is_inside_board(local_position):
		var cell: Vector2i = board_view.cell_from_position(local_position)
		var shape: Array[Vector2i] = pieces[selected_piece].cells
		board_view.set_preview(shape, cell, board.can_place(shape, cell))
	else:
		board_view.clear_preview()

func _on_board_pointer_released(local_position: Vector2) -> void:
	if paused or game_over or not drag_active or selected_piece < 0:
		return
	if board_view.is_inside_board(local_position):
		var cell: Vector2i = board_view.cell_from_position(local_position)
		_try_place_selected(cell)
	_finish_drag()


func _try_place_selected(origin: Vector2i) -> void:
	if paused or game_over or selected_piece < 0:
		return
	var selected: Dictionary = pieces[selected_piece]
	var shape: Array[Vector2i] = selected.cells
	if not board.can_place(shape, origin):
		_set_status("That placement doesn't fit. Try another position.")
		Feedback.play("error")
		Feedback.vibrate(18)
		return
	var result: Dictionary = board.place(shape, origin, int(selected.color_id))
	board_view.animate_placement(result.placed)
	Feedback.play("place")
	Feedback.vibrate(22)
	score += ScoringRules.placement_points(shape.size())
	SaveData.record_placement(shape.size())
	pieces[selected_piece] = {}
	selected_piece = -1

	var special_type := str(selected.get("special_type", "normal"))
	var special_result: Dictionary = {"cells": [], "coins": 0, "message": ""}
	if special_type != "normal":
		special_result = SpecialResolver.resolve(board, special_type, origin)
		var effect_color := _special_color(special_type)
		board_view.flash_special_cells(special_result.cells, effect_color)
		if int(special_result.coins) > 0:
			SaveData.add_coins(int(special_result.coins), "Treasure block")
			Feedback.play("reward")
			Feedback.vibrate(55)
			_show_reward_popup(int(special_result.coins))
		_set_status(str(special_result.message))
		if special_type == "bomb" or special_type == "rainbow" or special_type == "lightning":
			score += int(special_result.cells.size()) * 5
	else:
		_set_status("Nice placement. Build your next clear.")

	var cleared: int = int(result.lines_cleared)
	level_lines += cleared
	if cleared > 0:
		SaveData.record_lines_cleared(cleared)
		SaveData.record_combo(combo + 1)
		combo += 1
		score += ScoringRules.line_points(cleared, combo)
		board_view.flash_lines(result.cleared_rows, result.cleared_columns)
		Feedback.play("combo" if combo > 1 else "clear")
		Feedback.vibrate(45)
		_set_status("LINE CLEAR! %d lines  •  COMBO x%d" % [cleared, combo])
	elif special_type == "normal":
		combo = 0

	if bool(SaveData.get_value("adventure_active", false)) and level_lines >= level_objective:
		_show_victory_screen()
		return
	if score > best_score:
		best_score = score
		SaveData.set_value("best_score", best_score)

	if _all_pieces_used():
		pieces = generator.next_tray(3)
	_refresh_all()
	if not _has_any_move():
		game_over = true
		_show_game_over()

func _finish_drag() -> void:
	drag_active = false
	selected_piece = -1
	board_view.clear_preview()
	for button in tray_buttons:
		button.scale = Vector2.ONE

func _all_pieces_used() -> bool:
	for piece in pieces:
		if not piece.is_empty():
			return false
	return true

func _has_any_move() -> bool:
	for piece in pieces:
		if piece.is_empty():
			continue
		var shape: Array[Vector2i] = piece.cells
		if board.has_any_placement(shape):
			return true
	return false

func _show_pause_screen() -> void:
	if paused or game_over:
		return
	paused = true
	_finish_drag()
	var dialog := ConfirmationDialog.new()
	dialog.title = "GAME PAUSED"
	dialog.dialog_text = "Take a break. Your current score is %d." % score
	dialog.ok_button_text = "RESUME"
	dialog.confirmed.connect(func(): paused = false)
	dialog.canceled.connect(func(): paused = false)
	add_child(dialog)
	dialog.popup_centered()

func _show_game_over() -> void:
	paused = true
	SaveData.record_game_completed(score)
	var dialog := AcceptDialog.new()
	dialog.title = "ROUND COMPLETE"
	dialog.dialog_text = "FINAL SCORE  %s\nBEST SCORE  %s\n\nNo moves left. Try another round!" % [score, best_score]
	dialog.confirmed.connect(func(): paused = false; _new_game())
	dialog.ok_button_text = "PLAY AGAIN"
	add_child(dialog)
	dialog.popup_centered()

func _show_tutorial() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "WELCOME TO BLOCKVERSE"
	dialog.dialog_text = "1. Choose a shape from the tray.\n2. Drag it onto an empty part of the board.\n3. Complete a full row or column to clear it.\n4. Chain clears for combo bonuses.\n5. Special blocks have powerful effects."
	dialog.ok_button_text = "LET'S PLAY"
	dialog.confirmed.connect(func(): SaveData.set_value("tutorial_seen", true))
	add_child(dialog)
	dialog.popup_centered(Vector2i(420, 300))

func _show_reward_popup(coins: int) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "TREASURE FOUND!"
	dialog.dialog_text = "+%d coins added to your wallet." % coins
	dialog.ok_button_text = "AWESOME"
	add_child(dialog)
	dialog.popup_centered()

func _show_victory_screen() -> void:
	paused = true
	Feedback.play("reward")
	Feedback.vibrate(100)
	SaveData.record_game_completed(score)
	var current := int(SaveData.get_value("current_level", 1))
	SaveData.set_value("unlocked_level", maxi(int(SaveData.get_value("unlocked_level", 1)), current + 1))
	var reward := 50 + current * 5
	SaveData.add_coins(reward, "Adventure level %d" % current)
	var dialog := AcceptDialog.new()
	dialog.title = "LEVEL COMPLETE!"
	dialog.dialog_text = "Objective completed!\nLines cleared: %d / %d\n\nReward: %d coins" % [level_lines, level_objective, reward]
	dialog.ok_button_text = "CONTINUE"
	dialog.confirmed.connect(func(): AppRouter.open_level_select())
	add_child(dialog)
	dialog.popup_centered()

func _set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message
