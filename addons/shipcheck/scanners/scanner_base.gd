@tool
extends RefCounted
class_name ShipCheckScanner

const ShipCheckIssueScript := preload("res://addons/shipcheck/data/shipcheck_issue.gd")
const ShipCheckConfigScript := preload("res://addons/shipcheck/data/shipcheck_config.gd")


func get_scanner_id() -> String:
	return "base"


func get_scanner_name() -> String:
	return "Unnamed Scanner"


func scan(_project_root: String, _context: Dictionary = {}) -> Array[ShipCheckIssue]:
	return []


func _get_shipcheck_config(context: Dictionary) -> ShipCheckConfig:
	if context.has("config") and context["config"] != null:
		return context["config"]
	return ShipCheckConfigScript.load_from_project()


func _scanner_enabled(context: Dictionary, default_value: bool = true) -> bool:
	return _get_shipcheck_config(context).is_scanner_enabled(get_scanner_id(), default_value)


func _get_files(project_root: String, extensions: PackedStringArray, context: Dictionary) -> PackedStringArray:
	if not context.has("_shipcheck_file_cache"):
		context["_shipcheck_file_cache"] = {}

	var cache: Dictionary = context["_shipcheck_file_cache"]
	var include_addons := _get_shipcheck_config(context).should_include_addons()
	var key := "%s|%s|addons:%s" % [project_root, ",".join(extensions), str(include_addons)]
	if cache.has(key):
		return cache[key]

	var files := _list_files_recursive(project_root, extensions, include_addons)
	cache[key] = files
	return files


func _get_actual_path_map(project_root: String, context: Dictionary) -> Dictionary:
	if not context.has("_shipcheck_actual_path_map_cache"):
		context["_shipcheck_actual_path_map_cache"] = {}

	var cache: Dictionary = context["_shipcheck_actual_path_map_cache"]
	if cache.has(project_root):
		return cache[project_root]

	var paths := {}
	for path in _get_files(project_root, PackedStringArray(), context):
		paths[path.to_lower()] = path

	cache[project_root] = paths
	return paths


func _list_files_recursive(root_path: String, extensions: PackedStringArray = PackedStringArray(), include_addons: bool = false) -> PackedStringArray:
	var results := PackedStringArray()
	var dir := DirAccess.open(root_path)
	if dir == null:
		return results

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry.begins_with(".") and entry != ".gdignore":
			entry = dir.get_next()
			continue

		var full_path := root_path.path_join(entry)
		if dir.current_is_dir():
			if not _should_skip_directory(full_path, include_addons):
				results.append_array(_list_files_recursive(full_path, extensions, include_addons))
		else:
			if not _should_skip_file(full_path) and (extensions.is_empty() or extensions.has(entry.get_extension().to_lower())):
				results.append(full_path)

		entry = dir.get_next()

	dir.list_dir_end()
	return results


func _should_skip_directory(path: String, include_addons: bool = false) -> bool:
	var normalized := path.trim_suffix("/")
	return (not include_addons and (normalized == "res://addons" or normalized.begins_with("res://addons/"))) \
		or normalized == "res://.godot" \
		or normalized.begins_with("res://.godot/") \
		or normalized == "res://_shipcheck_quarantine" \
		or normalized.begins_with("res://_shipcheck_quarantine/")


func _should_skip_file(path: String) -> bool:
	return [
		"shipcheck_ignore.cfg",
		"shipcheck_report.md",
		"shipcheck_config.cfg"
	].has(path.get_file())


func _read_text_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	return file.get_as_text()


func _read_text_lines(path: String) -> PackedStringArray:
	var text := _read_text_file(path)
	if text == "":
		return PackedStringArray()
	text = text.replace("\r\n", "\n").replace("\r", "\n")
	return text.split("\n", true)


func _extract_res_paths(line: String) -> PackedStringArray:
	var paths := PackedStringArray()
	var quoted_regex := RegEx.new()
	quoted_regex.compile("[\\\"'](res://[^\\\"']+)[\\\"']")
	var quoted_matches := quoted_regex.search_all(line)
	for result in quoted_matches:
		var quoted_path := _clean_extracted_res_path(result.get_string(1))
		if quoted_path != "" and not paths.has(quoted_path):
			paths.append(quoted_path)

	if not paths.is_empty():
		return paths

	var regex := RegEx.new()
	regex.compile("res://[^\\\"'\\s\\)\\]\\}\\,]+")
	var matches := regex.search_all(line)
	for result in matches:
		var path := _clean_extracted_res_path(result.get_string())
		if path != "" and not paths.has(path):
			paths.append(path)
	return paths


func _clean_extracted_res_path(path: String) -> String:
	var cleaned := path.strip_edges()
	cleaned = cleaned.trim_prefix("[code]").trim_prefix("`")
	var bbcode_index := cleaned.find("[/code]")
	if bbcode_index >= 0:
		cleaned = cleaned.substr(0, bbcode_index)
	var markdown_index := cleaned.find("</code>")
	if markdown_index >= 0:
		cleaned = cleaned.substr(0, markdown_index)
	while cleaned.length() > 0:
		var last := cleaned.substr(cleaned.length() - 1, 1)
		if "`\"',.;:)]}".contains(last):
			cleaned = cleaned.substr(0, cleaned.length() - 1)
		else:
			break
	return cleaned


func _resource_or_file_exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.open(path) != null or ResourceLoader.exists(path)


func _looks_dynamic_or_partial(path: String) -> bool:
	return path.contains("+") \
		or path.contains("%") \
		or path.contains("{") \
		or path.contains("}") \
		or path.ends_with("/")


func _line_is_ignored(line: String) -> bool:
	return line.contains("shipcheck: ignore") or line.contains("shipcheck: ignore-line")


func _is_pure_comment_line(line: String) -> bool:
	var trimmed := line.strip_edges()
	return trimmed.begins_with("#") or trimmed.begins_with(";")


func _get_defined_input_actions() -> PackedStringArray:
	var actions := PackedStringArray()
	for property in ProjectSettings.get_property_list():
		var name := str(property.get("name", ""))
		if not name.begins_with("input/"):
			continue
		var action := name.trim_prefix("input/")
		if action != "" and not actions.has(action):
			actions.append(action)
	return actions
