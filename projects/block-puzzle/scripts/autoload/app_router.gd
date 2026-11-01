extends Node
## Centralized scene navigation for BLOCKVERSE.

const HOME := "res://scenes/home.tscn"
const MODE_SELECT := "res://scenes/mode_select.tscn"
const CLASSIC_GAME := "res://scenes/main.tscn"
const ADVENTURE_MAP := "res://scenes/adventure_map.tscn"
const LEVEL_SELECT := "res://scenes/level_select.tscn"
const PROGRESSION := "res://scenes/progression.tscn"
const SHOP := "res://scenes/shop.tscn"

func go_home() -> void:
	_change_scene(HOME)

func open_mode_select() -> void:
	_change_scene(MODE_SELECT)

func start_classic() -> void:
	start_mode("classic")

func start_mode(mode_id: String) -> void:
	SaveData.set_value("active_mode", mode_id)
	if mode_id == "daily":
		var date := Time.get_date_dict_from_system()
		var date_key := "%04d%02d%02d" % [date.year, date.month, date.day]
		SaveData.set_value("daily_seed", date_key.hash())
	_change_scene(CLASSIC_GAME)

func open_adventure_map() -> void:
	_change_scene(ADVENTURE_MAP)

func open_level_select() -> void:
	_change_scene(LEVEL_SELECT)

func open_progression() -> void:
	_change_scene(PROGRESSION)

func open_shop() -> void:
	_change_scene(SHOP)

func _change_scene(path: String) -> void:
	var current := get_tree().current_scene
	if current == null:
		var immediate_error := get_tree().change_scene_to_file(path)
		if immediate_error != OK:
			push_error("BLOCKVERSE: failed to open scene %s (error %s)." % [path, immediate_error])
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	current.add_child(layer)
	var fade := ColorRect.new()
	fade.color = Color(0.02, 0.03, 0.08, 0.0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.16)
	tween.tween_callback(func():
		var error := get_tree().change_scene_to_file(path)
		if error != OK:
			layer.queue_free()
			push_error("BLOCKVERSE: failed to open scene %s (error %s)." % [path, error])
	)
