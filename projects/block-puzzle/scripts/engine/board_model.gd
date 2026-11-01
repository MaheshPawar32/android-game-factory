extends RefCounted
class_name BlockverseBoard
## Pure game-board model with player-selectable square dimensions.

const MIN_SIZE := 5
const MAX_SIZE := 10
const DEFAULT_SIZE := 5
const EMPTY := -1

var size: int = DEFAULT_SIZE
var cells: Array = []

func _init(board_size: int = DEFAULT_SIZE) -> void:
	size = clampi(board_size, MIN_SIZE, MAX_SIZE)
	reset()

func set_size(board_size: int) -> void:
	size = clampi(board_size, MIN_SIZE, MAX_SIZE)
	reset()

func reset() -> void:
	cells.clear()
	for y in range(size):
		var row: Array[int] = []
		for x in range(size):
			row.append(EMPTY)
		cells.append(row)

func is_inside(x: int, y: int) -> bool:
	return x >= 0 and x < size and y >= 0 and y < size

func get_cell(x: int, y: int) -> int:
	if not is_inside(x, y):
		return EMPTY
	return int(cells[y][x])

func can_place(shape: Array[Vector2i], origin: Vector2i) -> bool:
	if shape.is_empty():
		return false
	for offset in shape:
		var point := origin + offset
		if not is_inside(point.x, point.y) or cells[point.y][point.x] != EMPTY:
			return false
	return true

func place(shape: Array[Vector2i], origin: Vector2i, block_id: int = 0) -> Dictionary:
	if not can_place(shape, origin):
		return {"success": false, "placed": [], "cleared_rows": [], "cleared_columns": [], "lines_cleared": 0}
	var placed: Array[Vector2i] = []
	for offset in shape:
		var point := origin + offset
		cells[point.y][point.x] = block_id
		placed.append(point)
	var cleared := clear_completed_lines()
	return {
		"success": true,
		"placed": placed,
		"cleared_rows": cleared.rows,
		"cleared_columns": cleared.columns,
		"lines_cleared": cleared.rows.size() + cleared.columns.size()
	}

func clear_completed_lines() -> Dictionary:
	var full_rows: Array[int] = []
	var full_columns: Array[int] = []
	for y in range(size):
		var full := true
		for x in range(size):
			if cells[y][x] == EMPTY:
				full = false
				break
		if full:
			full_rows.append(y)
	for x in range(size):
		var full := true
		for y in range(size):
			if cells[y][x] == EMPTY:
				full = false
				break
		if full:
			full_columns.append(x)
	for y in full_rows:
		for x in range(size):
			cells[y][x] = EMPTY
	for x in full_columns:
		for y in range(size):
			cells[y][x] = EMPTY
	return {"rows": full_rows, "columns": full_columns}

func has_any_placement(shape: Array[Vector2i]) -> bool:
	for y in range(size):
		for x in range(size):
			if can_place(shape, Vector2i(x, y)):
				return true
	return false

func is_full() -> bool:
	for y in range(size):
		for x in range(size):
			if cells[y][x] == EMPTY:
				return false
	return true

func to_dictionary() -> Dictionary:
	return {"size": size, "cells": cells.duplicate(true)}

func load_dictionary(snapshot: Dictionary) -> bool:
	var incoming_size := int(snapshot.get("size", -1))
	if incoming_size < MIN_SIZE or incoming_size > MAX_SIZE:
		return false
	var incoming: Variant = snapshot.get("cells")
	if not incoming is Array or incoming.size() != incoming_size:
		return false
	for y in range(incoming_size):
		if not incoming[y] is Array or incoming[y].size() != incoming_size:
			return false
		for x in range(incoming_size):
			if not (incoming[y][x] is int):
				return false
	size = incoming_size
	cells = incoming.duplicate(true)
	return true
