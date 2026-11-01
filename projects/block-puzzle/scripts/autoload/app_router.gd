extends Node
## Centralized scene navigation for BLOCKVERSE.

const HOME := "res://scenes/home.tscn"
const MODE_SELECT := "res://scenes/mode_select.tscn"
const CLASSIC_GAME := "res://scenes/main.tscn"
const ADVENTURE_MAP := "res://scenes/adventure_map.tscn"
const LEVEL_SELECT := "res://scenes/level_select.tscn"

func go_home() -> void:
	_change_scene(HOME)

func open_mode_select() -> void:
	_change_scene(MODE_SELECT)

func start_classic() -> void:
	_change_scene(CLASSIC_GAME)

func open_adventure_map() -> void:
	_change_scene(ADVENTURE_MAP)

func open_level_select() -> void:
	_change_scene(LEVEL_SELECT)

func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("BLOCKVERSE: failed to open scene %s (error %s)." % [path, error])
