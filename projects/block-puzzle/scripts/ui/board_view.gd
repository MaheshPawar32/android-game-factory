extends Control
class_name BlockverseBoardView

signal pointer_moved(local_position: Vector2)
signal pointer_released(local_position: Vector2)

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
var _special_flash_cells: Array[Vector2i] = []
var _special_flash_color := Color.WHITE
var _special_flash := 0.0
var _place_flash_cells: Array[Vector2i] = []
var _place_flash := 0.0

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
	var count := _grid_size()
	var cell_size := _cell_size()
	var step := cell_size + GAP
	var local := position - Vector2(INSET, INSET)
	return Vector2i(floori(local.x / step), floori(local.y / step))

func is_inside_board(position: Vector2) -> bool:
	var side := _board_side()
	return Rect2(Vector2(INSET, INSET), Vector2(side, side)).has_point(position)

func _grid_size() -> int:
	return int(board_model.size) if board_model != null else 5

func _board_side() -> float:
	return maxf(0.0, minf(size.x, size.y) - INSET * 2.0)

func _cell_size() -> float:
	var count := _grid_size()
	return (_board_side() - GAP * (count - 1)) / count

func flash_special_cells(points: Array, color: Color) -> void:
	_special_flash_cells.clear()
	for point in points:
		if point is Vector2i:
			_special_flash_cells.append(point)
	_special_flash_color = color
	_special_flash = 1.0
	var tween := create_tween()
	tween.tween_property(self, "_special_flash", 0.0, 0.32)
	tween.tween_callback(queue_redraw)
	queue_redraw()

func animate_placement(points: Array) -> void:
	_place_flash_cells.clear()
	for point in points:
		if point is Vector2i:
			_place_flash_cells.append(point)
	_place_flash = 1.0
	var tween := create_tween()
	tween.tween_property(self, "_place_flash", 0.0, 0.18)
	tween.tween_callback(queue_redraw)
	queue_redraw()

func _draw() -> void:
	if board_model == null:
		return
	var count := _grid_size()
	var cell := _cell_size()
	var step := cell + GAP
	for y in range(count):
		for x in range(count):
			var rect := Rect2(Vector2(INSET + x * step, INSET + y * step), Vector2(cell, cell))
			var value: int = board_model.get_cell(x, y)
			var fill := Color("#202B45")
			if value != -1:
				fill = COLORS[posmod(value, COLORS.size())]
			if _clear_flash > 0.0 and ((y in last_cleared_rows) or (x in last_cleared_columns)):
				fill = fill.lerp(Color.WHITE, _clear_flash * 0.75)
			if _special_flash > 0.0 and Vector2i(x, y) in _special_flash_cells:
				fill = fill.lerp(_special_flash_color, _special_flash * 0.82)
			if _place_flash > 0.0 and Vector2i(x, y) in _place_flash_cells:
				fill = fill.lerp(Color.WHITE, _place_flash * 0.48)
			draw_rect(rect, fill, true)
			draw_rect(rect, fill.lightened(0.16) if value != -1 else Color("#33415F"), false, 1.2)
	if not preview_shape.is_empty() and preview_origin.x >= 0:
		for offset in preview_shape:
			var point := preview_origin + offset
			if point.x < 0 or point.x >= count or point.y < 0 or point.y >= count:
				continue
			var rect := Rect2(Vector2(INSET + point.x * step, INSET + point.y * step), Vector2(cell, cell))
			var ghost := Color("#55E6B7", 0.62) if preview_valid else Color("#FF5368", 0.62)
			draw_rect(rect, ghost, true)
			draw_rect(rect, Color.WHITE, false, 1.5)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed:
		pointer_released.emit(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		pointer_released.emit(event.position)
		accept_event()
	elif event is InputEventScreenDrag:
		pointer_moved.emit(event.position)
	elif event is InputEventMouseMotion:
		pointer_moved.emit(event.position)
