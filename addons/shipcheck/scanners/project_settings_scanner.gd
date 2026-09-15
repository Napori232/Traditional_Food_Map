@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name ProjectSettingsScanner


func get_scanner_id() -> String:
	return "project_settings"


func get_scanner_name() -> String:
	return "Project Settings Scanner"


func scan(_project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var settings := _get_shipcheck_config(context)

	var project_name := str(ProjectSettings.get_setting("application/config/name", ""))
	if project_name.strip_edges() == "":
		issues.append(ShipCheckIssue.create(
			settings.get_severity("project_settings", "project_name_missing_severity", ShipCheckIssue.Severity.INFO),
			"Project Name Missing",
			"The project does not define application/config/name.",
			"project.godot",
			-1,
			"Set a project name in Project Settings > Application > Config.",
			get_scanner_name()
		))

	if settings.get_bool("project_settings", "require_main_scene", true):
		var main_scene := str(ProjectSettings.get_setting("application/run/main_scene", ""))
		if main_scene.strip_edges() == "":
			issues.append(ShipCheckIssue.create(
				settings.get_severity("project_settings", "no_main_scene_severity", ShipCheckIssue.Severity.WARNING),
				"No Main Scene Set",
				"The project does not define application/run/main_scene.",
				"project.godot",
				-1,
				"Set a main scene in Project Settings > Application > Run.",
				get_scanner_name()
			))
		elif not ResourceLoader.exists(main_scene):
			issues.append(ShipCheckIssue.create(
				settings.get_severity("project_settings", "main_scene_missing_severity", ShipCheckIssue.Severity.CRITICAL),
				"Main Scene Missing",
				"The configured main scene could not be found.",
				"project.godot",
				-1,
				"Restore the main scene or update application/run/main_scene.",
				get_scanner_name(),
				"Main scene: %s" % main_scene
			))

	if settings.get_bool("project_settings", "check_project_icon", true):
		var icon_path := str(ProjectSettings.get_setting("application/config/icon", ""))
		if icon_path != "" and not ResourceLoader.exists(icon_path) and not FileAccess.file_exists(icon_path):
			issues.append(ShipCheckIssue.create(
				settings.get_severity("project_settings", "project_icon_missing_severity", ShipCheckIssue.Severity.WARNING),
				"Project Icon Missing",
				"The configured project icon could not be found.",
				"project.godot",
				-1,
				"Restore the icon file or update application/config/icon.",
				get_scanner_name(),
				"Icon: %s" % icon_path
			))

	if settings.get_bool("project_settings", "check_autoloads", true):
		issues.append_array(_scan_autoloads(settings))
	return issues


func _scan_autoloads(settings: ShipCheckConfig) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	for property in ProjectSettings.get_property_list():
		var name := str(property.get("name", ""))
		if not name.begins_with("autoload/"):
			continue

		var autoload_name := name.trim_prefix("autoload/")
		var raw_value := str(ProjectSettings.get_setting(name, ""))
		var path := raw_value.trim_prefix("*")
		if path == "":
			continue

		if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
			issues.append(ShipCheckIssue.create(
				settings.get_severity("project_settings", "autoload_missing_severity", ShipCheckIssue.Severity.CRITICAL),
				"Autoload Path Missing",
				"An autoload points to a script or scene that could not be found.",
				"project.godot",
				-1,
				"Restore the autoload target or update Project Settings > Globals > Autoload.",
				get_scanner_name(),
				"%s -> %s" % [autoload_name, path]
			))

	return issues
