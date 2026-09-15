extends PanelContainer

signal category_selected(category: String)

var row: HBoxContainer

func _ready() -> void:
	add_theme_stylebox_override("panel", _style_box(Color("#f8f1df"), Color("#cfc2a8"), 12, 1))
	row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)

## Rebuilds category buttons from data-layer category identifiers.
func SetCategories(categories: Array[String]) -> void:
	for child in row.get_children():
		child.queue_free()
	for category in categories:
		var button := Button.new()
		button.text = category
		button.custom_minimum_size = Vector2(70 if category == "全部" else 82, 34)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", Color("#4a5148"))
		button.add_theme_stylebox_override("normal", _style_box(Color("#eee5d0"), Color("#d9ccb3"), 10, 1))
		button.add_theme_stylebox_override("hover", _style_box(Color("#e2eadc"), Color("#90aa96"), 10, 1))
		button.pressed.connect(_on_category_pressed.bind(category))
		row.add_child(button)

func _on_category_pressed(category: String) -> void:
	category_selected.emit(category)

func _style_box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
