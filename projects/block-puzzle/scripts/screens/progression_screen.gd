extends Control

var content: VBoxContainer

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BlockverseTheme.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := _label("YOUR JOURNEY", 25, BlockverseTheme.TEXT_PRIMARY, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var back := _button("⌂", 48)
	back.pressed.connect(func(): AppRouter.go_home())
	header.add_child(back)
	var level := int(SaveData.get_value("player_level", 1))
	var xp := int(SaveData.get_value("player_xp", 0))
	var target := SaveData.xp_to_next_level(level)
	_card(root, "LEVEL %d  •  %d / %d XP" % [level, xp, target], "Earn XP by placing blocks, clearing lines and completing rounds.")
	var progress := ProgressBar.new()
	progress.max_value = target
	progress.value = xp
	progress.custom_minimum_size.y = 14
	root.add_child(progress)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	_add_missions()
	_add_achievements()
	_add_wallet()
	var footer := _label("ALL PROGRESS IS STORED OFFLINE ON THIS DEVICE", 10, BlockverseTheme.TEXT_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(footer)

func _add_missions() -> void:
	_section("DAILY MISSIONS  •  RESETS EACH DAY")
	for mission_id in SaveData.MISSION_DEFINITIONS:
		var item: Dictionary = SaveData.MISSION_DEFINITIONS[mission_id]
		var progress := SaveData.mission_progress(mission_id)
		var target := int(item.target)
		var done := progress >= target
		var claimed := SaveData.mission_claimed(mission_id)
		var card := _panel()
		content.add_child(card)
		var row := HBoxContainer.new()
		card.add_child(row)
		var details := VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(details)
		details.add_child(_label(str(item.title), 15, BlockverseTheme.TEXT_PRIMARY, true))
		details.add_child(_label("%d / %d complete  •  +%d coins  •  +%d XP" % [progress, target, int(item.reward), int(item.xp)], 11, BlockverseTheme.TEXT_MUTED))
		var claim := _button("CLAIM" if done and not claimed else ("CLAIMED" if claimed else "IN PROGRESS"), 92)
		claim.disabled = not done or claimed
		claim.pressed.connect(func(): SaveData.claim_mission(mission_id); _rebuild())
		row.add_child(claim)
		var bar := ProgressBar.new()
		bar.max_value = target
		bar.value = progress
		bar.custom_minimum_size.y = 8
		card.add_child(bar)

func _add_achievements() -> void:
	_section("ACHIEVEMENTS")
	for achievement_id in SaveData.ACHIEVEMENTS:
		var item: Dictionary = SaveData.ACHIEVEMENTS[achievement_id]
		var unlocked := SaveData.achievement_unlocked(achievement_id)
		var line := "✓  " if unlocked else "◇  "
		_card(content, line + str(item.title), str(item.description) + "  •  " + ("Reward collected" if unlocked else "+%d coins" % int(item.reward)))

func _add_wallet() -> void:
	_section("COIN WALLET")
	_card(content, "🪙  %d COINS" % int(SaveData.get_value("coins", 0)), "Coins are earned from missions, achievements, special blocks and level rewards.")
	var history: Array = SaveData.get_value("wallet_history", [])
	for entry in history:
		_card(content, "+%d  •  %s" % [int(entry.get("amount", 0)), str(entry.get("reason", "Reward"))], str(entry.get("date", "")))
	if history.is_empty():
		_card(content, "No transactions yet", "Your earned coin rewards will appear here.")

func _rebuild() -> void:
	for child in content.get_children():
		child.queue_free()
	_add_missions()
	_add_achievements()
	_add_wallet()

func _section(value: String) -> void:
	content.add_child(_label(value, 12, BlockverseTheme.SECONDARY, true))

func _card(parent: Node, heading: String, body: String) -> void:
	var card := _panel()
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	box.add_child(_label(heading, 15, BlockverseTheme.TEXT_PRIMARY, true))
	box.add_child(_label(body, 11, BlockverseTheme.TEXT_MUTED))

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = BlockverseTheme.SURFACE
	style.border_color = BlockverseTheme.SURFACE_RAISED
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(value: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if bold:
		label.add_theme_color_override("font_outline_color", Color("#000000"))
		label.add_theme_constant_override("outline_size", 1)
	return label

func _button(value: String, min_width: float) -> Button:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(min_width, 46)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", BlockverseTheme.TEXT_PRIMARY)
	var style := StyleBoxFlat.new()
	style.bg_color = BlockverseTheme.SURFACE_RAISED
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.focus_mode = Control.FOCUS_NONE
	return button
