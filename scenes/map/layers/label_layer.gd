extends "res://scenes/map/layers/map_layer_base.gd"

const DISTRICT_TEXT := Color("#665d50")
const ROAD_TEXT := Color("#8b7659")
const LANDMARK_TEXT := Color("#534b40")
const WATER_TEXT := Color("#5d8f8e")

func _draw() -> void:
	var data := _map_data()
	if data == null:
		return
	var font := ThemeDB.fallback_font
	for district in data.GetDistricts():
		draw_string(font, _world_to_screen(district["label"]), district["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, DISTRICT_TEXT)
	for road in data.GetRoads():
		if road["class"] == "local" and map_zoom < 1.15:
			continue
		var points: PackedVector2Array = road["points"]
		var label_index := int(points.size() / 2)
		var label_position: Vector2 = _world_to_screen(points[label_index]) + Vector2(5, -6)
		var font_size := 9 if road["class"] == "local" else 11
		draw_string(font, label_position, road["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ROAD_TEXT)
	for landmark in data.GetLandmarks():
		var position: Vector2 = _world_to_screen(landmark["position"]) + Vector2(10, 4)
		var color: Color = WATER_TEXT if landmark["type"] == "water" else LANDMARK_TEXT
		draw_string(font, position, landmark["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
	draw_string(font, _world_to_screen(Vector2(610, 70)), "杭州市", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#4f493f"))
