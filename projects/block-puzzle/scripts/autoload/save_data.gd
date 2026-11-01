extends Node

const SAVE_PATH := "user://blockverse_save.cfg"
const SAVE_VERSION := 5
const MISSION_DEFINITIONS := {
	"place_blocks": {"title": "Place 25 blocks", "target": 25, "reward": 40, "xp": 30},
	"clear_lines": {"title": "Clear 5 lines", "target": 5, "reward": 50, "xp": 35},
	"play_games": {"title": "Play 2 rounds", "target": 2, "reward": 35, "xp": 25}
}
const BOARD_SKINS := {
	"classic": {"title": "Classic Neon", "price": 0, "colors": ["#20C8D9", "#7657F6", "#FFB547", "#FF658B", "#55D68B", "#62A7FF"]},
	"aurora": {"title": "Aurora Glow", "price": 180, "colors": ["#50E3C2", "#5B8DEF", "#B18CFF", "#F58CCB", "#9CEB7A", "#FFD166"]},
	"sunset": {"title": "Sunset Rush", "price": 220, "colors": ["#FF6B6B", "#F7B267", "#F79D65", "#C86BFA", "#F25F5C", "#FFD166"]},
	"ocean": {"title": "Deep Ocean", "price": 260, "colors": ["#00B4D8", "#0077B6", "#48CAE4", "#90E0EF", "#4361EE", "#4CC9F0"]},
	"forest": {"title": "Forest Calm", "price": 300, "colors": ["#588157", "#A3B18A", "#DAD7CD", "#3A5A40", "#6A994E", "#BC6C25"]}
}
const ACHIEVEMENTS := {
	"first_game": {"title": "First Steps", "description": "Finish your first round", "target": 1, "reward": 30},
	"first_line": {"title": "Line Maker", "description": "Clear your first line", "target": 1, "reward": 30},
	"score_500": {"title": "Rising Star", "description": "Reach a score of 500", "target": 500, "reward": 50},
	"combo_3": {"title": "Combo Master", "description": "Reach a 3× combo", "target": 3, "reward": 60},
	"lines_100": {"title": "Clear Skies", "description": "Clear 100 lines in total", "target": 100, "reward": 100}
}

var data: Dictionary = {}

func _ready() -> void:
	load_data()
	refresh_daily_missions()

func load_data() -> void:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	data = config.get_value("save", "data", _default_data()) if error == OK else _default_data()
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
	return data.get("settings", {}).get(key, fallback)

func add_coins(amount: int, reason: String = "Reward") -> void:
	if amount <= 0:
		return
	data["coins"] = int(data.get("coins", 0)) + amount
	var history: Array = data.get("wallet_history", [])
	history.push_front({"amount": amount, "reason": reason, "date": _today_key()})
	while history.size() > 20:
		history.pop_back()
	data["wallet_history"] = history
	save_data()

func owns_skin(skin_id: String) -> bool:
	return skin_id == "classic" or skin_id in data.get("owned_skins", ["classic"])

func selected_skin() -> String:
	return str(data.get("selected_skin", "classic"))

func purchase_skin(skin_id: String) -> bool:
	if not BOARD_SKINS.has(skin_id) or owns_skin(skin_id):
		return false
	var price := int(BOARD_SKINS[skin_id].price)
	if int(data.get("coins", 0)) < price:
		return false
	data["coins"] = int(data.get("coins", 0)) - price
	var owned: Array = data.get("owned_skins", ["classic"])
	owned.append(skin_id)
	data["owned_skins"] = owned
	var history: Array = data.get("wallet_history", [])
	history.push_front({"amount": -price, "reason": "Board skin: %s" % BOARD_SKINS[skin_id].title, "date": _today_key()})
	data["wallet_history"] = history
	save_data()
	return true

func select_skin(skin_id: String) -> bool:
	if not owns_skin(skin_id):
		return false
	data["selected_skin"] = skin_id
	save_data()
	return true

func add_xp(amount: int, reason: String = "Gameplay") -> void:
	if amount <= 0:
		return
	var xp := int(data.get("player_xp", 0)) + amount
	var level := int(data.get("player_level", 1))
	while xp >= xp_to_next_level(level):
		xp -= xp_to_next_level(level)
		level += 1
		add_coins(25, "Level %d reward" % level)
	data["player_xp"] = xp
	data["player_level"] = level
	data["last_xp_reason"] = reason
	save_data()

func xp_to_next_level(level: int = -1) -> int:
	var current := int(data.get("player_level", 1)) if level < 1 else level
	return 100 + (current - 1) * 50

func refresh_daily_missions() -> void:
	var today := _today_key()
	if str(data.get("mission_date", "")) == today:
		return
	data["mission_date"] = today
	data["daily_missions"] = {
		"place_blocks": 0,
		"clear_lines": 0,
		"play_games": 0
	}
	data["mission_claimed"] = {}
	save_data()

func record_placement(block_count: int) -> void:
	_increment_mission("place_blocks", maxi(block_count, 0))
	_check_achievement("first_game", int(data.get("games_played", 0)) > 0)
	add_xp(maxi(1, block_count), "Block placement")

func record_lines_cleared(lines: int) -> void:
	if lines <= 0:
		return
	data["total_lines_cleared"] = int(data.get("total_lines_cleared", 0)) + lines
	_increment_mission("clear_lines", lines)
	_check_achievement("first_line", true)
	_check_achievement("lines_100", int(data["total_lines_cleared"]) >= 100)
	add_xp(lines * 8, "Line clear")
	save_data()

func record_combo(combo_value: int) -> void:
	_check_achievement("combo_3", combo_value >= 3)

func record_game_completed(final_score: int) -> void:
	data["games_played"] = int(data.get("games_played", 0)) + 1
	_increment_mission("play_games", 1)
	_check_achievement("first_game", true)
	_check_achievement("score_500", final_score >= 500)
	add_xp(20 + mini(final_score / 100, 50), "Round completed")
	save_data()

func record_mode_score(mode_id: String, value: int) -> void:
	var records: Dictionary = data.get("mode_records", {})
	records[mode_id] = maxi(int(records.get(mode_id, 0)), value)
	data["mode_records"] = records
	save_data()

func record_level_completion(level: int, final_score: int, stars: int) -> void:
	var records: Dictionary = data.get("level_records", {})
	var key := str(maxi(level, 1))
	var previous: Dictionary = records.get(key, {})
	records[key] = {"best_score": maxi(int(previous.get("best_score", 0)), final_score), "stars": maxi(int(previous.get("stars", 0)), clampi(stars, 1, 3))}
	data["level_records"] = records
	save_data()

func level_stars(level: int) -> int:
	return int(data.get("level_records", {}).get(str(maxi(level, 1)), {}).get("stars", 0))

func mode_record(mode_id: String) -> int:
	return int(data.get("mode_records", {}).get(mode_id, 0))

func mission_progress(mission_id: String) -> int:
	return int(data.get("daily_missions", {}).get(mission_id, 0))

func mission_claimed(mission_id: String) -> bool:
	return bool(data.get("mission_claimed", {}).get(mission_id, false))

func claim_mission(mission_id: String) -> bool:
	refresh_daily_missions()
	if not MISSION_DEFINITIONS.has(mission_id) or mission_claimed(mission_id):
		return false
	var definition: Dictionary = MISSION_DEFINITIONS[mission_id]
	if mission_progress(mission_id) < int(definition.target):
		return false
	var claimed: Dictionary = data.get("mission_claimed", {})
	claimed[mission_id] = true
	data["mission_claimed"] = claimed
	add_coins(int(definition.reward), "Daily mission")
	add_xp(int(definition.xp), "Daily mission")
	save_data()
	return true

func achievement_unlocked(achievement_id: String) -> bool:
	return bool(data.get("achievements", {}).get(achievement_id, false))

func _check_achievement(achievement_id: String, condition: bool) -> void:
	if not condition or not ACHIEVEMENTS.has(achievement_id) or achievement_unlocked(achievement_id):
		return
	var unlocked: Dictionary = data.get("achievements", {})
	unlocked[achievement_id] = true
	data["achievements"] = unlocked
	add_coins(int(ACHIEVEMENTS[achievement_id].reward), "Achievement: %s" % ACHIEVEMENTS[achievement_id].title)
	add_xp(20, "Achievement")
	save_data()

func _increment_mission(mission_id: String, amount: int) -> void:
	refresh_daily_missions()
	var progress: Dictionary = data.get("daily_missions", {})
	var definition: Dictionary = MISSION_DEFINITIONS.get(mission_id, {})
	progress[mission_id] = mini(int(progress.get(mission_id, 0)) + amount, int(definition.get("target", 999999)))
	data["daily_missions"] = progress
	save_data()

func _today_key() -> String:
	var date := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [date.year, date.month, date.day]

func _default_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"player_name": "Player",
		"player_level": 1,
		"player_xp": 0,
		"coins": 250,
		"best_score": 0,
		"mode_records": {},
		"level_records": {},
		"daily_seed": 0,
		"games_played": 0,
		"total_lines_cleared": 0,
		"unlocked_world": 1,
		"unlocked_level": 1,
		"board_size": 5,
		"mission_date": "",
		"daily_missions": {},
		"mission_claimed": {},
		"achievements": {},
		"wallet_history": [],
		"selected_skin": "classic",
		"owned_skins": ["classic"],
		"settings": {"sound": true, "music": true, "vibration": true, "notifications": true}
	}

func _normalize_data() -> void:
	var defaults := _default_data()
	for key in defaults:
		if not data.has(key):
			data[key] = defaults[key]
	if not data.get("settings") is Dictionary:
		data["settings"] = defaults["settings"].duplicate(true)
	for key in defaults["settings"]:
		if not data["settings"].has(key):
			data["settings"][key] = defaults["settings"][key]
	for key in ["daily_missions", "mission_claimed", "achievements", "mode_records", "level_records"]:
		if not data.get(key) is Dictionary:
			data[key] = {}
	for key in ["daily_missions", "mission_claimed", "achievements"]:
		if not data.get(key) is Dictionary:
			data[key] = {}
	if not data.get("wallet_history") is Array:
		data["wallet_history"] = []
	if not data.get("owned_skins") is Array:
		data["owned_skins"] = ["classic"]
	if str(data.get("selected_skin", "classic")) not in data["owned_skins"]:
		data["selected_skin"] = "classic"
	data["board_size"] = clampi(int(data.get("board_size", 5)), 5, 10)
	data["save_version"] = SAVE_VERSION
