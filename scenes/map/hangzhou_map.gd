extends Control

signal shop_selected(shop_id: String)

const MARKER_SCENE := preload("res://scenes/map/shop_marker.tscn")
const MAP_DATA_SCRIPT := preload("res://Data/map_data.gd")
const MAP_INK := Color("#5c665d")
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
var water_layer: Control
var district_layer: Control
var road_layer: Control
var building_layer: Control
var landmark_layer: Control
var label_layer: Control
var map_data: Node
var world_size := Vector2.ZERO
var _dragging := false
var _drag_origin := Vector2.ZERO
var _pan_origin := Vector2.ZERO
var _touch_origin := Vector2.ZERO
var _touch_panning := false

func _ready() -> void:
	marker_layer = get_node("MarkerLayer")
	water_layer = get_node("WaterLayer")
	district_layer = get_node("DistrictLayer")
	road_layer = get_node("RoadLayer")
	building_layer = get_node("BuildingLayer")
	landmark_layer = get_node("LandmarkLayer")
	label_layer = get_node("LabelLayer")
	map_data = MAP_DATA_SCRIPT.new()
	add_child(map_data)
	world_size = map_data.GetWorldSize()
	for layer in [water_layer, district_layer, building_layer, road_layer, landmark_layer, label_layer]:
		layer.SetMapData(map_data)
	_update_layer_views()
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
		_update_layer_views()
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	_draw_paper_grain()

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
		_update_layer_views()
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
		_update_layer_views()
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

func _world_to_screen(world_position: Vector2) -> Vector2:
	return size * 0.5 + (world_position - world_size * 0.5 + pan) * _map_scale()

func _map_scale() -> float:
	return minf(size.x / world_size.x, size.y / world_size.y) * 0.92 * zoom

func _set_zoom(value: float) -> void:
	zoom = clampf(value, 0.75, 1.8)
	_position_markers()
	_update_layer_views()
	queue_redraw()

func _update_layer_views() -> void:
	if water_layer == null:
		return
	for layer in [water_layer, district_layer, building_layer, road_layer, landmark_layer, label_layer]:
		layer.SetView(size, world_size, zoom, pan)
