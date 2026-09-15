@tool
extends RefCounted
class_name ShipCheckIgnore

const CONFIG_PATH := "res://shipcheck_ignore.cfg"
const DEFAULT_IGNORED_PATHS := [
	"res://.godot/",
	"res://shipcheck_report.md",
	"res://shipcheck_report.html",
	"res://shipcheck_report.json",
	"res://shipcheck_baseline.cfg",
	"res://shipcheck_ignore.cfg",
	"res://shipcheck_config.cfg"
]

var ignored_paths: PackedStringArray = PackedStringArray()
var ignored_issue_ids: PackedStringArray = PackedStringArray()
var ignored_scanners: PackedStringArray = PackedStringArray()
var include_addons: bool = false


static func load_from_project(p_include_addons: bool = false) -> ShipCheckIgnore:
	var rules := ShipCheckIgnore.new()
	rules.include_addons = p_include_addons
	rules.ignored_paths = rules._get_default_ignored_paths()
	if not FileAccess.file_exists(CONFIG_PATH):
		return rules

	var config := ConfigFile.new()
	var error := config.load(CONFIG_PATH)
	if error != OK:
		return rules

	if config.has_section_key("paths", "ignore"):
		rules.ignored_paths = rules._to_packed_string_array(config.get_value("paths", "ignore", []))
	rules.ignored_issue_ids = rules._to_packed_string_array(config.get_value("issues", "ignore_ids", []))
	rules.ignored_scanners = rules._to_packed_string_array(config.get_value("scanners", "ignore", []))
	return rules


func is_issue_ignored(issue: ShipCheckIssue) -> bool:
	if ignored_issue_ids.has(issue.get_issue_id()):
		return true
	if ignored_issue_ids.has(issue.get_legacy_issue_id()):
		return true

	if ignored_scanners.has(issue.scanner_name) or ignored_scanners.has(issue.scanner_id):
		return true

	for pattern in ignored_paths:
		if _path_matches(issue.file_path, pattern):
			return true

	if _is_issue_ignored_by_directive(issue):
		return true

	return false


func add_issue_ignore(issue: ShipCheckIssue) -> Error:
	var config := ConfigFile.new()
	if FileAccess.file_exists(CONFIG_PATH):
		var load_error := config.load(CONFIG_PATH)
		if load_error != OK:
			return load_error

	_ensure_default_sections(config)
	var ids := _to_packed_string_array(config.get_value("issues", "ignore_ids", []))
	var issue_id := issue.get_issue_id()
	if not ids.has(issue_id):
		ids.append(issue_id)

	var paths := _to_packed_string_array(config.get_value("paths", "ignore", []))
	var scanners := _to_packed_string_array(config.get_value("scanners", "ignore", []))
	var save_error := _save_pretty(paths, scanners, ids)
	if save_error == OK:
		ignored_issue_ids = ids
	return save_error


func add_path_ignore(path: String) -> Error:
	var config := ConfigFile.new()
	if FileAccess.file_exists(CONFIG_PATH):
		var load_error := config.load(CONFIG_PATH)
		if load_error != OK:
			return load_error

	_ensure_default_sections(config)
	var paths := _to_packed_string_array(config.get_value("paths", "ignore", []))
	if path != "" and not paths.has(path):
		paths.append(path)

	var scanners := _to_packed_string_array(config.get_value("scanners", "ignore", []))
	var ids := _to_packed_string_array(config.get_value("issues", "ignore_ids", []))
	var save_error := _save_pretty(paths, scanners, ids)
	if save_error == OK:
		ignored_paths = paths
	return save_error


func add_scanner_ignore(scanner: String) -> Error:
	var config := ConfigFile.new()
	if FileAccess.file_exists(CONFIG_PATH):
		var load_error := config.load(CONFIG_PATH)
		if load_error != OK:
			return load_error

	_ensure_default_sections(config)
	var scanners := _to_packed_string_array(config.get_value("scanners", "ignore", []))
	if scanner != "" and not scanners.has(scanner):
		scanners.append(scanner)

	var paths := _to_packed_string_array(config.get_value("paths", "ignore", []))
	var ids := _to_packed_string_array(config.get_value("issues", "ignore_ids", []))
	var save_error := _save_pretty(paths, scanners, ids)
	if save_error == OK:
		ignored_scanners = scanners
	return save_error


func ensure_config_exists() -> Error:
	var config := ConfigFile.new()
	if FileAccess.file_exists(CONFIG_PATH):
		var load_error := config.load(CONFIG_PATH)
		if load_error != OK:
			return load_error

	_ensure_default_sections(config)
	var paths := _to_packed_string_array(config.get_value("paths", "ignore", []))
	var scanners := _to_packed_string_array(config.get_value("scanners", "ignore", []))
	var ids := _to_packed_string_array(config.get_value("issues", "ignore_ids", []))
	return _save_pretty(paths, scanners, ids)


func _ensure_default_sections(config: ConfigFile) -> void:
	if not config.has_section_key("paths", "ignore"):
		config.set_value("paths", "ignore", _to_array(_get_default_ignored_paths()))
	if not config.has_section_key("scanners", "ignore"):
		config.set_value("scanners", "ignore", [])
	if not config.has_section_key("issues", "ignore_ids"):
		config.set_value("issues", "ignore_ids", [])


func _ensure_help_text(config: ConfigFile) -> void:
	config.set_value("help", "paths", "Use exact paths, folder prefixes ending in '/', or simple wildcards like res://art/source/*")
	config.set_value("help", "scanners", "Use scanner display names, for example Debug Code Scanner")
	config.set_value("help", "inline", "Add '# shipcheck: ignore' to a code/resource line to ignore that line.")


func _save_pretty(paths: PackedStringArray, scanners: PackedStringArray, issue_ids: PackedStringArray) -> Error:
	paths.sort()
	scanners.sort()
	issue_ids.sort()

	var lines: Array[String] = []
	lines.append("; ShipCheck ignore rules")
	lines.append("; Paths support exact paths, folder prefixes ending in '/', or wildcards like res://art/source/*")
	lines.append("; Scanner ignores use display names, for example: Debug Code Scanner")
	lines.append("; Inline ignores: add '# shipcheck: ignore' to a specific code/resource line.")
	lines.append("; ShipCheck also supports ignore-line, ignore-next-line, ignore-file, ignore-start, and ignore-end directives.")
	lines.append("")
	lines.append("[paths]")
	lines.append("")
	lines.append("ignore=%s" % _format_string_array(paths))
	lines.append("")
	lines.append("[scanners]")
	lines.append("")
	lines.append("ignore=%s" % _format_string_array(scanners))
	lines.append("")
	lines.append("[issues]")
	lines.append("")
	lines.append("ignore_ids=%s" % _format_string_array(issue_ids))
	lines.append("")

	var file := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		return ERR_CANT_CREATE

	file.store_string("\n".join(lines))
	file.close()
	return OK


func _format_string_array(values: PackedStringArray) -> String:
	if values.is_empty():
		return "[]"

	var lines: Array[String] = ["["]
	for i in range(values.size()):
		var suffix := "," if i < values.size() - 1 else ""
		lines.append("\t\"%s\"%s" % [_escape_cfg_string(values[i]), suffix])
	lines.append("]")
	return "\n".join(lines)


func _escape_cfg_string(value: String) -> String:
	return value.replace("\\", "\\\\").replace("\"", "\\\"")


func _to_packed_string_array(value) -> PackedStringArray:
	var result := PackedStringArray()
	if value is PackedStringArray:
		return value
	if value is Array:
		for item in value:
			result.append(str(item))
	elif value is String and value != "":
		result.append(value)
	return result


func _get_default_ignored_paths() -> PackedStringArray:
	var result := PackedStringArray()
	if not include_addons:
		result.append("res://addons/")
	for path in DEFAULT_IGNORED_PATHS:
		result.append(path)
	return result


func _merge_string_arrays(base: PackedStringArray, extra: PackedStringArray) -> PackedStringArray:
	var result := PackedStringArray()
	for value in base:
		if value != "" and not result.has(value):
			result.append(value)
	for value in extra:
		if value != "" and not result.has(value):
			result.append(value)
	return result


func _path_matches(path: String, pattern: String) -> bool:
	if pattern == "":
		return false

	if pattern.contains("*"):
		var regex := RegEx.new()
		regex.compile("^%s$" % _wildcard_to_regex(pattern))
		return regex.search(path) != null

	if pattern.ends_with("/"):
		return path.begins_with(pattern)

	return path == pattern or path.begins_with(pattern.trim_suffix("/") + "/")


func _is_issue_ignored_by_directive(issue: ShipCheckIssue) -> bool:
	if issue.file_path.get_extension().to_lower() != "gd" or issue.line_number <= 0:
		return false
	if not FileAccess.file_exists(issue.file_path):
		return false

	var file := FileAccess.open(issue.file_path, FileAccess.READ)
	if file == null:
		return false

	var lines := file.get_as_text().replace("\r\n", "\n").replace("\r", "\n").split("\n", true)
	var target_index := issue.line_number - 1
	if target_index < 0 or target_index >= lines.size():
		return false

	if _line_has_matching_directive(lines[target_index], "ignore", issue):
		return true
	if _line_has_matching_directive(lines[target_index], "ignore-line", issue):
		return true
	if target_index > 0 and _line_has_matching_directive(lines[target_index - 1], "ignore-next-line", issue):
		return true

	var active_tokens: PackedStringArray = PackedStringArray()
	for i in range(0, target_index + 1):
		var start_tokens := _get_directive_tokens(lines[i], "ignore-start")
		for token in start_tokens:
			if not active_tokens.has(token):
				active_tokens.append(token)

		if i == target_index:
			for token in active_tokens:
				if _directive_token_matches(token, issue):
					return true

		var end_tokens := _get_directive_tokens(lines[i], "ignore-end")
		for token in end_tokens:
			if active_tokens.has(token):
				active_tokens.remove_at(active_tokens.find(token))

	for line in lines:
		if _line_has_matching_directive(line, "ignore-file", issue):
			return true

	return false


func _line_has_matching_directive(line: String, directive: String, issue: ShipCheckIssue) -> bool:
	for token in _get_directive_tokens(line, directive):
		if _directive_token_matches(token, issue):
			return true
	return false


func _get_directive_tokens(line: String, directive: String) -> PackedStringArray:
	var tokens := PackedStringArray()
	var marker := "shipcheck:"
	var index := line.find(marker)
	if index < 0:
		return tokens

	var payload := line.substr(index + marker.length()).strip_edges()
	if payload == "":
		return tokens

	var parts := payload.split(" ", false)
	if parts.is_empty():
		return tokens
	if parts[0] != directive:
		return tokens

	if parts.size() == 1:
		tokens.append("")
	else:
		for i in range(1, parts.size()):
			var token := parts[i].strip_edges().trim_suffix(",")
			if token != "":
				tokens.append(token)
	return tokens


func _directive_token_matches(token: String, issue: ShipCheckIssue) -> bool:
	if token == "":
		return true
	return token == issue.scanner_id \
		or token == issue.rule_id \
		or token == issue.get_rule_key() \
		or token == issue.scanner_name


func _wildcard_to_regex(pattern: String) -> String:
	var escaped := ""
	for i in range(pattern.length()):
		var ch := pattern.substr(i, 1)
		if ch == "*":
			escaped += ".*"
		elif ".+?^${}()|[]\\".contains(ch):
			escaped += "\\" + ch
		else:
			escaped += ch
	return escaped


func _to_array(values: PackedStringArray) -> Array:
	var result: Array = []
	for value in values:
		result.append(value)
	return result
