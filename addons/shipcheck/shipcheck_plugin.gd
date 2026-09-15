@tool
extends EditorPlugin

const ShipCheckDock := preload("res://addons/shipcheck/ui/shipcheck_dock.gd")

var dock: Control


func _enter_tree() -> void:
	dock = ShipCheckDock.new()
	dock.name = "ShipCheck"
	if dock.has_method("set_editor_interface"):
		dock.set_editor_interface(get_editor_interface())
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)


func _exit_tree() -> void:
	if dock != null:
		remove_control_from_docks(dock)
		dock.queue_free()
		dock = null

