extends Control
## Procedural Adventure map and paged level browser. Levels are generated from their number.
const LevelData = preload("res://scripts/engine/level_generator.gd")
const BG := Color("#101426")
const PANEL := Color("#202943")
const TEXT := Color("#F6F5FF")
const MUTED := Color("#A7B0CC")
const TEAL := Color("#25B8A8")

func _ready() -> void:
	_build()

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var title := _label("ADVENTURE", 26, TEXT, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var back := _button("⌂", Color("#293657"))
	back.custom_minimum_size = Vector2(48, 46)
	back.pressed.connect(func(): AppRouter.go_home())
	top.add_child(back)
	if name == "AdventureMap":
		_build_world_map(root)
	else:
		_build_level_select(root)

func _build_world_map(root: VBoxContainer) -> void:
	var unlocked_level := int(SaveData.get_value("unlocked_level", 1))
	var unlocked_world := LevelData.world_for_level(unlocked_level)
	SaveData.set_value("unlocked_world", unlocked_world)
	root.add_child(_label("5,000+ LEVELS • PROCEDURALLY GENERATED", 13, TEAL, true))
	root.add_child(_label("Every level has its own repeatable puzzle sequence and growing objective.", 12, MUTED))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	var first_world := maxi(1, unlocked_world - 3)
	var last_world := unlocked_world + 1
	for world_id in range(first_world, last_world + 1):
		var first_level := (world_id - 1) * LevelData.LEVELS_PER_WORLD + 1
		var completed := clampi(unlocked_level - first_level, 0, LevelData.LEVELS_PER_WORLD)
		var is_open := first_level <= unlocked_level
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _panel_style(Color("#182B4B") if world_id == unlocked_world else PANEL))
		list.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		row.add_child(line)
		line.add_child(_label("✦" if is_open else "🔒", 25, Color("#FFD166"), true))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(info)
		info.add_child(_label("WORLD %03d  •  %s" % [world_id, LevelData.world_name(world_id)], 14, TEXT, true))
		info.add_child(_label("%d / 12 levels completed" % completed, 11, MUTED))
		var action := _button("ENTER" if is_open else "LOCKED", TEAL if is_open else Color("#34405C"))
		action.disabled = not is_open
		action.pressed.connect(func(): SaveData.set_value("selected_world", world_id); AppRouter.open_level_select())
		line.add_child(action)
	_add_bottom_button(root, "CONTINUE • LEVEL %d" % unlocked_level, TEAL, func(): SaveData.set_value("selected_world", unlocked_world); AppRouter.open_level_select())

func _build_level_select(root: VBoxContainer) -> void:
	var world_id := maxi(1, int(SaveData.get_value("selected_world", 1)))
	var first_level := (world_id - 1) * LevelData.LEVELS_PER_WORLD + 1
	var unlocked := int(SaveData.get_value("unlocked_level", 1))
	root.add_child(_label("WORLD %03d  •  %s" % [world_id, LevelData.world_name(world_id)], 14, MUTED, true))
	root.add_child(_label("UNLOCKED THROUGH LEVEL %d" % unlocked, 13, Color("#FFD166"), true))
	var sample := LevelData.configuration(first_level)
	root.add_child(_label("LEVEL OBJECTIVE  •  CLEAR %d LINES" % int(sample.objective_lines), 12, TEAL, true))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	for local_level in range(LevelData.LEVELS_PER_WORLD):
		var global_level := first_level + local_level
		var config := LevelData.configuration(global_level)
		var is_unlocked := global_level <= unlocked
		var marker := "★" if global_level < unlocked else ("▶" if is_unlocked else "🔒")
		var tile := _button("%02d\n%s" % [local_level + 1, marker], TEAL if global_level == unlocked else PANEL)
		tile.custom_minimum_size = Vector2(86, 76)
		tile.disabled = not is_unlocked
		tile.tooltip_text = "Level %d • %s • Clear %d lines" % [global_level, config.difficulty, config.objective_lines]
		tile.pressed.connect(func(): _start_level(global_level))
		grid.add_child(tile)
	_add_bottom_button(root, "BACK TO WORLDS", Color("#293657"), func(): AppRouter.open_adventure_map())

func _start_level(level: int) -> void:
	if not LevelData.is_supported(level):
		return
	SaveData.set_value("current_level", level)
	SaveData.set_value("active_mode", "classic")
	SaveData.set_value("adventure_active", true)
	AppRouter.start_classic()

func _add_bottom_button(root: VBoxContainer, caption: String, fill: Color, action: Callable) -> void:
	var button := _button(caption, fill)
	button.custom_minimum_size.y = 54
	button.pressed.connect(action)
	root.add_child(button)

func _label(value: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if bold:
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 1)
	return label

func _button(value: String, fill: Color) -> Button:
	var button := Button.new()
	button.text = value
	button.add_theme_font_size_override("font_size", 15)
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
	style.set_corner_radius_all(16)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
