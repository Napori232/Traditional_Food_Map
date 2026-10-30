extends "res://scenes/map/layers/map_layer_base.gd"

const WATER_COLOR := Color("#c7e1e0")
const RIVER_COLOR := Color("#b4d5d6")
const WATER_LINE := Color("#7aa9a8")

func _draw() -> void:
	var data := _map_data()
	if data == null:
		return
	for feature in data.GetWaterFeatures():
		var points: PackedVector2Array = feature["points"]
		var screen_points := PackedVector2Array()
		for point in points:
			screen_points.append(_world_to_screen(point))
		if feature["type"] == "lake":
			draw_colored_polygon(screen_points, WATER_COLOR)
			draw_polyline(screen_points + PackedVector2Array([screen_points[0]]), WATER_LINE, 1.6 * _map_scale(), true)
		else:
			draw_polyline(screen_points, RIVER_COLOR, 16.0 * _map_scale(), true)
			draw_polyline(screen_points, WATER_LINE, 1.6 * _map_scale(), true)
