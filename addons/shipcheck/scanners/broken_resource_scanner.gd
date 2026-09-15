@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name BrokenResourceScanner


func get_scanner_id() -> String:
	return "broken_resource"


func get_scanner_name() -> String:
	return "Broken Resource Scanner"


func scan(project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var files := _get_files(project_root, PackedStringArray(["tscn", "tres", "theme", "gd", "gdshader"]), context)
	var actual_paths := _get_actual_path_map(project_root, context)
	var settings := _get_shipcheck_config(context)
	var seen := {}

	for file_path in files:
		var lines := _read_text_lines(file_path)
		for i in range(lines.size()):
			var line := lines[i]
			if _line_is_ignored(line):
				continue
			if file_path.get_extension().to_lower() == "gd" \
					and not settings.get_bool("broken_resource", "scan_pure_comments", false) \
					and _is_pure_comment_line(line):
				continue

			for referenced_path in _extract_res_paths(line):
				if _looks_dynamic_or_partial(referenced_path):
					continue
				if referenced_path.get_extension().to_lower() == "gd" and line.contains("type=\"Script\""):
					continue

				var key := "%s:%s:%d" % [file_path, referenced_path, i + 1]
				if seen.has(key):
					continue
				seen[key] = true

				if not _resource_or_file_exists(referenced_path):
					if _exists_with_different_casing(referenced_path, actual_paths):
						continue

					issues.append(ShipCheckIssue.create(
						ShipCheckIssue.Severity.ERROR,
						"Broken Resource Reference",
						"A referenced project resource could not be found.",
						file_path,
						i + 1,
						"Restore the file, update the reference, or remove the object that uses it.",
						get_scanner_name(),
						"Missing: %s" % referenced_path
					))

	return issues


func _exists_with_different_casing(path: String, actual_paths: Dictionary) -> bool:
	var key := path.to_lower()
	return actual_paths.has(key) and actual_paths[key] != path
