extends PanelContainer

signal closed
signal favorite_requested
signal blocked_requested
signal comment_submitted(text: String)

var current_shop: Dictionary = {}
var favorite_button: Button
var blocked_button: Button
var comment_input: TextEdit
var comments_box: VBoxContainer
var content: VBoxContainer

func _ready() -> void:
	visible = false
	add_theme_stylebox_override("panel", _style_box(Color("#f7efdf"), Color("#d8c9ac"), 14, 1))
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)

## Shows one shop and its current user-owned state.
func ShowShop(shop: Dictionary, favorite: bool, blocked: bool, comments: Array[Dictionary]) -> void:
	current_shop = shop
	visible = true
	_build_content(favorite, blocked, comments)

## Hides the detail panel and clears its selected shop.
func Clear() -> void:
	current_shop = {}
	visible = false

func _build_content(favorite: bool, blocked: bool, comments: Array[Dictionary]) -> void:
	for child in content.get_children():
		child.queue_free()

	var head := HBoxContainer.new()
	head.custom_minimum_size.y = 32
	content.add_child(head)

	var title := Label.new()
	title.text = current_shop.get("name", "")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#302c25"))
	head.add_child(title)

	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "关闭"
	close.custom_minimum_size = Vector2(34, 32)
	close.add_theme_font_size_override("font_size", 22)
	close.add_theme_color_override("font_color", Color("#302c25"))
	close.add_theme_color_override("font_hover_color", Color("#302c25"))
	close.add_theme_stylebox_override("normal", _style_box(Color("#f7efdf"), Color("#f7efdf"), 8, 0))
	close.add_theme_stylebox_override("hover", _style_box(Color("#eee2cb"), Color("#eee2cb"), 8, 0))
	close.add_theme_stylebox_override("pressed", _style_box(Color("#e5d7bc"), Color("#e5d7bc"), 8, 0))
	close.pressed.connect(_on_close_pressed)
	head.add_child(close)

	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 8)
	content.add_child(tags)
	for item in current_shop.get("items", []):
		var tag := Label.new()
		tag.text = item
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tag.custom_minimum_size = Vector2(78, 28)
		tag.add_theme_font_size_override("font_size", 13)
		tag.add_theme_color_override("font_color", Color("#302c25"))
		tag.add_theme_stylebox_override("normal", _style_box(Color("#f4ead6"), Color("#d4c4a7"), 8, 1))
		tags.add_child(tag)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	content.add_child(actions)

	favorite_button = Button.new()
	favorite_button.text = "★ 已收藏" if favorite else "☆ 收藏"
	favorite_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	favorite_button.custom_minimum_size.y = 40
	favorite_button.add_theme_color_override("font_color", Color("#302c25"))
	favorite_button.pressed.connect(_on_favorite_pressed)
	actions.add_child(favorite_button)

	blocked_button = Button.new()
	blocked_button.text = "取消拉黑" if blocked else "拉黑"
	blocked_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blocked_button.custom_minimum_size.y = 40
	blocked_button.add_theme_color_override("font_color", Color("#302c25"))
	blocked_button.pressed.connect(_on_blocked_pressed)
	actions.add_child(blocked_button)

	var comment_title := Label.new()
	comment_title.text = "留言"
	comment_title.add_theme_font_size_override("font_size", 15)
	comment_title.add_theme_color_override("font_color", Color("#302c25"))
	content.add_child(comment_title)

	comment_input = TextEdit.new()
	comment_input.placeholder_text = "写一句话…"
	comment_input.custom_minimum_size.y = 70
	comment_input.add_theme_font_size_override("font_size", 14)
	comment_input.add_theme_color_override("font_color", Color("#302c25"))
	comment_input.add_theme_color_override("font_placeholder_color", Color("#80745f"))
	comment_input.add_theme_stylebox_override("normal", _style_box(Color("#fffaf0"), Color("#eadfc8"), 9, 1))
	comment_input.add_theme_stylebox_override("focus", _style_box(Color("#fffdf7"), Color("#cbb996"), 9, 1))
	content.add_child(comment_input)

	var publish := Button.new()
	publish.text = "发布留言"
	publish.custom_minimum_size.y = 36
	publish.add_theme_color_override("font_color", Color("#302c25"))
	publish.pressed.connect(_on_publish_pressed)
	content.add_child(publish)

	comments_box = VBoxContainer.new()
	comments_box.add_theme_constant_override("separation", 6)
	content.add_child(comments_box)
	_render_comments(comments)

func _render_comments(comments: Array[Dictionary]) -> void:
	if comments.is_empty():
		var empty := Label.new()
		empty.text = "还没有留言"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color("#80745f"))
		comments_box.add_child(empty)
		return
	for comment in comments:
		var line := Label.new()
		line.text = "%s    %s" % [comment["date"], comment["text"]]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_theme_font_size_override("font_size", 13)
		line.add_theme_color_override("font_color", Color("#302c25"))
		line.add_theme_stylebox_override("normal", _style_box(Color("#f5eddd"), Color("#e4d7bd"), 8, 1))
		comments_box.add_child(line)

func _on_close_pressed() -> void:
	closed.emit()

func _on_favorite_pressed() -> void:
	favorite_requested.emit()

func _on_blocked_pressed() -> void:
	blocked_requested.emit()

func _on_publish_pressed() -> void:
	var text := comment_input.text.strip_edges()
	if not text.is_empty():
		comment_submitted.emit(text)

func _style_box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style
