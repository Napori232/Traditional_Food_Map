extends Node

signal state_changed(shop_id: String)

const APP_GLOBAL := preload("res://global/app_global.gd")

var _shops: Array[Dictionary] = [
	{"id": "lou_wai_lou", "name": "楼外楼", "category": APP_GLOBAL.CATEGORY_MAIN, "items": ["杭帮菜", "西湖醋鱼"], "position": Vector2(355, 190)},
	{"id": "zhi_wei_zhuang", "name": "知味观·味庄", "category": APP_GLOBAL.CATEGORY_MAIN, "items": ["杭帮菜", "小笼"], "position": Vector2(560, 305)},
	{"id": "green_tea", "name": "绿茶餐厅", "category": APP_GLOBAL.CATEGORY_MAIN, "items": ["创意菜", "烤鱼"], "position": Vector2(790, 250)},
	{"id": "xin_feng", "name": "新丰小吃", "category": APP_GLOBAL.CATEGORY_SNACK, "items": ["小笼", "拌川"], "position": Vector2(675, 410)},
	{"id": "fang_lao_da", "name": "方老大面", "category": APP_GLOBAL.CATEGORY_SNACK, "items": ["片儿川", "拌面"], "position": Vector2(420, 560)},
	{"id": "wu_shan", "name": "吴山烤禽", "category": APP_GLOBAL.CATEGORY_SNACK, "items": ["烤禽", "卤味"], "position": Vector2(660, 600)},
	{"id": "florest", "name": "浮力森林", "category": APP_GLOBAL.CATEGORY_DESSERT, "items": ["蛋糕", "面包"], "position": Vector2(860, 180)},
	{"id": "west_lake_roufen", "name": "西湖藕粉铺", "category": APP_GLOBAL.CATEGORY_DESSERT, "items": ["藕粉", "糕点"], "position": Vector2(240, 500)},
	{"id": "holiland", "name": "好利来", "category": APP_GLOBAL.CATEGORY_DESSERT, "items": ["蛋糕", "甜点"], "position": Vector2(980, 330)},
	{"id": "heytea", "name": "喜茶", "category": APP_GLOBAL.CATEGORY_DRINK, "items": ["芝芝莓莓", "纯茶"], "position": Vector2(910, 470)},
	{"id": "chabaidao", "name": "茶百道", "category": APP_GLOBAL.CATEGORY_DRINK, "items": ["水果茶", "奶茶"], "position": Vector2(770, 570)},
	{"id": "guming", "name": "古茗", "category": APP_GLOBAL.CATEGORY_DRINK, "items": ["鲜奶茶", "果茶"], "position": Vector2(1080, 575)}
]

var _favorites: Dictionary = {}
var _blocked: Dictionary = {}
var _comments: Dictionary = {}

## Returns all category identifiers exposed by the food directory.
func GetCategories() -> Array[String]:
	return ["全部", APP_GLOBAL.CATEGORY_MAIN, APP_GLOBAL.CATEGORY_SNACK, APP_GLOBAL.CATEGORY_DESSERT, APP_GLOBAL.CATEGORY_DRINK]

## Returns shop records filtered by category and search text.
func GetShopsFiltered(category: String, query: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var normalized_query := query.strip_edges().to_lower()
	for source_shop in _shops:
		if category != "全部" and source_shop["category"] != category:
			continue
		if not normalized_query.is_empty() and not _shop_matches_query(source_shop, normalized_query):
			continue
		result.append(source_shop.duplicate(true))
	return result

## Finds one shop record by its stable identifier.
func GetShopById(shop_id: String) -> Dictionary:
	for shop in _shops:
		if shop["id"] == shop_id:
			return shop.duplicate(true)
	return {}

## Returns the current favorite state for one shop.
func IsFavorite(shop_id: String) -> bool:
	return _favorites.has(shop_id)

## Toggles a shop favorite and removes its id when unfavorited.
func ToggleFavorite(shop_id: String) -> bool:
	if _favorites.has(shop_id):
		_favorites.erase(shop_id)
	else:
		_favorites[shop_id] = true
	state_changed.emit(shop_id)
	return _favorites.has(shop_id)

## Returns the current blocked state for one shop.
func IsBlocked(shop_id: String) -> bool:
	return _blocked.has(shop_id)

## Toggles the blocked state for one shop.
func ToggleBlocked(shop_id: String) -> bool:
	if _blocked.has(shop_id):
		_blocked.erase(shop_id)
	else:
		_blocked[shop_id] = true
	state_changed.emit(shop_id)
	return _blocked.has(shop_id)

## Returns a copy of favorite shop identifiers for scene rendering.
func GetFavoriteIds() -> Dictionary:
	return _favorites.duplicate()

## Returns a copy of blocked shop identifiers for scene rendering.
func GetBlockedIds() -> Dictionary:
	return _blocked.duplicate()

## Adds a dated comment to a shop and returns the stored comment.
func AddComment(shop_id: String, text: String) -> Dictionary:
	var comment := {
		"date": Time.get_date_string_from_system(),
		"text": text.strip_edges()
	}
	var comments: Array = _comments.get(shop_id, [])
	comments.append(comment)
	_comments[shop_id] = comments
	state_changed.emit(shop_id)
	return comment

## Returns dated comments belonging to one shop.
func GetComments(shop_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for comment in _comments.get(shop_id, []):
		result.append(comment.duplicate(true))
	return result

func _shop_matches_query(shop: Dictionary, query: String) -> bool:
	var searchable := "%s %s %s" % [shop["name"], shop["category"], " ".join(shop["items"])]
	return query in searchable.to_lower()
