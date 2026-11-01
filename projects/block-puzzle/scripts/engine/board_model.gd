extends RefCounted
class_name BlockverseBoard
## Pure game-board model. No scene tree or UI dependencies.

const SIZE := 10
const EMPTY := -1

var cells: Array = []

func _init() -> void:
	reset()

func reset() -> void:
	cells.clear()
	for y in range(SIZE):
		var row: Array[int] = []
		for x in range(SIZE):
			row.append(EMPTY)
		cells.append(row)

func is_inside(x: int, y: int) -> bool:
	return x >= 0 and x < SIZE and y >= 0 and y < SIZE

func get_cell(x: int, y: int) -> int:
	if not is_inside(x, y):
		return EMPTY
	return int(cells[y][x])

func can_place(shape: Array[Vector2i], origin: Vector2i) -> bool:
	if shape.is_empty():
		return false
	for offset in shape:
		var point := origin + offset
		if not is_inside(point.x, point.y):
			return false
		if cells[point.y][point.x] != EMPTY:
			return false
	return true

func place(shape: Array[Vector2i], origin: Vector2i, block_id: int = 0) -> Dictionary:
	if not can_place(shape, origin):
		return {"success": false, "placed": [], "cleared_rows": [], "cleared_columns": []}
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
	for y in range(SIZE):
		var full := true
		for x in range(SIZE):
			if cells[y][x] == EMPTY:
				full = false
				break
		if full:
			full_rows.append(y)
	for x in range(SIZE):
		var full := true
		for y in range(SIZE):
			if cells[y][x] == EMPTY:
				full = false
				break
		if full:
			full_columns.append(x)

	# Clear the union of all completed rows and columns simultaneously.
	for y in full_rows:
		for x in range(SIZE):
			cells[y][x] = EMPTY
	for x in full_columns:
		for y in range(SIZE):
			cells[y][x] = EMPTY
	return {"rows": full_rows, "columns": full_columns}

func has_any_placement(shape: Array[Vector2i]) -> bool:
	for y in range(SIZE):
		for x in range(SIZE):
			if can_place(shape, Vector2i(x, y)):
				return true
	return false

func is_full() -> bool:
	for y in range(SIZE):
		for x in range(SIZE):
			if cells[y][x] == EMPTY:
				return false
	return true

func to_dictionary() -> Dictionary:
	return {"size": SIZE, "cells": cells.duplicate(true)}

func load_dictionary(snapshot: Dictionary) -> bool:
	if int(snapshot.get("size", -1)) != SIZE:
		return false
	var incoming: Variant = snapshot.get("cells")
	if not incoming is Array or incoming.size() != SIZE:
		return false
	for y in range(SIZE):
		if not incoming[y] is Array or incoming[y].size() != SIZE:
			return false
		for x in range(SIZE):
			if not (incoming[y][x] is int):
				return false
	cells = incoming.duplicate(true)
	return true
