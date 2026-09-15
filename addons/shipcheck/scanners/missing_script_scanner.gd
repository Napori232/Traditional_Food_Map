@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name MissingScriptScanner


func get_scanner_id() -> String:
	return "missing_script"


func get_scanner_name() -> String:
	return "Missing Script Scanner"


func scan(project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var files := _get_files(project_root, PackedStringArray(["tscn", "tres"]), context)
	var seen := {}

	for file_path in files:
		var lines := _read_text_lines(file_path)
		for i in range(lines.size()):
			var line := lines[i]
			if _line_is_ignored(line):
				continue
			if not line.contains("path=\"res://"):
				continue
			if not line.contains("type=\"Script\"") and not line.contains(".gd"):
				continue

			for path in _extract_res_paths(line):
				if path.get_extension().to_lower() != "gd":
					continue

				var key := "%s:%s:%d" % [file_path, path, i + 1]
				if seen.has(key):
					continue
				seen[key] = true

				if not FileAccess.file_exists(path):
					issues.append(ShipCheckIssue.create(
						ShipCheckIssue.Severity.ERROR,
						"Missing Script Reference",
						"This scene or resource references a script file that does not exist.",
						file_path,
						i + 1,
						"Restore the script, update the reference, or remove the script from the scene/resource.",
						get_scanner_name(),
						"Missing: %s" % path
					))

	return issues
