extends Control
class_name BlockverseBoardView

signal pointer_moved(local_position: Vector2)
signal pointer_released(local_position: Vector2)

const GRID_SIZE := 10
const GAP := 5.0
const INSET := 8.0
const COLORS: Array[Color] = [
	Color("#20C8D9"), Color("#7657F6"), Color("#FFB547"),
	Color("#FF658B"), Color("#55D68B"), Color("#62A7FF")
]

var board_model: RefCounted
var preview_shape: Array[Vector2i] = []
var preview_origin := Vector2i(-1, -1)
var preview_valid := false
var last_cleared_rows: Array = []
var last_cleared_columns: Array = []
var _clear_flash := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func set_board(model: RefCounted) -> void:
	board_model = model
	queue_redraw()

func set_preview(shape: Array[Vector2i], origin: Vector2i, valid: bool) -> void:
	preview_shape = shape
	preview_origin = origin
	preview_valid = valid
	queue_redraw()

func clear_preview() -> void:
	preview_shape.clear()
	preview_origin = Vector2i(-1, -1)
	queue_redraw()

func flash_lines(rows: Array, columns: Array) -> void:
	last_cleared_rows = rows.duplicate()
	last_cleared_columns = columns.duplicate()
	_clear_flash = 1.0
	var tween := create_tween()
	tween.tween_property(self, "_clear_flash", 0.0, 0.24)
	tween.tween_callback(queue_redraw)
	queue_redraw()

func cell_from_position(position: Vector2) -> Vector2i:
	var cell_size := _cell_size()
	var step := cell_size + GAP
	var local := position - Vector2(INSET, INSET)
	return Vector2i(floori(local.x / step), floori(local.y / step))

func is_inside_board(position: Vector2) -> bool:
	var side := _board_side()
	return Rect2(Vector2(INSET, INSET), Vector2(side, side)).has_point(position)

func _board_side() -> float:
	return maxf(0.0, minf(size.x, size.y) - INSET * 2.0)

func _cell_size() -> float:
	return (_board_side() - GAP * (GRID_SIZE - 1)) / GRID_SIZE

func _draw() -> void:
	if board_model == null:
		return
	var cell := _cell_size()
	var step := cell + GAP
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var rect := Rect2(Vector2(INSET + x * step, INSET + y * step), Vector2(cell, cell))
			var value: int = board_model.get_cell(x, y)
			var fill := Color("#202B45")
			if value != -1:
				fill = COLORS[posmod(value, COLORS.size())]
			if _clear_flash > 0.0 and ((y in last_cleared_rows) or (x in last_cleared_columns)):
				fill = fill.lerp(Color.WHITE, _clear_flash * 0.75)
			draw_rect(rect, fill, true)
			if value != -1:
				draw_rect(rect, fill.lightened(0.16), false, 1.4)
			else:
				draw_rect(rect, Color("#33415F"), false, 1.0)
	if not preview_shape.is_empty() and preview_origin.x >= 0:
		for offset in preview_shape:
			var point := preview_origin + offset
			if point.x < 0 or point.x >= GRID_SIZE or point.y < 0 or point.y >= GRID_SIZE:
				continue
			var rect := Rect2(Vector2(INSET + point.x * step, INSET + point.y * step), Vector2(cell, cell))
			var ghost := Color("#55E6B7", 0.62) if preview_valid else Color("#FF5368", 0.62)
			draw_rect(rect, ghost, true)
			draw_rect(rect, Color.WHITE, false, 1.5)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if not event.pressed:
			pointer_released.emit(event.position)
			accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			pointer_released.emit(event.position)
			accept_event()
	elif event is InputEventScreenDrag:
		pointer_moved.emit(event.position)
	elif event is InputEventMouseMotion:
		pointer_moved.emit(event.position)
