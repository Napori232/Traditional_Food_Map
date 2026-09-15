@tool
extends RefCounted
class_name ShipCheckScannerRegistry

const ShipCheckEditionScript := preload("res://addons/shipcheck/data/shipcheck_edition.gd")
const MissingScriptScannerScript := preload("res://addons/shipcheck/scanners/missing_script_scanner.gd")
const BrokenResourceScannerScript := preload("res://addons/shipcheck/scanners/broken_resource_scanner.gd")
const CaseSensitivePathScannerScript := preload("res://addons/shipcheck/scanners/case_sensitive_path_scanner.gd")
const ProjectSettingsScannerScript := preload("res://addons/shipcheck/scanners/project_settings_scanner.gd")
const InputMapScannerScript := preload("res://addons/shipcheck/scanners/input_map_scanner.gd")
const DebugCodeScannerScript := preload("res://addons/shipcheck/scanners/debug_code_scanner.gd")
const ExportPresetScannerScript := preload("res://addons/shipcheck/scanners/export_preset_scanner.gd")
const LargeAssetScannerScript := preload("res://addons/shipcheck/scanners/large_asset_scanner.gd")
const ReleaseRiskScannerScript := preload("res://addons/shipcheck/scanners/release_risk_scanner.gd")

const LITE_DEFAULT_SCANNERS := [
	"missing_script",
	"broken_resource",
	"case_sensitive_path",
	"project_settings",
	"input_map",
	"debug_code",
	"export_preset",
	"large_asset",
	"release_risk",
]

const LITE_LOOSE_SCANNERS := [
	"missing_script",
	"broken_resource",
	"case_sensitive_path",
	"project_settings",
	"input_map",
	"export_preset",
	"release_risk",
]


static func get_edition() -> int:
	return ShipCheckEditionScript.get_current_edition()


static func get_edition_label() -> String:
	return "Lite"


static func get_default_preset() -> String:
	return "Lite Default"


static func get_presets() -> PackedStringArray:
	return PackedStringArray(["Lite Default", "Lite Loose"])


static func normalize_preset(preset: String) -> String:
	match preset.strip_edges().to_lower():
		"loose", "lite loose":
			return "Lite Loose"
		_:
			return "Lite Default"


static func get_preset_metadata(preset: String) -> Dictionary:
	var normalized := normalize_preset(preset)
	var scanner_ids := _get_scanner_ids_for_preset(normalized)
	var metadata := {
		"Lite Default": {
			"name": "Lite Default",
			"short_description": "Free core scan for common pre-export issues.",
			"description": "Runs the Lite reference, settings, input, debug, export, asset-size, and basic release-risk checks. Good before sharing builds or uploading jam/student projects.",
			"recommended_use": "Use this for normal Lite scans before exporting.",
		},
		"Lite Loose": {
			"name": "Lite Loose",
			"short_description": "Lower-noise scan for early projects.",
			"description": "Runs the Lite checks most likely to catch broken builds while skipping debug leftovers and large asset warnings. Good when a project is still messy but you want real blockers.",
			"recommended_use": "Use this while prototyping or cleaning up a noisy project.",
		},
	}
	var result: Dictionary = metadata.get(normalized, metadata["Lite Default"]).duplicate()
	result["scanner_count"] = scanner_ids.size()
	result["scanners"] = scanner_ids
	return result


static func get_preset_description(preset: String) -> String:
	return str(get_preset_metadata(preset).get("description", ""))


static func get_scanner_entries(preset: String) -> Array:
	var entries: Array = []
	for scanner_id in _get_scanner_ids_for_preset(normalize_preset(preset)):
		entries.append(get_scanner_metadata(scanner_id))
	return entries


static func instantiate_scanners(preset: String, config = null) -> Array:
	var scanners: Array = []
	for scanner_id in _get_scanner_ids_for_preset(normalize_preset(preset)):
		var metadata := get_scanner_metadata(scanner_id)
		var default_enabled := bool(metadata.get("default_enabled_lite", true))
		if config != null and not config.is_scanner_enabled(scanner_id, default_enabled):
			continue

		var scanner = _new_scanner(scanner_id)
		if scanner != null:
			scanners.append(scanner)
	return scanners


static func get_scanner_metadata(scanner_id: String) -> Dictionary:
	var metadata := {
		"missing_script": {
			"scanner_id": "missing_script",
			"display_name": "Missing Script Scanner",
			"description": "Finds scene/resource script references whose files are gone.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "References",
		},
		"broken_resource": {
			"scanner_id": "broken_resource",
			"display_name": "Broken Resource Scanner",
			"description": "Finds quoted res:// references that do not resolve.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "References",
		},
		"case_sensitive_path": {
			"scanner_id": "case_sensitive_path",
			"display_name": "Case-Sensitive Path Scanner",
			"description": "Finds references that differ from the real file casing.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "References",
		},
		"project_settings": {
			"scanner_id": "project_settings",
			"display_name": "Project Settings Scanner",
			"description": "Checks main scene, autoloads, icon paths, and release settings.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "Project Settings",
		},
		"input_map": {
			"scanner_id": "input_map",
			"display_name": "InputMap Scanner",
			"description": "Checks InputMap actions used in scripts against Project Settings.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "Input",
		},
		"debug_code": {
			"scanner_id": "debug_code",
			"display_name": "Debug Code Scanner",
			"description": "Finds prints, breakpoints, asserts, TODOs, and similar release leftovers.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "Release Risk",
		},
		"export_preset": {
			"scanner_id": "export_preset",
			"display_name": "Export Preset Scanner",
			"description": "Checks export preset presence and blank export paths.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "Export",
		},
		"large_asset": {
			"scanner_id": "large_asset",
			"display_name": "Large Asset Scanner",
			"description": "Flags large runtime assets and source-art files by threshold.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "Assets",
		},
		"release_risk": {
			"scanner_id": "release_risk",
			"display_name": "Release Risk Scanner",
			"description": "Finds secrets, .env files, .gdignore traps, plain HTTP URLs, and VCS gaps.",
			"edition": "lite",
			"default_enabled_lite": true,
			"category": "Release Risk",
		},
	}
	return metadata.get(scanner_id, {})


static func _get_scanner_ids_for_preset(preset: String) -> Array:
	if preset == "Lite Loose":
		return LITE_LOOSE_SCANNERS.duplicate()
	return LITE_DEFAULT_SCANNERS.duplicate()


static func _new_scanner(scanner_id: String):
	match scanner_id:
		"missing_script":
			return MissingScriptScannerScript.new()
		"broken_resource":
			return BrokenResourceScannerScript.new()
		"case_sensitive_path":
			return CaseSensitivePathScannerScript.new()
		"project_settings":
			return ProjectSettingsScannerScript.new()
		"input_map":
			return InputMapScannerScript.new()
		"debug_code":
			return DebugCodeScannerScript.new()
		"export_preset":
			return ExportPresetScannerScript.new()
		"large_asset":
			return LargeAssetScannerScript.new()
		"release_risk":
			return ReleaseRiskScannerScript.new()
		_:
			return null
