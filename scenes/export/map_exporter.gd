extends Node

const MAP_SCENE := preload("res://scenes/map/hangzhou_map.tscn")
const EXPORT_SIZE := Vector2i(1600, 1100)

## Renders the paper map with only favorite and blocked shops and saves a PNG.
func ExportFavoriteMap(food_data: Node, output_path: String = "user://traditional_food_map.png") -> String:
	var viewport := SubViewport.new()
	viewport.size = EXPORT_SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	viewport.disable_3d = true
	add_child(viewport)

	var map := MAP_SCENE.instantiate()
	viewport.add_child(map)
	map.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map.SetShops(food_data.GetShopsFiltered("全部", ""))
	map.SetFavoriteIds(food_data.GetFavoriteIds())
	map.SetBlockedIds(food_data.GetBlockedIds())
	map.SetSearchMode(false)

	await get_tree().process_frame
	await get_tree().process_frame
	var texture: ViewportTexture = viewport.get_texture()
	if texture == null:
		viewport.queue_free()
		return ""
	var image := texture.get_image()
	if image == null:
		viewport.queue_free()
		return ""
	var error := image.save_png(output_path)
	viewport.queue_free()
	if error != OK:
		return ""
	return output_path
