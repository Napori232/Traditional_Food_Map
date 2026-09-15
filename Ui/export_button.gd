extends Button

signal export_requested

func _ready() -> void:
	text = "导出"
	tooltip_text = "导出收藏与拉黑地图为 PNG"
	custom_minimum_size = Vector2(68, 44)
	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color("#302c25"))
	add_theme_color_override("font_hover_color", Color("#302c25"))
	add_theme_stylebox_override("normal", _style_box(Color("#f7efdf"), Color("#d8c9ac"), 12, 1))
	add_theme_stylebox_override("hover", _style_box(Color("#eee2cb"), Color("#cbb996"), 12, 1))
	add_theme_stylebox_override("pressed", _style_box(Color("#e5d7bc"), Color("#b9a27c"), 12, 1))
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	export_requested.emit()

func _style_box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
