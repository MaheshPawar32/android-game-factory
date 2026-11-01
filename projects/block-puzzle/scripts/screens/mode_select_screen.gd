extends Control

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BlockverseTheme.BACKGROUND
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var back := Button.new()
	back.text = "‹"
	back.custom_minimum_size = Vector2(52, 52)
	back.pressed.connect(func(): AppRouter.go_home())
	header.add_child(back)
	var title := Label.new()
	title.text = "SELECT MODE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", BlockverseTheme.TEXT_PRIMARY)
	header.add_child(title)
	var spacer := Control.new()
	spacer.custom_minimum_size.x = 52
	header.add_child(spacer)

	var modes := [
		["🏆  CLASSIC", "Endless high-score challenge", "classic"],
		["🗺  ADVENTURE", "Progress through themed worlds", "adventure"],
		["📅  DAILY CHALLENGE", "Same seeded puzzle for everyone today", "daily"],
		["🪷  ZEN", "Relax and play without game over", "zen"],
		["🔥  COMBO RUSH", "Reach a 5× combo streak", "combo_rush"],
		["⏱  TIME ATTACK", "Score as much as possible in 90 seconds", "time_attack"]
	]
	for mode in modes:
		var button := Button.new()
		button.text = "%s\n%s" % [mode[0], mode[1]]
		button.custom_minimum_size.y = 92
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", BlockverseTheme.TEXT_PRIMARY)
		button.focus_mode = Control.FOCUS_NONE
		var style := StyleBoxFlat.new()
		style.bg_color = BlockverseTheme.SURFACE
		style.border_color = BlockverseTheme.SURFACE_RAISED
		style.set_border_width_all(1)
		style.set_corner_radius_all(18)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		var mode_id: String = mode[2]
		button.pressed.connect(func(): AppRouter.start_mode(mode_id))
		layout.add_child(button)

