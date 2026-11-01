extends Node
## Centralized scene navigation for BLOCKVERSE.

const HOME := "res://scenes/home.tscn"
const MODE_SELECT := "res://scenes/mode_select.tscn"
const CLASSIC_GAME := "res://scenes/main.tscn"

func go_home() -> void:
	_change_scene(HOME)

func open_mode_select() -> void:
	_change_scene(MODE_SELECT)

func start_classic() -> void:
	_change_scene(CLASSIC_GAME)

func _change_scene(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("BLOCKVERSE: failed to open scene %s (error %s)." % [path, error])
