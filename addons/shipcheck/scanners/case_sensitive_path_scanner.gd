@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name CaseSensitivePathScanner


func get_scanner_id() -> String:
	return "case_sensitive_path"


func get_scanner_name() -> String:
	return "Case-Sensitive Path Scanner"


func scan(project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var actual_paths := _get_actual_path_map(project_root, context)
	var files := _get_files(project_root, PackedStringArray(["tscn", "tres", "theme", "gd", "gdshader"]), context)

	for file_path in files:
		var lines := _read_text_lines(file_path)
		for i in range(lines.size()):
			var line := lines[i]
			if _line_is_ignored(line):
				continue

			for referenced_path in _extract_res_paths(line):
				if _looks_dynamic_or_partial(referenced_path):
					continue

				var key := referenced_path.to_lower()
				if not actual_paths.has(key):
					continue

				var actual_path: String = actual_paths[key]
				if actual_path != referenced_path:
					issues.append(ShipCheckIssue.create(
						ShipCheckIssue.Severity.ERROR,
						"Path Casing Mismatch",
						"A referenced resource path uses different casing than the actual file.",
						file_path,
						i + 1,
						"Update the reference casing exactly. This can break Linux, web, and some exported builds.",
						get_scanner_name(),
						"Referenced: %s\nActual: %s" % [referenced_path, actual_path]
					))

	return issues
