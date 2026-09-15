@tool
extends RefCounted
class_name ShipCheckConfig

const CONFIG_PATH := "res://shipcheck_config.cfg"
const DEFAULTS_PATH := "res://addons/shipcheck/shipcheck_defaults.cfg"

const DEFAULT_DEBUG_RULES := {
	"print": {"enabled": true, "severity": "INFO"},
	"prints": {"enabled": true, "severity": "INFO"},
	"printerr": {"enabled": true, "severity": "WARNING"},
	"push_warning": {"enabled": true, "severity": "INFO"},
	"push_error": {"enabled": true, "severity": "WARNING"},
	"assert": {"enabled": true, "severity": "INFO"},
	"breakpoint": {"enabled": true, "severity": "ERROR"},
	"todo": {"enabled": true, "severity": "INFO"},
	"fixme": {"enabled": true, "severity": "INFO"},
}

const DEFAULT_LARGE_ASSET_LIMITS_MB := {
	"png": 8,
	"jpg": 8,
	"jpeg": 8,
	"webp": 8,
	"wav": 12,
	"ogg": 20,
	"mp3": 20,
	"mp4": 50,
	"webm": 50,
	"tres": 10,
	"res": 10,
	"psd": 1,
	"kra": 1,
	"aseprite": 1,
	"blend": 1,
}

var config := ConfigFile.new()


static func load_from_project() -> ShipCheckConfig:
	var settings := ShipCheckConfig.new()
	settings._load()
	return settings


func ensure_config_exists() -> Error:
	if not FileAccess.file_exists(CONFIG_PATH):
		return _copy_default_config_to_project()
	_load()
	return OK


func get_bool(section: String, key: String, default_value: bool) -> bool:
	return bool(config.get_value(section, key, default_value))


func get_int(section: String, key: String, default_value: int) -> int:
	return int(config.get_value(section, key, default_value))


func get_float(section: String, key: String, default_value: float) -> float:
	return float(config.get_value(section, key, default_value))


func get_string(section: String, key: String, default_value: String) -> String:
	return str(config.get_value(section, key, default_value))


func get_severity(section: String, key: String, default_value: ShipCheckIssue.Severity) -> ShipCheckIssue.Severity:
	return severity_from_string(get_string(section, key, _severity_to_string(default_value)), default_value)


func is_scanner_enabled(scanner_id: String, default_value: bool = true) -> bool:
	return get_bool("scanners", scanner_id, default_value)


func should_include_addons() -> bool:
	return get_bool("general", "include_addons", false)


func should_show_suppressed_issues() -> bool:
	return get_bool("general", "show_suppressed_issues", false)


func is_debug_rule_enabled(rule_id: String) -> bool:
	return get_bool("debug_code", "%s_enabled" % rule_id, _get_default_debug_enabled(rule_id))


func get_debug_rule_severity(rule_id: String) -> ShipCheckIssue.Severity:
	var default_label := _get_default_debug_severity(rule_id)
	return severity_from_string(get_string("debug_code", "%s_severity" % rule_id, default_label), ShipCheckIssue.Severity.INFO)


func get_large_asset_limit_mb(extension: String) -> float:
	var normalized := extension.to_lower().trim_prefix(".")
	var default_limit := float(DEFAULT_LARGE_ASSET_LIMITS_MB.get(normalized, get_float("large_assets", "default_threshold_mb", 25.0)))
	return get_float("large_assets", "%s_mb" % normalized, default_limit)


func get_large_asset_severity(extension: String) -> ShipCheckIssue.Severity:
	var normalized := extension.to_lower().trim_prefix(".")
	var default_label := get_string("large_assets", "severity", "WARNING")
	if ["psd", "kra", "aseprite", "blend"].has(normalized):
		default_label = get_string("large_assets", "source_file_severity", "INFO")
	return severity_from_string(default_label, ShipCheckIssue.Severity.WARNING)


func should_scan_large_asset_extension(extension: String) -> bool:
	var normalized := extension.to_lower().trim_prefix(".")
	if DEFAULT_LARGE_ASSET_LIMITS_MB.has(normalized):
		return true
	var extra_extensions := _to_packed_string_array(config.get_value("large_assets", "extra_extensions", []))
	return extra_extensions.has(normalized)


static func severity_from_string(label: String, fallback: ShipCheckIssue.Severity) -> ShipCheckIssue.Severity:
	match label.strip_edges().to_upper():
		"CRITICAL":
			return ShipCheckIssue.Severity.CRITICAL
		"ERROR":
			return ShipCheckIssue.Severity.ERROR
		"WARNING", "WARN":
			return ShipCheckIssue.Severity.WARNING
		"INFO":
			return ShipCheckIssue.Severity.INFO
		_:
			return fallback


func _load() -> void:
	config = ConfigFile.new()
	if FileAccess.file_exists(CONFIG_PATH):
		config.load(CONFIG_PATH)
	_apply_defaults()


func _apply_defaults() -> void:
	_set_default("general", "include_addons", false)
	_set_default("general", "show_suppressed_issues", false)

	_set_default("presets", "lite_default_description", "Core free pre-export scan for common release risks.")
	_set_default("presets", "lite_loose_description", "Lower-noise scan for early projects and messy prototypes.")

	_set_default("scanners", "missing_script", true)
	_set_default("scanners", "broken_resource", true)
	_set_default("scanners", "case_sensitive_path", true)
	_set_default("scanners", "project_settings", true)
	_set_default("scanners", "input_map", true)
	_set_default("scanners", "debug_code", true)
	_set_default("scanners", "export_preset", true)
	_set_default("scanners", "large_asset", true)
	_set_default("scanners", "release_risk", true)

	_set_default("broken_resource", "scan_pure_comments", false)

	for rule_id in DEFAULT_DEBUG_RULES.keys():
		_set_default("debug_code", "%s_enabled" % rule_id, DEFAULT_DEBUG_RULES[rule_id]["enabled"])
		_set_default("debug_code", "%s_severity" % rule_id, DEFAULT_DEBUG_RULES[rule_id]["severity"])

	_set_default("large_assets", "enabled", true)
	_set_default("large_assets", "default_threshold_mb", 25)
	_set_default("large_assets", "severity", "WARNING")
	_set_default("large_assets", "source_file_severity", "INFO")
	_set_default("large_assets", "extra_extensions", [])
	for extension in DEFAULT_LARGE_ASSET_LIMITS_MB.keys():
		_set_default("large_assets", "%s_mb" % extension, DEFAULT_LARGE_ASSET_LIMITS_MB[extension])

	_set_default("input_map", "report_undefined_actions", true)
	_set_default("input_map", "report_unused_actions", true)
	_set_default("input_map", "ignore_ui_actions", true)

	_set_default("project_settings", "require_main_scene", true)
	_set_default("project_settings", "no_main_scene_severity", "WARNING")
	_set_default("project_settings", "main_scene_missing_severity", "CRITICAL")
	_set_default("project_settings", "check_project_icon", true)
	_set_default("project_settings", "project_icon_missing_severity", "WARNING")
	_set_default("project_settings", "check_autoloads", true)
	_set_default("project_settings", "autoload_missing_severity", "CRITICAL")
	_set_default("project_settings", "project_name_missing_severity", "INFO")

	_set_default("export_presets", "require_export_presets", true)
	_set_default("export_presets", "require_export_paths", true)

	_set_default("release_risk", "report_vcs_ignore", true)
	_set_default("release_risk", "missing_gitignore_severity", "WARNING")
	_set_default("release_risk", "missing_gitignore_rule_severity", "INFO")
	_set_default("release_risk", "report_export_credentials_file", true)
	_set_default("release_risk", "export_credentials_severity", "WARNING")
	_set_default("release_risk", "report_sensitive_files", true)
	_set_default("release_risk", "sensitive_file_severity", "CRITICAL")
	_set_default("release_risk", "report_secret_literals", true)
	_set_default("release_risk", "secret_literal_severity", "WARNING")
	_set_default("release_risk", "private_key_literal_severity", "CRITICAL")
	_set_default("release_risk", "report_plain_http_urls", true)
	_set_default("release_risk", "plain_http_url_severity", "WARNING")
	_set_default("release_risk", "report_gdignore_issues", true)
	_set_default("release_risk", "gdignore_reference_severity", "ERROR")
	_set_default("release_risk", "gdignore_content_severity", "INFO")


func _set_default(section: String, key: String, value) -> void:
	if not config.has_section_key(section, key):
		config.set_value(section, key, value)


func _get_default_debug_enabled(rule_id: String) -> bool:
	if DEFAULT_DEBUG_RULES.has(rule_id):
		return bool(DEFAULT_DEBUG_RULES[rule_id]["enabled"])
	return true


func _get_default_debug_severity(rule_id: String) -> String:
	if DEFAULT_DEBUG_RULES.has(rule_id):
		return str(DEFAULT_DEBUG_RULES[rule_id]["severity"])
	return "INFO"


func _copy_default_config_to_project() -> Error:
	if FileAccess.file_exists(DEFAULTS_PATH):
		var source := FileAccess.open(DEFAULTS_PATH, FileAccess.READ)
		if source == null:
			return ERR_CANT_OPEN
		var target := FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
		if target == null:
			return ERR_CANT_CREATE
		target.store_string(source.get_as_text())
		target.close()
		return OK

	_load()
	_apply_defaults()
	return config.save(CONFIG_PATH)


func _severity_to_string(severity: ShipCheckIssue.Severity) -> String:
	match severity:
		ShipCheckIssue.Severity.CRITICAL:
			return "CRITICAL"
		ShipCheckIssue.Severity.ERROR:
			return "ERROR"
		ShipCheckIssue.Severity.WARNING:
			return "WARNING"
		_:
			return "INFO"


func _to_packed_string_array(value) -> PackedStringArray:
	var result := PackedStringArray()
	if value is PackedStringArray:
		return value
	if value is Array:
		for item in value:
			result.append(str(item).to_lower().trim_prefix("."))
	elif value is String and value != "":
		result.append(value.to_lower().trim_prefix("."))
	return result
