extends "res://scenes/map/layers/map_layer_base.gd"

const BUILDING_COLORS := [
	Color("#ead8b9"), Color("#e5cdb4"), Color("#d9d0bd"),
	Color("#e8d9c9"), Color("#d7c8ae")
]
const ROOF_COLORS := [
	Color("#bd8e72"), Color("#c59c68"), Color("#a9957d"), Color("#b57968")
]
const PARK_COLOR := Color("#b8cfae")
const PARK_DARK := Color("#7eaa7b")

func _draw() -> void:
	var data := _map_data()
	if data == null:
		return
	var block_index := 0
	for block in data.GetBuildingBlocks():
		var rect: Rect2 = block["rect"]
		var style: String = block["style"]
		var screen_rect := _world_rect_to_screen(rect)
		if style == "park":
			_draw_park(screen_rect, block_index)
		else:
			_draw_building_block(screen_rect, style, block_index)
		block_index += 1

func _draw_building_block(rect: Rect2, style: String, block_index: int) -> void:
	var columns := 4 if style == "dense" else 3
	var rows := 3 if style == "dense" else 2
	var gap := 5.0 * _map_scale()
	var cell_width := (rect.size.x - gap * float(columns + 1)) / float(columns)
	var cell_height := (rect.size.y - gap * float(rows + 1)) / float(rows)
	for row in range(rows):
		for column in range(columns):
			var offset := Vector2(
				gap + float(column) * (cell_width + gap),
				gap + float(row) * (cell_height + gap)
			)
			var building_rect := Rect2(rect.position + offset, Vector2(cell_width, cell_height))
			var color: Color = BUILDING_COLORS[(block_index + row + column) % BUILDING_COLORS.size()]
			_draw_building(building_rect, color, block_index + row + column)

func _draw_building(rect: Rect2, color: Color, seed_value: int) -> void:
	var roof_height := minf(5.0 * _map_scale(), rect.size.y * 0.25)
	var body := PackedVector2Array([
		rect.position + Vector2(1, roof_height),
		rect.position + Vector2(rect.size.x - 1, roof_height),
		rect.position + Vector2(rect.size.x - 1, rect.size.y),
		rect.position + Vector2(1, rect.size.y)
	])
	var roof := PackedVector2Array([
		rect.position + Vector2(0, roof_height),
		rect.position + Vector2(rect.size.x * 0.5, 0),
		rect.position + Vector2(rect.size.x, roof_height)
	])
	draw_colored_polygon(body, color)
	draw_colored_polygon(roof, ROOF_COLORS[seed_value % ROOF_COLORS.size()])
	draw_polyline(body + PackedVector2Array([body[0]]), Color("#a58d73"), 0.8 * _map_scale(), true)
	if rect.size.x > 16.0 * _map_scale():
		var window_color := Color("#f5e9bd")
		var window_width := maxf(2.0, rect.size.x * 0.12)
		var window_height := maxf(2.0, rect.size.y * 0.12)
		for window_x in [rect.position.x + rect.size.x * 0.32, rect.position.x + rect.size.x * 0.66]:
			draw_rect(Rect2(window_x, rect.position.y + rect.size.y * 0.52, window_width, window_height), window_color)

func _draw_park(rect: Rect2, seed_value: int) -> void:
	draw_style_box(_round_box(PARK_COLOR, Color("#93b18a"), 8), rect)
	var tree_count := 5 + seed_value % 3
	for index in range(tree_count):
		var ratio := float(index + 1) / float(tree_count + 1)
		var position := rect.position + Vector2(rect.size.x * ratio, rect.size.y * (0.35 + 0.25 * float(index % 2)))
		draw_circle(position, 4.0 * _map_scale(), PARK_DARK)
		draw_circle(position + Vector2(3, 2) * _map_scale(), 3.0 * _map_scale(), Color("#9fbd8b"))

func _world_rect_to_screen(rect: Rect2) -> Rect2:
	var top_left := _world_to_screen(rect.position)
	var bottom_right := _world_to_screen(rect.position + rect.size)
	return Rect2(top_left, bottom_right - top_left)

func _round_box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style
