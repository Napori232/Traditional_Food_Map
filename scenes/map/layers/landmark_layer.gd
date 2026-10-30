extends "res://scenes/map/layers/map_layer_base.gd"

const LANDMARK_INK := Color("#806c4c")
const PARK_INK := Color("#86a98d")
const WATER_INK := Color("#5f9697")
const STATION_INK := Color("#bd7d5f")

func _draw() -> void:
	var data := _map_data()
	if data == null:
		return
	for landmark in data.GetLandmarks():
		var position: Vector2 = _world_to_screen(landmark["position"])
		var type: String = landmark["type"]
		var color := LANDMARK_INK
		if type == "park":
			color = PARK_INK
		elif type == "water":
			color = WATER_INK
		elif type == "station" or type == "airport":
			color = STATION_INK
		_draw_landmark_icon(position, type, color)

func _draw_landmark_icon(position: Vector2, type: String, color: Color) -> void:
	var scale := _map_scale()
	if type == "water":
		_draw_ellipse(position, Vector2(18, 10) * scale, Color("#d5ebe4"))
		draw_arc(position, 18.0 * scale, 0.0, TAU, 24, WATER_INK, 1.2 * scale, true)
	elif type == "temple":
		draw_colored_polygon(PackedVector2Array([
			position + Vector2(-14, 5) * scale,
			position + Vector2(14, 5) * scale,
			position + Vector2(0, -10) * scale
		]), Color("#c57f63"))
		draw_rect(Rect2(position + Vector2(-9, 5) * scale, Vector2(18, 10) * scale), Color("#e4c28e"))
	elif type == "tower":
		draw_colored_polygon(PackedVector2Array([
			position + Vector2(-7, 13) * scale,
			position + Vector2(7, 13) * scale,
			position + Vector2(4, -7) * scale,
			position + Vector2(-4, -7) * scale
		]), Color("#c47a5f"))
		draw_line(position + Vector2(-10, -7) * scale, position + Vector2(10, -7) * scale, color, 2.0 * scale)
		draw_line(position + Vector2(-7, -12) * scale, position + Vector2(7, -12) * scale, color, 1.5 * scale)
	elif type == "park":
		draw_circle(position + Vector2(-7, 2) * scale, 7 * scale, PARK_INK)
		draw_circle(position + Vector2(5, -2) * scale, 8 * scale, Color("#9abf8a"))
		draw_rect(Rect2(position + Vector2(-2, 6) * scale, Vector2(4, 9) * scale), Color("#987c5d"))
	elif type == "station":
		draw_rect(Rect2(position + Vector2(-14, -8) * scale, Vector2(28, 16) * scale), Color("#f1d29a"))
		draw_line(position + Vector2(-9, -8) * scale, position + Vector2(-9, 8) * scale, color, 2.0 * scale)
		draw_line(position + Vector2(0, -8) * scale, position + Vector2(0, 8) * scale, color, 2.0 * scale)
		draw_line(position + Vector2(9, -8) * scale, position + Vector2(9, 8) * scale, color, 2.0 * scale)
	elif type == "stadium":
		_draw_ellipse(position, Vector2(19, 12) * scale, Color("#d6c3a2"))
		_draw_ellipse(position, Vector2(10, 5) * scale, Color("#9cb8a0"))
		draw_arc(position, 19.0 * scale, 0.0, TAU, 24, color, 1.3 * scale, true)
	elif type == "airport":
		draw_line(position + Vector2(-20, 8) * scale, position + Vector2(20, -8) * scale, color, 5.0 * scale)
		draw_line(position + Vector2(-10, -12) * scale, position + Vector2(10, 12) * scale, color, 3.0 * scale)
		draw_circle(position, 4 * scale, Color("#f1d29a"))
	elif type == "heritage":
		draw_circle(position, 13 * scale, Color("#d8c295"))
		draw_circle(position, 7 * scale, Color("#b78c5e"))
		draw_circle(position, 2.5 * scale, Color("#f2dfad"))
	else:
		draw_circle(position, 8.0 * scale, Color("#f8f1df"))
		draw_circle(position, 5.0 * scale, color)

func _draw_ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(25):
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
