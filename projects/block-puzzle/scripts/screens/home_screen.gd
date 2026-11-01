extends Control

var coin_label: Label
var level_label: Label

func _ready() -> void:
	_build_screen()

func _build_screen() -> void:
	var bg := ColorRect.new()
	bg.color = BlockverseTheme.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	var top := HBoxContainer.new()
	layout.add_child(top)
	var player := VBoxContainer.new()
	player.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(player)
	level_label = _label("PLAYER  •  LV.%d" % int(SaveData.get_value("player_level", 1)), 13, BlockverseTheme.TEXT_MUTED)
	player.add_child(level_label)
	var xp := _label("%d / %d XP to next level" % [int(SaveData.get_value("player_xp", 0)), SaveData.xp_to_next_level()], 12, BlockverseTheme.TEXT_MUTED)
	player.add_child(xp)
	coin_label = _label("🪙  %s" % _format_number(int(SaveData.get_value("coins", 250))), 18, BlockverseTheme.GOLD, true)
	top.add_child(coin_label)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 34
	layout.add_child(spacer)

	var logo := _label("✦  BLOCKVERSE  ✦", 38, BlockverseTheme.TEXT_PRIMARY, true)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(logo)
	var tagline := _label("PLACE. CLEAR. COMBO. CONQUER.", 13, BlockverseTheme.SECONDARY, true)
	tagline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(tagline)

	var hero_spacer := Control.new()
	hero_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(hero_spacer)

	var play := _button("▶   PLAY", BlockverseTheme.SUCCESS, Color("#123D39"))
	play.custom_minimum_size.y = 76
	play.add_theme_font_size_override("font_size", 26)
	play.pressed.connect(func(): AppRouter.open_mode_select())
	layout.add_child(play)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	layout.add_child(cards)
	var adventure := _button("🗺  ADVENTURE\nWorld 1", BlockverseTheme.SURFACE_RAISED, BlockverseTheme.PRIMARY)
	adventure.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	adventure.custom_minimum_size.y = 82
	adventure.pressed.connect(func(): AppRouter.open_adventure_map())
	cards.add_child(adventure)
	var daily := _button("📅  DAILY\nCHALLENGE", BlockverseTheme.SURFACE_RAISED, BlockverseTheme.PRIMARY)
	daily.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	daily.custom_minimum_size.y = 82
	daily.pressed.connect(func(): AppRouter.open_progression())
	cards.add_child(daily)

	var shortcuts := HBoxContainer.new()
	shortcuts.add_theme_constant_override("separation", 12)
	layout.add_child(shortcuts)
	for item in ["MISSIONS", "SHOP", "PROFILE"]:
		var shortcut := _button(item, BlockverseTheme.SURFACE, BlockverseTheme.SURFACE_RAISED)
		shortcut.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shortcut.custom_minimum_size.y = 58
		shortcut.pressed.connect(func(): AppRouter.open_shop() if item == "SHOP" else AppRouter.open_progression())
		shortcuts.add_child(shortcut)

	var settings := _button("⚙  SETTINGS", BlockverseTheme.SURFACE, BlockverseTheme.SURFACE_RAISED)
	settings.custom_minimum_size.y = 54
	settings.pressed.connect(_show_settings)
	layout.add_child(settings)

	var footer := _label("OFFLINE PLAY  •  PROGRESS SAVED ON THIS DEVICE", 10, BlockverseTheme.TEXT_MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(footer)

func _label(value: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color("#000000"))
		label.add_theme_constant_override("outline_size", 1)
	return label

func _button(value: String, fill: Color, border: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", BlockverseTheme.TEXT_PRIMARY)
	button.focus_mode = Control.FOCUS_NONE
	var normal := StyleBoxFlat.new()
	normal.bg_color = fill
	normal.border_color = border
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(BlockverseTheme.BUTTON_RADIUS)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = fill.lightened(0.12)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	return button

func _show_coming_soon(feature: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = feature
	dialog.dialog_text = "%s is planned for a later development batch." % feature
	add_child(dialog)
	dialog.popup_centered()

func _show_settings() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "GAME SETTINGS"
	dialog.dialog_text = "Choose the feedback you want during play."
	var options := VBoxContainer.new()
	for setting in [
		["sound", "Sound effects"],
		["music", "Music"],
		["vibration", "Haptic feedback"],
		["notifications", "Notifications"]
	]:
		var toggle := CheckButton.new()
		toggle.text = setting[1]
		toggle.button_pressed = bool(SaveData.get_setting(setting[0], true))
		toggle.toggled.connect(func(enabled: bool): SaveData.update_setting(setting[0], enabled))
		options.add_child(toggle)
	dialog.add_child(options)
	dialog.get_ok_button().text = "DONE"
	add_child(dialog)
	dialog.popup_centered(Vector2i(360, 300))

func _format_number(value: int) -> String:
	var text := str(value)
	var result := ""
	while text.length() > 3:
		result = "," + text.substr(text.length() - 3, 3) + result
		text = text.substr(0, text.length() - 3)
	return text + result
