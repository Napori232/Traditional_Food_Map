extends "res://scenes/map/layers/map_layer_base.gd"

const DISTRICT_FILL := Color("#f2eadb")
const DISTRICT_LINE := Color("#c8bda9")
const CITY_BORDER := Color("#a99b82")

func _draw() -> void:
	var data := _map_data()
	if data == null:
		return
	for district in data.GetDistricts():
		var points: PackedVector2Array = district["points"]
		var screen_points := PackedVector2Array()
		for point in points:
			screen_points.append(_world_to_screen(point))
		draw_colored_polygon(screen_points, DISTRICT_FILL)
		draw_polyline(screen_points + PackedVector2Array([screen_points[0]]), DISTRICT_LINE, 1.0 * _map_scale(), true)
	var city_border := PackedVector2Array([
		_world_to_screen(Vector2(80, 120)), _world_to_screen(Vector2(470, 90)),
		_world_to_screen(Vector2(1010, 115)), _world_to_screen(Vector2(1370, 120)),
		_world_to_screen(Vector2(1530, 500)), _world_to_screen(Vector2(1510, 890)),
		_world_to_screen(Vector2(1080, 1080)), _world_to_screen(Vector2(180, 1060)),
		_world_to_screen(Vector2(50, 940)), _world_to_screen(Vector2(80, 120))
	])
	draw_polyline(city_border, CITY_BORDER, 2.0 * _map_scale(), true)
