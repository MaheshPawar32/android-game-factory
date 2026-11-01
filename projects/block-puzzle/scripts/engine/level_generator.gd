extends RefCounted
class_name BlockverseLevelGenerator
## Procedurally derives a repeatable level configuration from its global level number.

const LEVELS_PER_WORLD := 12
const WORLD_NAMES := ["CRYSTAL GROVE", "EMBER CANYON", "FROST PEAKS", "STARLIGHT BAY", "NEBULA FRONTIER", "ANCIENT RUINS", "SHADOW REALM", "SOLAR CITADEL"]

static func world_for_level(level: int) -> int:
	return maxi(1, int(ceil(float(maxi(level, 1)) / float(LEVELS_PER_WORLD))))

static func world_name(world: int) -> String:
	var index := posmod(maxi(world, 1) - 1, WORLD_NAMES.size())
	var cycle := int((maxi(world, 1) - 1) / WORLD_NAMES.size())
	return WORLD_NAMES[index] if cycle == 0 else "%s %d" % [WORLD_NAMES[index], cycle + 1]

static func level_seed(level: int) -> int:
	var safe_level := maxi(level, 1)
	return int((safe_level * 104729 + 20261101) % 2147483647)

static func configuration(level: int) -> Dictionary:
	var safe_level := maxi(level, 1)
	var difficulty_step := int((safe_level - 1) / 20)
	var objective := mini(3 + difficulty_step, 20)
	var suggested_board := clampi(5 + int((safe_level - 1) / 100), 5, 10)
	var reward := mini(50 + safe_level * 5, 500)
	var is_boss := safe_level % 25 == 0
	var is_score_trial := safe_level % 7 == 0 and not is_boss
	var move_limit := objective * 5 + 10 if safe_level % 5 == 0 else 0
	if is_boss:
		move_limit = objective * 5 + 8
	var objective_type := "boss" if is_boss else ("score" if is_score_trial else ("limited_moves" if move_limit > 0 else "lines"))
	var target_score := mini(250 + safe_level * 8, 5000) if is_score_trial else 0
	return {
		"level": safe_level,
		"world": world_for_level(safe_level),
		"world_name": world_name(world_for_level(safe_level)),
		"seed": level_seed(safe_level),
		"objective_lines": objective * 2 if is_boss else objective,
		"objective_type": objective_type,
		"move_limit": move_limit,
		"target_score": target_score,
		"is_boss": is_boss,
		"suggested_board_size": suggested_board,
		"reward_coins": reward,
		"difficulty": "STARTER" if safe_level <= 20 else ("RISING" if safe_level <= 100 else ("EXPERT" if safe_level <= 500 else "MASTER"))
	}

static func is_supported(level: int) -> bool:
	return level >= 1 and level <= 999999
