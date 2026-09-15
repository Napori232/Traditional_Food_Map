extends PanelContainer

signal category_selected(category: String)

const APP_GLOBAL := preload("res://global/app_global.gd")
const CATEGORY_COLORS := {
	APP_GLOBAL.CATEGORY_MAIN: Color("#d46b4d"),
	APP_GLOBAL.CATEGORY_SNACK: Color("#d49a43"),
	APP_GLOBAL.CATEGORY_DESSERT: Color("#b9769b"),
	APP_GLOBAL.CATEGORY_DRINK: Color("#4b8f89")
}

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
		button.add_theme_color_override("font_color", Color("#302c25"))
		button.add_theme_stylebox_override("normal", _category_style_box(category, 0.72))
		button.add_theme_stylebox_override("hover", _category_style_box(category, 0.62))
		button.add_theme_stylebox_override("pressed", _category_style_box(category, 0.52))
		button.pressed.connect(_on_category_pressed.bind(category))
		row.add_child(button)

func _on_category_pressed(category: String) -> void:
	category_selected.emit(category)

func _category_style_box(category: String, tint: float) -> StyleBoxFlat:
	var color: Color = CATEGORY_COLORS.get(category, Color("#d8c9ac"))
	return _style_box(color.lightened(tint), color.darkened(0.04), 10, 1)

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
