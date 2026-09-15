extends Control

signal selected(shop_id: String)

var shop: Dictionary = {}
var is_favorite := false
var is_blocked := false
var is_search_result := false
var marker_color := Color("#527a6b")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(190, 48)

## Assigns the shop record represented by this marker.
func SetShop(value: Dictionary) -> void:
	shop = value
	queue_redraw()

## Updates the marker icon state and search emphasis.
func SetState(favorite: bool, blocked: bool, search_result: bool) -> void:
	is_favorite = favorite
	is_blocked = blocked
	is_search_result = search_result
	queue_redraw()

## Positions this marker at a map-local screen coordinate.
func SetMapPosition(value: Vector2) -> void:
	position = value - Vector2(4, 24)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selected.emit(shop.get("id", ""))
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		selected.emit(shop.get("id", ""))
		accept_event()

func _draw() -> void:
	if shop.is_empty():
		return
	var center := Vector2(8, 24)
	if is_search_result:
		draw_circle(center, 18.0, Color(marker_color, 0.12))
		draw_arc(center, 20.0, 0.0, TAU, 32, Color(marker_color, 0.72), 1.5, true)
	if is_blocked:
		_draw_poop_marker(center)
	elif is_favorite:
		draw_string(ThemeDB.fallback_font, Vector2(-3, 33), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("#d49c37"))
	else:
		draw_circle(center, 9.0, Color("#f8f2df"))
		draw_circle(center, 6.0, marker_color)
	draw_string(ThemeDB.fallback_font, Vector2(24, 29), shop.get("name", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#31403b"))

func _draw_poop_marker(center: Vector2) -> void:
	var brown := Color("#8b6049")
	var dark := Color("#3b3029")
	draw_circle(center + Vector2(0, 5), 10, brown)
	draw_circle(center + Vector2(-6, 0), 7, brown)
	draw_circle(center + Vector2(5, -1), 7, brown)
	draw_circle(center + Vector2(-2, -7), 6, brown)
	draw_circle(center + Vector2(-3, 2), 1.4, dark)
	draw_circle(center + Vector2(4, 2), 1.4, dark)
	draw_arc(center + Vector2(0, 3), 3.5, 0.2, 2.9, 10, dark, 1.2, true)
