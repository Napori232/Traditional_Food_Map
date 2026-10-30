extends "res://scenes/map/layers/map_layer_base.gd"

const ROAD_CORE := Color("#d7c8ae")
const ROAD_EDGE := Color("#f8f2e6")
const EXPRESSWAY_CORE := Color("#c4a96f")
const EXPRESSWAY_EDGE := Color("#fff5df")

func _draw() -> void:
	var data := _map_data()
	if data == null:
		return
	for road in data.GetRoads():
		var points: PackedVector2Array = road["points"]
		var screen_points := PackedVector2Array()
		for point in points:
			screen_points.append(_world_to_screen(point))
		var is_expressway: bool = road["class"] == "expressway"
		var is_local: bool = road["class"] == "local"
		var width := 7.0 if is_expressway else (2.0 if is_local else 4.0)
		var core := EXPRESSWAY_CORE if is_expressway else (Color("#d9d0bf") if is_local else ROAD_CORE)
		var edge := EXPRESSWAY_EDGE if is_expressway else (Color("#fbf7ee") if is_local else ROAD_EDGE)
		draw_polyline(screen_points, edge, (width + 3.0) * _map_scale(), true)
		draw_polyline(screen_points, core, width * _map_scale(), true)
