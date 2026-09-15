extends Control

const FOOD_DATA_PATH := "/root/FoodData"

@onready var map: Control = $HangzhouMap
@onready var category_filter: Control = $UILayer/CategoryFilter
@onready var search_box: Control = $UILayer/SearchBox
@onready var export_button: Button = $UILayer/ExportButton
@onready var shop_detail: Control = $UILayer/ShopDetail
@onready var toast: Control = $UILayer/Toast
@onready var map_exporter: Node = $MapExporter

var food_data: Node
var selected_shop_id := ""
var active_category := "全部"
var active_query := ""

func _ready() -> void:
	food_data = get_node(FOOD_DATA_PATH)
	category_filter.SetCategories(food_data.GetCategories())
	category_filter.category_selected.connect(_on_category_selected)
	search_box.query_changed.connect(_on_query_changed)
	export_button.export_requested.connect(_on_export_requested)
	map.shop_selected.connect(_on_shop_selected)
	shop_detail.closed.connect(_close_detail)
	shop_detail.favorite_requested.connect(_toggle_favorite)
	shop_detail.blocked_requested.connect(_toggle_blocked)
	shop_detail.comment_submitted.connect(_submit_comment)
	food_data.state_changed.connect(_on_data_state_changed)
	_refresh_map()
	_layout_interface()
	resized.connect(_layout_interface)

## Refreshes scene markers from the data layer using current UI filters.
func RefreshMap() -> void:
	_refresh_map()

func _refresh_map() -> void:
	var visible_shops: Array[Dictionary] = food_data.GetShopsFiltered(active_category, active_query)
	map.SetShops(visible_shops)
	map.SetSearchMode(not active_query.strip_edges().is_empty())
	map.SetFavoriteIds(food_data.GetFavoriteIds())
	map.SetBlockedIds(food_data.GetBlockedIds())

func _on_category_selected(category: String) -> void:
	active_category = category
	_refresh_map()

func _on_query_changed(query: String) -> void:
	active_query = query
	_refresh_map()

func _on_shop_selected(shop_id: String) -> void:
	selected_shop_id = shop_id
	var shop: Dictionary = food_data.GetShopById(shop_id)
	shop_detail.ShowShop(shop, food_data.IsFavorite(shop_id), food_data.IsBlocked(shop_id), food_data.GetComments(shop_id))
	_layout_interface()

func _toggle_favorite() -> void:
	if selected_shop_id.is_empty():
		return
	food_data.ToggleFavorite(selected_shop_id)
	_refresh_detail()

func _toggle_blocked() -> void:
	if selected_shop_id.is_empty():
		return
	food_data.ToggleBlocked(selected_shop_id)
	_refresh_detail()

func _submit_comment(text: String) -> void:
	if selected_shop_id.is_empty():
		return
	food_data.AddComment(selected_shop_id, text)
	_refresh_detail()

func _on_export_requested() -> void:
	var output_path: String = await map_exporter.ExportFavoriteMap(food_data)
	if output_path.is_empty():
		_show_toast("导出失败")
	else:
		_show_toast("已导出 PNG")

func _show_toast(message: String) -> void:
	toast.text = message
	toast.visible = true
	await get_tree().create_timer(2.0).timeout
	toast.visible = false

func _refresh_detail() -> void:
	if selected_shop_id.is_empty():
		return
	var shop: Dictionary = food_data.GetShopById(selected_shop_id)
	shop_detail.ShowShop(shop, food_data.IsFavorite(selected_shop_id), food_data.IsBlocked(selected_shop_id), food_data.GetComments(selected_shop_id))

func _on_data_state_changed(shop_id: String) -> void:
	_refresh_map()
	if shop_id == selected_shop_id:
		_refresh_detail()

func _close_detail() -> void:
	selected_shop_id = ""
	shop_detail.Clear()
	_layout_interface()

func _layout_interface() -> void:
	if not is_node_ready():
		return
	var width := size.x
	var height := size.y
	if width >= 620.0:
		category_filter.position = Vector2(14, 14)
		category_filter.size = Vector2(minf(maxf(220.0, width - 28.0), 490.0), 50)
		search_box.position = Vector2(width - 268.0, 14)
		search_box.size = Vector2(254, 50)
		export_button.position = Vector2(width - 58.0, 72)
	else:
		category_filter.position = Vector2(14, 14)
		category_filter.size = Vector2(maxf(0.0, width - 28.0), 50)
		search_box.position = Vector2(14, 72)
		search_box.size = Vector2(maxf(0.0, width - 28.0), 50)
		export_button.position = Vector2(width - 58.0, 132)
	export_button.size = Vector2(44, 44)
	if shop_detail.visible:
		if width >= 820.0:
			shop_detail.position = Vector2(width - 382, 14)
			shop_detail.size = Vector2(368, height - 28)
		else:
			var panel_height := minf(390.0, maxf(240.0, height - 28))
			shop_detail.position = Vector2(14, height - panel_height - 14)
			shop_detail.size = Vector2(maxf(0.0, width - 28), panel_height)
	toast.position = Vector2(width * 0.5 - 90, height - 58)
	toast.size = Vector2(180, 34)
