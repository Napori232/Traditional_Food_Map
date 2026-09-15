@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name LargeAssetScanner

func get_scanner_id() -> String:
	return "large_asset"


func get_scanner_name() -> String:
	return "Large Asset Scanner"


func scan(project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var settings := _get_shipcheck_config(context)
	if not settings.get_bool("large_assets", "enabled", true):
		return issues

	var files := _get_files(project_root, PackedStringArray(), context)

	for file_path in files:
		var extension := file_path.get_extension().to_lower()
		if not settings.should_scan_large_asset_extension(extension):
			continue

		var limit_mb := settings.get_large_asset_limit_mb(extension)
		var file := FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			continue
		var size_bytes := file.get_length()
		var size_mb := float(size_bytes) / 1024.0 / 1024.0
		if size_mb <= limit_mb:
			continue

		issues.append(ShipCheckIssue.create(
			settings.get_large_asset_severity(extension),
			"Large Asset Found",
			"An asset is larger than ShipCheck's suggested size threshold.",
			file_path,
			-1,
			"Review whether this belongs in the exported project or should be optimized.",
			get_scanner_name(),
			"Size: %s, threshold: %s" % [_format_size(size_bytes), _format_size(limit_mb * 1024.0 * 1024.0)]
		))

	return issues


func _format_size(bytes: float) -> String:
	if bytes < 1024.0:
		return "%d B" % int(bytes)
	if bytes < 1024.0 * 1024.0:
		return "%.2f KB" % (bytes / 1024.0)
	return "%.2f MB" % (bytes / 1024.0 / 1024.0)
