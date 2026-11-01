extends Control

var list: VBoxContainer

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
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var title := Label.new()
	title.text = "BOARD SKINS"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", BlockverseTheme.TEXT_PRIMARY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var coins := Label.new()
	coins.name = "CoinBalance"
	coins.text = "🪙 %d" % int(SaveData.get_value("coins", 0))
	coins.add_theme_color_override("font_color", BlockverseTheme.GOLD)
	coins.add_theme_font_size_override("font_size", 18)
	header.add_child(coins)
	var back := Button.new()
	back.text = "⌂"
	back.custom_minimum_size = Vector2(48, 46)
	back.pressed.connect(func(): AppRouter.go_home())
	header.add_child(back)
	var intro := Label.new()
	intro.text = "Unlock a new colour mood for your puzzle board. Purchases are saved on this device."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", BlockverseTheme.TEXT_MUTED)
	root.add_child(intro)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	_refresh()

func _refresh() -> void:
	for child in list.get_children():
		child.queue_free()
	for skin_id in SaveData.BOARD_SKINS:
		var skin: Dictionary = SaveData.BOARD_SKINS[skin_id]
		var owned := SaveData.owns_skin(skin_id)
		var selected := SaveData.selected_skin() == skin_id
		var card := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = BlockverseTheme.SURFACE
		style.border_color = BlockverseTheme.PRIMARY if selected else BlockverseTheme.SURFACE_RAISED
		style.set_border_width_all(1)
		style.set_corner_radius_all(16)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", style)
		list.add_child(card)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 9)
		card.add_child(box)
		var row := HBoxContainer.new()
		box.add_child(row)
		var name := Label.new()
		name.text = str(skin.title)
		name.add_theme_font_size_override("font_size", 17)
		name.add_theme_color_override("font_color", BlockverseTheme.TEXT_PRIMARY)
		name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name)
		var action := Button.new()
		action.custom_minimum_size = Vector2(110, 42)
		action.text = "SELECTED" if selected else ("SELECT" if owned else "🪙 %d" % int(skin.price))
		action.disabled = selected
		action.pressed.connect(func(): _on_skin_action(skin_id))
		row.add_child(action)
		var swatches := HBoxContainer.new()
		swatches.add_theme_constant_override("separation", 7)
		box.add_child(swatches)
		for hex in skin.colors:
			var swatch := ColorRect.new()
			swatch.color = Color(str(hex))
			swatch.custom_minimum_size = Vector2(34, 25)
			swatches.add_child(swatch)
		var caption := Label.new()
		caption.text = "Equipped" if selected else ("Owned" if owned else "Permanent unlock • one-time purchase")
		caption.add_theme_color_override("font_color", BlockverseTheme.TEXT_MUTED)
		caption.add_theme_font_size_override("font_size", 11)
		box.add_child(caption)
	var balance := get_node_or_null("CoinBalance") as Label
	if balance:
		balance.text = "🪙 %d" % int(SaveData.get_value("coins", 0))

func _on_skin_action(skin_id: String) -> void:
	if SaveData.owns_skin(skin_id):
		SaveData.select_skin(skin_id)
	else:
		if not SaveData.purchase_skin(skin_id):
			var dialog := AcceptDialog.new()
			dialog.title = "NOT ENOUGH COINS"
			dialog.dialog_text = "Play rounds, clear lines and complete missions to earn more coins."
			add_child(dialog)
			dialog.popup_centered()
			return
		SaveData.select_skin(skin_id)
	_refresh()
