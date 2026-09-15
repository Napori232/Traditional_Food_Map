extends Control

signal shop_selected(shop_id: String)

const MARKER_SCENE := preload("res://scenes/map/shop_marker.tscn")
const WORLD_SIZE := Vector2(1200.0, 820.0)
const MAP_INK := Color("#5c665d")
const ROAD_INK := Color("#b4a98d")
const WATER := Color("#b7d3d0")
const PAPER := Color("#eee5d0")
const CATEGORY_COLORS := {
	"正餐": Color("#d46b4d"),
	"小吃": Color("#d49a43"),
	"甜品": Color("#b9769b"),
	"饮品": Color("#4b8f89")
}
const DETAIL_ZOOM_THRESHOLD := 1.18

var shops: Array[Dictionary] = []
var favorite_ids: Dictionary = {}
var blocked_ids: Dictionary = {}
var search_mode := false
var zoom := 1.0
var pan := Vector2.ZERO
var marker_layer: Control
var _dragging := false
var _drag_origin := Vector2.ZERO
var _pan_origin := Vector2.ZERO
var _touch_origin := Vector2.ZERO
var _touch_panning := false

func _ready() -> void:
	marker_layer = get_node("MarkerLayer")
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	_refresh_markers()
	queue_redraw()

## Rebuilds map marker nodes from data-layer shop records.
func SetShops(value: Array[Dictionary]) -> void:
	shops = value
	_refresh_markers()

## Updates which generated markers show favorite stars.
func SetFavoriteIds(value: Dictionary) -> void:
	favorite_ids = value
	_refresh_markers()

## Updates which generated markers show blocked icons.
func SetBlockedIds(value: Dictionary) -> void:
	blocked_ids = value
	_refresh_markers()

## Forces filtered search results to appear at every zoom level.
func SetSearchMode(value: bool) -> void:
	search_mode = value
	_refresh_markers()

## Enlarges the map without changing its current center offset.
func ZoomIn() -> void:
	_set_zoom(zoom + 0.15)

## Shrinks the map without changing its current center offset.
func ZoomOut() -> void:
	_set_zoom(zoom - 0.15)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_position_markers()
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	_draw_paper_grain()
	_draw_map_shape()
	_draw_map_labels()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			ZoomIn()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			ZoomOut()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_origin = event.position
				_pan_origin = pan
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		pan = _pan_origin + (event.position - _drag_origin) / _map_scale()
		_position_markers()
		queue_redraw()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_origin = event.position
			_pan_origin = pan
			_touch_panning = true
		else:
			_touch_panning = false
	elif event is InputEventScreenDrag and _touch_panning:
		pan = _pan_origin + (event.position - _touch_origin) / _map_scale()
		_position_markers()
		queue_redraw()

func _refresh_markers() -> void:
	if marker_layer == null:
		return
	for child in marker_layer.get_children():
		child.queue_free()
	for shop in shops:
		var marker = MARKER_SCENE.instantiate()
		var category: String = shop.get("category", "")
		marker.marker_color = CATEGORY_COLORS.get(category, MAP_INK)
		marker.SetShop(shop)
		marker.SetState(favorite_ids.has(shop["id"]), blocked_ids.has(shop["id"]), search_mode)
		marker.selected.connect(_on_marker_selected)
		marker_layer.add_child(marker)
	_position_markers()

func _position_markers() -> void:
	if marker_layer == null:
		return
	for marker in marker_layer.get_children():
		var shop: Dictionary = marker.shop
		var should_show: bool = search_mode or favorite_ids.has(shop["id"]) or blocked_ids.has(shop["id"]) or zoom >= DETAIL_ZOOM_THRESHOLD
		marker.visible = should_show
		marker.SetMapPosition(_world_to_screen(shop["position"]))

func _on_marker_selected(shop_id: String) -> void:
	shop_selected.emit(shop_id)

func _draw_paper_grain() -> void:
	for x in range(20, int(size.x), 38):
		draw_line(Vector2(x, 0), Vector2(x + 90, size.y), Color(0.37, 0.33, 0.24, 0.025), 1.0)
	for y in range(28, int(size.y), 46):
		draw_line(Vector2(0, y), Vector2(size.x, y + 25), Color(0.37, 0.33, 0.24, 0.02), 1.0)

func _draw_map_shape() -> void:
	var lake := PackedVector2Array([
		Vector2(260, 90), Vector2(390, 52), Vector2(530, 70), Vector2(625, 142),
		Vector2(650, 245), Vector2(620, 370), Vector2(552, 468), Vector2(446, 514),
		Vector2(348, 475), Vector2(278, 392), Vector2(245, 282), Vector2(242, 170)
	])
	var lake_screen := PackedVector2Array()
	for point in lake:
		lake_screen.append(_world_to_screen(point))
	draw_colored_polygon(lake_screen, WATER)
	draw_polyline(lake_screen + PackedVector2Array([lake_screen[0]]), Color("#6f9997"), 2.0, true)

	var roads := [
		[Vector2(80, 170), Vector2(290, 190), Vector2(500, 180), Vector2(790, 230), Vector2(1100, 190)],
		[Vector2(105, 360), Vector2(315, 335), Vector2(520, 355), Vector2(770, 330), Vector2(1110, 390)],
		[Vector2(175, 580), Vector2(330, 475), Vector2(520, 420), Vector2(760, 470), Vector2(1040, 630)],
		[Vector2(760, 65), Vector2(720, 220), Vector2(740, 390), Vector2(690, 735)],
		[Vector2(960, 70), Vector2(880, 240), Vector2(875, 445), Vector2(915, 760)]
	]
	for road in roads:
		var road_screen := PackedVector2Array()
		for point in road:
			road_screen.append(_world_to_screen(point))
		draw_polyline(road_screen, ROAD_INK, 8.0 * _map_scale(), true)
		draw_polyline(road_screen, Color(0.96, 0.92, 0.82, 0.55), 2.0 * _map_scale(), true)

	var districts := [
		Rect2(40, 42, 250, 140),
		Rect2(45, 410, 270, 250),
		Rect2(690, 35, 360, 155),
		Rect2(930, 430, 210, 290)
	]
	for rect in districts:
		var corners := PackedVector2Array([
			_world_to_screen(rect.position),
			_world_to_screen(rect.position + Vector2(rect.size.x, 0)),
			_world_to_screen(rect.position + rect.size),
			_world_to_screen(rect.position + Vector2(0, rect.size.y)),
			_world_to_screen(rect.position)
		])
		draw_polyline(corners, Color(0.35, 0.32, 0.24, 0.18), 1.0, true)

func _draw_map_labels() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, _world_to_screen(Vector2(305, 250)), "西湖", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.18, 0.38, 0.38, 0.5))
	draw_string(font, _world_to_screen(Vector2(78, 108)), "余杭区", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(78, 390)), "西湖区", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(735, 92)), "拱墅区", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(955, 485)), "上城区", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(112, 155)), "文一西路", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(110, 345)), "天目山路", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(95, 620)), "龙井路", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(785, 206)), "延安路", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 0.32, 0.24, 0.65))
	draw_string(font, _world_to_screen(Vector2(925, 680)), "解放路", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.35, 0.32, 0.24, 0.65))

func _world_to_screen(world_position: Vector2) -> Vector2:
	return size * 0.5 + (world_position - WORLD_SIZE * 0.5 + pan) * _map_scale()

func _map_scale() -> float:
	return minf(size.x / WORLD_SIZE.x, size.y / WORLD_SIZE.y) * 0.92 * zoom

func _set_zoom(value: float) -> void:
	zoom = clampf(value, 0.75, 1.8)
	_position_markers()
	queue_redraw()
