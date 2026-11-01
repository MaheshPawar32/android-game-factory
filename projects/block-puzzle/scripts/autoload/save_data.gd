extends Node
## Lightweight versioned local save layer. Uses ConfigFile for a dependency-free
## first milestone; data remains on-device and works offline.

const SAVE_PATH := "user://blockverse_save.cfg"
const SAVE_VERSION := 1

var data: Dictionary = {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == OK:
		data = config.get_value("save", "data", _default_data())
	else:
		data = _default_data()
	_normalize_data()
	save_data()

func save_data() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "version", SAVE_VERSION)
	config.set_value("save", "data", data)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_error("BLOCKVERSE: unable to save local data (error %s)." % error)

func get_value(key: String, fallback: Variant = null) -> Variant:
	return data.get(key, fallback)

func set_value(key: String, value: Variant) -> void:
	data[key] = value
	save_data()

func update_setting(key: String, value: Variant) -> void:
	var settings: Dictionary = data.get("settings", {})
	settings[key] = value
	data["settings"] = settings
	save_data()

func get_setting(key: String, fallback: Variant = null) -> Variant:
	var settings: Dictionary = data.get("settings", {})
	return settings.get(key, fallback)

func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	data["coins"] = int(data.get("coins", 0)) + amount
	save_data()

func _default_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"player_name": "Player",
		"player_level": 1,
		"player_xp": 0,
		"coins": 250,
		"best_score": 0,
		"games_played": 0,
		"total_lines_cleared": 0,
		"unlocked_world": 1,
		"unlocked_level": 1,
		"settings": {
			"sound": true,
			"music": true,
			"vibration": true,
			"notifications": true
		}
	}

func _normalize_data() -> void:
	var defaults := _default_data()
	for key in defaults:
		if not data.has(key):
			data[key] = defaults[key]
	if not data.get("settings") is Dictionary:
		data["settings"] = defaults["settings"]
	var settings: Dictionary = data["settings"]
	for key in defaults["settings"]:
		if not settings.has(key):
			settings[key] = defaults["settings"][key]
	data["save_version"] = SAVE_VERSION
