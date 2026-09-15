@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name InputMapScanner

const INPUT_METHODS := [
	"is_action_pressed",
	"is_action_just_pressed",
	"is_action_just_released",
	"is_action_released",
	"is_action",
	"get_action_strength",
	"action_get_deadzone",
	"get_axis",
	"get_vector"
]


func get_scanner_id() -> String:
	return "input_map"


func get_scanner_name() -> String:
	return "InputMap Scanner"


func scan(project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var settings := _get_shipcheck_config(context)
	var defined_actions := _get_defined_input_actions()
	var used_actions := {}
	var files := _get_files(project_root, PackedStringArray(["gd"]), context)
	var string_constants := _collect_string_constants(files)

	for file_path in files:
		var lines := _read_text_lines(file_path)
		for i in range(lines.size()):
			var line := lines[i]
			if _line_is_ignored(line):
				continue

			if not _contains_input_method(line):
				continue

			var actions := _extract_input_actions_from_line(line, string_constants)
			if actions.is_empty():
				continue

			for action in actions:
				used_actions[action] = true
				if settings.get_bool("input_map", "report_undefined_actions", true) and not defined_actions.has(action):
					issues.append(ShipCheckIssue.create(
						ShipCheckIssue.Severity.ERROR,
						"Input Action Used But Not Defined",
						"A script uses an InputMap action that is not defined in Project Settings.",
						file_path,
						i + 1,
						"Add '%s' to Project Settings > Input Map or fix the action name in code." % action,
						get_scanner_name(),
						"Action: %s" % action
					))

	for action in defined_actions:
		if not settings.get_bool("input_map", "report_unused_actions", true):
			break
		if settings.get_bool("input_map", "ignore_ui_actions", true) and action.begins_with("ui_"):
			continue
		if not used_actions.has(action):
			issues.append(ShipCheckIssue.create(
				ShipCheckIssue.Severity.INFO,
				"Input Action Defined But Not Found In Code",
				"An InputMap action is defined but ShipCheck did not find direct code usage.",
				"project.godot",
				-1,
				"Remove unused actions or ignore this if the action is used dynamically.",
				get_scanner_name(),
				"Action: %s" % action
			))

	return issues


func _contains_input_method(line: String) -> bool:
	for method in INPUT_METHODS:
		if line.contains("Input.%s(" % method) or line.contains(".%s(" % method):
			return true
	return false


func _extract_input_actions_from_line(line: String, string_constants: Dictionary) -> PackedStringArray:
	var actions := _extract_quoted_strings(line)
	for identifier in _extract_input_call_identifiers(line):
		if string_constants.has(identifier):
			var action: String = string_constants[identifier]
			if action != "" and not actions.has(action):
				actions.append(action)
	return actions


func _collect_string_constants(files: PackedStringArray) -> Dictionary:
	var constants := {}
	var regex := RegEx.new()
	regex.compile("\\b(?:const|var)\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*(?::=|=)\\s*[\\\"']([^\\\"']+)[\\\"']")

	for file_path in files:
		var lines := _read_text_lines(file_path)
		for line in lines:
			if _line_is_ignored(line):
				continue
			var result := regex.search(line)
			if result == null:
				continue
			constants[result.get_string(1)] = result.get_string(2)

	return constants


func _extract_input_call_identifiers(line: String) -> PackedStringArray:
	var identifiers := PackedStringArray()
	var regex := RegEx.new()
	regex.compile("(?:Input|[A-Za-z_][A-Za-z0-9_]*)\\s*\\.\\s*(?:%s)\\s*\\(([^\\)]*)\\)" % "|".join(INPUT_METHODS))
	for result in regex.search_all(line):
		var args := result.get_string(1).split(",", false)
		for raw_arg in args:
			var arg := raw_arg.strip_edges()
			if _is_identifier(arg) and not identifiers.has(arg):
				identifiers.append(arg)
	return identifiers


func _is_identifier(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[A-Za-z_][A-Za-z0-9_]*$")
	return regex.search(value) != null


func _extract_quoted_strings(line: String) -> PackedStringArray:
	var values := PackedStringArray()
	var regex := RegEx.new()
	regex.compile("[\\\"']([^\\\"']+)[\\\"']")
	for result in regex.search_all(line):
		var value := result.get_string(1)
		if value != "" and not values.has(value):
			values.append(value)
	return values
