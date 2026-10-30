extends Control

var world_size := Vector2(1600.0, 1100.0)
var view_size := Vector2.ZERO
var map_zoom := 1.0
var map_pan := Vector2.ZERO

## Assigns the shared map data source used by this visual layer.
func SetMapData(value: Node) -> void:
	set_meta("map_data", value)
	queue_redraw()

## Updates the viewport transform shared by all map visual layers.
func SetView(view_size: Vector2, value_world_size: Vector2, value_zoom: float, value_pan: Vector2) -> void:
	self.view_size = view_size
	world_size = value_world_size
	map_zoom = value_zoom
	map_pan = value_pan
	queue_redraw()

func _world_to_screen(world_position: Vector2) -> Vector2:
	return view_size * 0.5 + (world_position - world_size * 0.5 + map_pan) * _map_scale()

func _map_scale() -> float:
	return minf(view_size.x / world_size.x, view_size.y / world_size.y) * 0.94 * map_zoom

func _map_data() -> Node:
	return get_meta("map_data", null)
