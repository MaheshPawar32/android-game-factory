extends RefCounted
class_name BlockversePieceGenerator
## Seedable generator for reproducible daily puzzles and deterministic tests.

var _rng := RandomNumberGenerator.new()
var _seed_value: int = 0

func set_seed(value: int) -> void:
	_seed_value = value
	_rng.seed = value

func randomize_seed() -> void:
	_rng.randomize()
	_seed_value = int(_rng.seed)

func get_seed() -> int:
	return _seed_value

func next_piece() -> Dictionary:
	var index := _rng.randi_range(0, BlockversePieces.shape_count() - 1)
	return make_piece(index)

func make_piece(shape_index: int, special_type: String = "normal") -> Dictionary:
	return {
		"shape_id": shape_index,
		"cells": BlockversePieces.get_shape(shape_index),
		"special_type": special_type,
		"color_id": _rng.randi_range(0, 5)
	}

func next_tray(count: int = 3) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in range(maxi(0, count)):
		result.append(next_piece())
	return result
