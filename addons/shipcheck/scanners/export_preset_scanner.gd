@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name ExportPresetScanner


func get_scanner_id() -> String:
	return "export_preset"


func get_scanner_name() -> String:
	return "Export Preset Scanner"


func scan(_project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var settings := _get_shipcheck_config(context)
	var preset_path := "res://export_presets.cfg"

	if not FileAccess.file_exists(preset_path):
		if not settings.get_bool("export_presets", "require_export_presets", true):
			return issues
		issues.append(ShipCheckIssue.create(
			ShipCheckIssue.Severity.WARNING,
			"No Export Presets Found",
			"The project does not have an export_presets.cfg file.",
			preset_path,
			-1,
			"Create at least one export preset before preparing a release build.",
			get_scanner_name()
		))
		return issues

	var lines := _read_text_lines(preset_path)
	if lines.is_empty():
		issues.append(ShipCheckIssue.create(
			ShipCheckIssue.Severity.WARNING,
			"Empty Export Presets File",
			"export_presets.cfg exists but has no readable preset data.",
			preset_path,
			-1,
			"Open the Export window and confirm your export presets.",
			get_scanner_name()
		))
		return issues

	var preset_count := 0
	var current_section := ""
	var current_name := ""
	var current_export_path := ""
	var current_line := -1

	for i in range(lines.size()):
		var line := lines[i].strip_edges()
		if line.begins_with("[preset.") and not line.contains(".options"):
			if current_section != "":
				_append_missing_export_path_issue(issues, current_name, current_export_path, current_line, settings)
			preset_count += 1
			current_section = line
			current_name = "Preset %d" % preset_count
			current_export_path = ""
			current_line = i + 1
			continue

		if current_section == "":
			continue

		if line.begins_with("name="):
			current_name = _strip_cfg_value(line)
		elif line.begins_with("export_path="):
			current_export_path = _strip_cfg_value(line)

	if current_section != "":
		_append_missing_export_path_issue(issues, current_name, current_export_path, current_line, settings)

	if preset_count == 0:
		issues.append(ShipCheckIssue.create(
			ShipCheckIssue.Severity.WARNING,
			"No Export Presets Defined",
			"export_presets.cfg exists, but no preset sections were found.",
			preset_path,
			-1,
			"Open the Export window and create a platform preset.",
			get_scanner_name()
		))

	return issues


func _append_missing_export_path_issue(
	issues: Array[ShipCheckIssue],
	preset_name: String,
	export_path: String,
	line_number: int,
	settings: ShipCheckConfig
) -> void:
	if export_path != "" or not settings.get_bool("export_presets", "require_export_paths", true):
		return

	issues.append(ShipCheckIssue.create(
		ShipCheckIssue.Severity.WARNING,
		"Export Path Missing",
		"An export preset does not define an export path.",
		"res://export_presets.cfg",
		line_number,
		"Set an export path for '%s' so batch exports and release checks work reliably." % preset_name,
		get_scanner_name(),
		"Preset: %s" % preset_name
	))


func _strip_cfg_value(line: String) -> String:
	var parts := line.split("=", true, 1)
	if parts.size() < 2:
		return ""
	return parts[1].strip_edges().trim_prefix("\"").trim_suffix("\"")
