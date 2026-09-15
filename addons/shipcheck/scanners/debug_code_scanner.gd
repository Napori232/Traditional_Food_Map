@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name DebugCodeScanner

const PATTERNS := [
	{"id": "print", "needle": "print(", "title": "Debug Print Found", "hint": "Remove the print call or add '# shipcheck: ignore' if it is intentional.", "allow_comments": false},
	{"id": "prints", "needle": "prints(", "title": "Debug Prints Found", "hint": "Remove the prints call or add '# shipcheck: ignore' if it is intentional.", "allow_comments": false},
	{"id": "printerr", "needle": "printerr(", "title": "Debug Error Print Found", "hint": "Confirm this output is wanted in release builds.", "allow_comments": false},
	{"id": "push_warning", "needle": "push_warning(", "title": "Warning Push Found", "hint": "Confirm this warning is wanted in release builds.", "allow_comments": false},
	{"id": "push_error", "needle": "push_error(", "title": "Error Push Found", "hint": "Confirm this error output is wanted in release builds.", "allow_comments": false},
	{"id": "assert", "needle": "assert(", "title": "Assert Found", "hint": "Confirm this assertion is safe for your release target.", "allow_comments": false},
	{"id": "breakpoint", "needle": "breakpoint", "title": "Breakpoint Found", "hint": "Remove breakpoints before shipping.", "allow_comments": false},
	{"id": "todo", "needle": "TODO", "title": "TODO Found", "hint": "Review TODO notes before shipping.", "allow_comments": true},
	{"id": "fixme", "needle": "FIXME", "title": "FIXME Found", "hint": "Review FIXME notes before shipping.", "allow_comments": true}
]


func get_scanner_id() -> String:
	return "debug_code"


func get_scanner_name() -> String:
	return "Debug Code Scanner"


func scan(project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var settings := _get_shipcheck_config(context)
	var files := _get_files(project_root, PackedStringArray(["gd"]), context)

	for file_path in files:
		var lines := _read_text_lines(file_path)
		for i in range(lines.size()):
			var line := lines[i]
			var trimmed := line.strip_edges()
			if _line_is_ignored(line):
				continue

			for pattern in PATTERNS:
				if trimmed.begins_with("#") and not bool(pattern.get("allow_comments", false)):
					continue

				var rule_id: String = pattern["id"]
				if not settings.is_debug_rule_enabled(rule_id):
					continue

				var needle: String = pattern["needle"]
				if not line.contains(needle):
					continue

				issues.append(ShipCheckIssue.create(
					settings.get_debug_rule_severity(rule_id),
					pattern["title"],
					"This line contains a debug or unfinished-code marker.",
					file_path,
					i + 1,
					pattern["hint"],
					get_scanner_name(),
					"Found: %s" % trimmed
				))

	return issues
