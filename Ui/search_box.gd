extends PanelContainer

signal query_changed(query: String)

var input: LineEdit
var clear_button: Button

func _ready() -> void:
	add_theme_stylebox_override("panel", _style_box(Color("#f7efdf"), Color("#d8c9ac"), 14, 1))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 3)
	margin.add_child(row)

	input = LineEdit.new()
	input.placeholder_text = "搜索店铺或食物"
	input.clear_button_enabled = false
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size = Vector2(0, 36)
	input.add_theme_font_size_override("font_size", 13)
	input.add_theme_color_override("font_color", Color("#302c25"))
	input.add_theme_color_override("font_placeholder_color", Color("#9d927b"))
	input.add_theme_color_override("caret_color", Color("#8b7857"))
	input.add_theme_stylebox_override("normal", _style_box(Color("#fffaf0"), Color("#eadfc8"), 9, 1))
	input.add_theme_stylebox_override("focus", _style_box(Color("#fffdf7"), Color("#cbb996"), 9, 1))
	input.text_changed.connect(_on_text_changed)
	row.add_child(input)

	clear_button = Button.new()
	clear_button.text = "×"
	clear_button.tooltip_text = "清空搜索"
	clear_button.custom_minimum_size = Vector2(34, 34)
	clear_button.add_theme_font_size_override("font_size", 21)
	clear_button.add_theme_color_override("font_color", Color("#302c25"))
	clear_button.add_theme_color_override("font_hover_color", Color("#302c25"))
	clear_button.add_theme_stylebox_override("normal", _style_box(Color("#f7efdf"), Color("#f7efdf"), 8, 0))
	clear_button.add_theme_stylebox_override("hover", _style_box(Color("#eee2cb"), Color("#eee2cb"), 8, 0))
	clear_button.add_theme_stylebox_override("pressed", _style_box(Color("#e5d7bc"), Color("#e5d7bc"), 8, 0))
	clear_button.pressed.connect(_on_clear_pressed)
	row.add_child(clear_button)
	clear_button.visible = not input.text.is_empty()

## Sets the visible search text without emitting a user search event.
func SetQuery(value: String) -> void:
	input.text = value

func _on_text_changed(value: String) -> void:
	clear_button.visible = not value.is_empty()
	query_changed.emit(value)

func _on_clear_pressed() -> void:
	input.clear()
	input.grab_focus()

func _style_box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	return style
