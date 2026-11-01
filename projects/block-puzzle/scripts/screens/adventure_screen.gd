extends Control
## Reusable premium BLOCKVERSE adventure and level-selection screens.
const BG := Color("#101426")
const PANEL := Color("#202943")
const TEXT := Color("#F6F5FF")
const MUTED := Color("#A7B0CC")
const TEAL := Color("#25B8A8")
const WORLD_NAMES := ["CRYSTAL GROVE", "EMBER CANYON", "FROST PEAKS", "STARLIGHT BAY"]
const WORLD_DETAILS := ["Master the basics among glowing crystal gardens.", "Clear fiery lanes and build longer combos.", "Plan carefully across the icy challenge boards.", "Conquer the final cosmic puzzle trials."]

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var title := _label("ADVENTURE", 28, TEXT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var back := _button("⌂", Color("#293657"))
	back.pressed.connect(func(): AppRouter.go_home())
	top.add_child(back)
	if name == "AdventureMap":
		_build_world_map(root)
	else:
		_build_level_select(root)

func _build_world_map(root: VBoxContainer) -> void:
	root.add_child(_label("Explore worlds. Unlock new challenges.", 14, MUTED))
	var world := PanelContainer.new()
	world.size_flags_vertical = Control.SIZE_EXPAND_FILL
	world.add_theme_stylebox_override("panel", _panel_style(Color("#182B4B")))
	root.add_child(world)
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 18)
	world.add_child(content)
	var unlocked_level := int(SaveData.get_value("unlocked_level", 1))
	var unlocked := clampi(int(ceil(float(unlocked_level) / 12.0)), 1, 4)
	SaveData.set_value("unlocked_world", unlocked)
	for i in range(1, 5):
		var row := HBoxContainer.new()
		content.add_child(row)
		var marker := _label("✦" if i <= unlocked else "🔒", 30, Color("#FFD166"), true)
		row.add_child(marker)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(_label("WORLD %02d  •  %s" % [i, WORLD_NAMES[i - 1]], 17, TEXT, true))
		info.add_child(_label(WORLD_DETAILS[i - 1], 12, MUTED))
		var first_level := (i - 1) * 12 + 1
		var completed := clampi(unlocked_level - first_level, 0, 12)
		info.add_child(_label("%d / 12 levels complete" % completed, 11, Color("#FFD166")))
		var open := _button("PLAY" if i <= unlocked else "LOCKED", TEAL if i <= unlocked else Color("#34405C"))
		open.disabled = i > unlocked
		open.pressed.connect(func(): SaveData.set_value("selected_world", i); AppRouter.open_level_select())
		row.add_child(open)
	_add_bottom_button(root, "CONTINUE ADVENTURE", TEAL, func(): SaveData.set_value("selected_world", clampi(int(ceil(float(unlocked_level) / 12.0)), 1, 4)); AppRouter.open_level_select())

func _build_level_select(root: VBoxContainer) -> void:
	var world := clampi(int(SaveData.get_value("selected_world", 1)), 1, 4)
	var first_level := (world - 1) * 12 + 1
	var unlocked := int(SaveData.get_value("unlocked_level", 1))
	root.add_child(_label("%s   /   WORLD %02d" % [WORLD_NAMES[world - 1], world], 13, MUTED))
	var progress := _label("YOUR JOURNEY     %d / 12 LEVELS" % clampi(unlocked - first_level, 0, 12), 15, Color("#FFD166"), true)
	root.add_child(progress)
	var target_lines := 3 + int((first_level - 1) / 4)
	root.add_child(_label("LEVEL OBJECTIVE  •  CLEAR %d LINES" % target_lines, 12, TEAL, true))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)
	for local_level in range(12):
		var global_level := first_level + local_level
		var is_unlocked := global_level <= unlocked
		var marker := "★" if global_level < unlocked else ("▶" if is_unlocked else "🔒")
		var tile := _button("%02d\n%s" % [local_level + 1, marker], TEAL if global_level == unlocked else PANEL)
		tile.custom_minimum_size = Vector2(90, 92)
		tile.disabled = not is_unlocked
		tile.pressed.connect(func(): _start_level(global_level))
		grid.add_child(tile)
	_add_bottom_button(root, "BACK TO WORLDS", Color("#293657"), func(): AppRouter.open_adventure_map())

func _start_level(level: int) -> void:
	SaveData.set_value("current_level", level)
	SaveData.set_value("active_mode", "classic")
	SaveData.set_value("adventure_active", true)
	AppRouter.start_classic()

func _add_bottom_button(root: VBoxContainer, caption: String, fill: Color, action: Callable) -> void:
	var button := _button(caption, fill)
	button.custom_minimum_size.y = 56
	button.pressed.connect(action)
	root.add_child(button)

func _label(value: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 1)
	return label

func _button(value: String, fill: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_stylebox_override("normal", _panel_style(fill))
	button.add_theme_stylebox_override("hover", _panel_style(fill.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _panel_style(fill.darkened(0.08)))
	return button

func _panel_style(fill: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = Color("#344466")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
