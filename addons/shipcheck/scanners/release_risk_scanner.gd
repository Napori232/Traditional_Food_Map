@tool
extends "res://addons/shipcheck/scanners/scanner_base.gd"
class_name ReleaseRiskScanner

const TEXT_EXTENSIONS := [
	"cfg",
	"env",
	"gd",
	"gdshader",
	"ini",
	"json",
	"md",
	"shader",
	"tres",
	"tscn",
	"txt"
]

const SECRET_WORDS := [
	"api_key",
	"apikey",
	"auth_token",
	"client_secret",
	"password",
	"private_key",
	"secret",
	"token"
]

const SECRET_PREFIXES := [
	"sk_live_",
	"sk_test_",
	"ghp_",
	"gho_",
	"github_pat_",
	"xoxb-",
	"xoxp-",
	"AIza",
	"AKIA"
]


func get_scanner_id() -> String:
	return "release_risk"


func get_scanner_name() -> String:
	return "Release Risk Scanner"


func scan(project_root: String, context: Dictionary = {}) -> Array[ShipCheckIssue]:
	var issues: Array[ShipCheckIssue] = []
	if not _scanner_enabled(context):
		return issues

	var settings := _get_shipcheck_config(context)
	var files := _list_project_files(project_root)

	if settings.get_bool("release_risk", "report_vcs_ignore", true):
		_scan_vcs_ignore(project_root, settings, issues)

	if settings.get_bool("release_risk", "report_export_credentials_file", true):
		_scan_export_credentials(settings, issues)

	if settings.get_bool("release_risk", "report_sensitive_files", true):
		_scan_sensitive_files(files, settings, issues)

	if settings.get_bool("release_risk", "report_gdignore_issues", true):
		_scan_gdignore(files, settings, issues)

	if settings.get_bool("release_risk", "report_secret_literals", true) or settings.get_bool("release_risk", "report_plain_http_urls", true):
		_scan_text_risks(files, settings, issues)

	return issues


func _scan_vcs_ignore(project_root: String, settings: ShipCheckConfig, issues: Array[ShipCheckIssue]) -> void:
	var path := project_root.path_join(".gitignore")
	if not FileAccess.file_exists(path):
		issues.append(ShipCheckIssue.create(
			settings.get_severity("release_risk", "missing_gitignore_severity", ShipCheckIssue.Severity.WARNING),
			"Missing .gitignore",
			"Godot projects should ignore generated editor/cache files in version control.",
			path,
			-1,
			"Generate version-control metadata in Godot or add a .gitignore that includes .godot/ and *.translation.",
			get_scanner_name()
		))
		return

	var text := _read_text_file(path)
	var normalized := text.replace("\\", "/")
	if not normalized.contains(".godot/") and not normalized.contains(".godot"):
		issues.append(ShipCheckIssue.create(
			settings.get_severity("release_risk", "missing_gitignore_rule_severity", ShipCheckIssue.Severity.INFO),
			".gitignore Missing .godot Rule",
			"Godot stores generated editor/cache data in .godot/.",
			path,
			-1,
			"Add .godot/ to .gitignore.",
			get_scanner_name()
		))

	if not normalized.contains("*.translation"):
		issues.append(ShipCheckIssue.create(
			settings.get_severity("release_risk", "missing_gitignore_rule_severity", ShipCheckIssue.Severity.INFO),
			".gitignore Missing Translation Rule",
			"Godot can generate binary imported .translation files.",
			path,
			-1,
			"Add *.translation to .gitignore if your project imports translations from CSV files.",
			get_scanner_name()
		))


func _scan_export_credentials(settings: ShipCheckConfig, issues: Array[ShipCheckIssue]) -> void:
	var path := "res://.godot/export_credentials.cfg"
	if not FileAccess.file_exists(path):
		return

	issues.append(ShipCheckIssue.create(
		settings.get_severity("release_risk", "export_credentials_severity", ShipCheckIssue.Severity.WARNING),
		"Export Credentials File Present",
		"Godot stores confidential export passwords and encryption keys in .godot/export_credentials.cfg.",
		path,
		-1,
		"Confirm this file is ignored by version control and is not shared with exported packages or public bug reports.",
		get_scanner_name()
	))


func _scan_sensitive_files(files: PackedStringArray, settings: ShipCheckConfig, issues: Array[ShipCheckIssue]) -> void:
	for file_path in files:
		if not _is_sensitive_file(file_path):
			continue
		issues.append(ShipCheckIssue.create(
			settings.get_severity("release_risk", "sensitive_file_severity", ShipCheckIssue.Severity.CRITICAL),
			"Potential Secret File",
			"A file commonly used for credentials or private keys is inside the project.",
			file_path,
			-1,
			"Move secrets outside res:// and load them from user://, environment variables, or platform-specific secure storage.",
			get_scanner_name(),
			"File: %s" % file_path.get_file()
		))


func _scan_gdignore(files: PackedStringArray, settings: ShipCheckConfig, issues: Array[ShipCheckIssue]) -> void:
	var ignored_dirs := PackedStringArray()
	for file_path in files:
		if file_path.get_file() != ".gdignore":
			continue

		var folder := file_path.get_base_dir()
		if not ignored_dirs.has(folder):
			ignored_dirs.append(folder)

		var text := _read_text_file(file_path).strip_edges()
		if text != "":
			issues.append(ShipCheckIssue.create(
				settings.get_severity("release_risk", "gdignore_content_severity", ShipCheckIssue.Severity.INFO),
				".gdignore Has Contents",
				"Godot ignores the contents of .gdignore files; they do not support patterns.",
				file_path,
				-1,
				"Keep .gdignore files empty. The file itself marks the folder as ignored.",
				get_scanner_name()
			))

	if ignored_dirs.is_empty():
		return

	for file_path in files:
		if not _should_scan_text_file(file_path):
			continue
		var lines := _read_text_lines(file_path)
		for i in range(lines.size()):
			if _line_is_ignored(lines[i]):
				continue
			var paths := _extract_res_paths(lines[i])
			for referenced_path in paths:
				var folder := _get_ignored_folder_for_path(referenced_path, ignored_dirs)
				if folder == "":
					continue
				issues.append(ShipCheckIssue.create(
					settings.get_severity("release_risk", "gdignore_reference_severity", ShipCheckIssue.Severity.ERROR),
					"Reference To .gdignore Folder",
					"A resource path points into a folder hidden by .gdignore.",
					file_path,
					i + 1,
					"Move the resource out of the ignored folder or remove the .gdignore file.",
					get_scanner_name(),
					"Referenced: %s\nIgnored folder: %s" % [referenced_path, folder]
				))


func _scan_text_risks(files: PackedStringArray, settings: ShipCheckConfig, issues: Array[ShipCheckIssue]) -> void:
	for file_path in files:
		if not _should_scan_text_file(file_path):
			continue

		var lines := _read_text_lines(file_path)
		for i in range(lines.size()):
			var line := lines[i]
			if _line_is_ignored(line):
				continue
			var line_number := i + 1

			if settings.get_bool("release_risk", "report_secret_literals", true):
				_scan_secret_line(line, file_path, line_number, settings, issues)

			if settings.get_bool("release_risk", "report_plain_http_urls", true):
				_scan_http_line(line, file_path, line_number, settings, issues)


func _scan_secret_line(
	line: String,
	file_path: String,
	line_number: int,
	settings: ShipCheckConfig,
	issues: Array[ShipCheckIssue]
) -> void:
	if line.contains("-----BEGIN ") and line.contains("PRIVATE KEY-----"):
		issues.append(ShipCheckIssue.create(
			settings.get_severity("release_risk", "private_key_literal_severity", ShipCheckIssue.Severity.CRITICAL),
			"Private Key Literal",
			"A private key appears to be embedded in a project file.",
			file_path,
			line_number,
			"Remove private keys from the project and rotate any credential that may have been committed or shared.",
			get_scanner_name(),
			"Matched private-key header."
		))
		return

	var secret := _find_secret_like_token(line)
	if secret == "":
		return

	issues.append(ShipCheckIssue.create(
		settings.get_severity("release_risk", "secret_literal_severity", ShipCheckIssue.Severity.WARNING),
		"Potential Secret Literal",
		"A token, password, or API key-like value appears in a project text file.",
		file_path,
		line_number,
		"Move secrets outside the exported project and rotate the value if it was ever committed or distributed.",
		get_scanner_name(),
		"Matched: %s" % _mask_secret(secret)
	))


func _scan_http_line(
	line: String,
	file_path: String,
	line_number: int,
	settings: ShipCheckConfig,
	issues: Array[ShipCheckIssue]
) -> void:
	var urls := _extract_http_urls(line)
	for url in urls:
		if _is_local_http_url(url):
			continue
		issues.append(ShipCheckIssue.create(
			settings.get_severity("release_risk", "plain_http_url_severity", ShipCheckIssue.Severity.WARNING),
			"Plain HTTP URL",
			"A non-local URL uses http:// instead of https://.",
			file_path,
			line_number,
			"Use HTTPS for release builds unless plain HTTP is strictly required and documented.",
			get_scanner_name(),
			"URL: %s" % url
		))


func _list_project_files(root_path: String) -> PackedStringArray:
	var results := PackedStringArray()
	var dir := DirAccess.open(root_path)
	if dir == null:
		return results

	dir.include_hidden = true
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue

		var full_path := root_path.path_join(entry)
		if dir.current_is_dir():
			if full_path == "res://.godot":
				var credentials_path := "res://.godot/export_credentials.cfg"
				if FileAccess.file_exists(credentials_path):
					results.append(credentials_path)
			elif not _should_skip_directory(full_path):
				results.append_array(_list_project_files(full_path))
		else:
			if not _should_skip_file(full_path):
				results.append(full_path)

		entry = dir.get_next()

	dir.list_dir_end()
	return results


func _is_sensitive_file(path: String) -> bool:
	var name := path.get_file().to_lower()
	var extension := path.get_extension().to_lower()

	if name.ends_with(".example") or name.ends_with(".sample") or name.ends_with(".template"):
		return false

	if name == ".env" or name.begins_with(".env."):
		return true
	if ["id_rsa", "id_dsa", "id_ecdsa", "id_ed25519"].has(name):
		return true
	if ["pem", "p12", "pfx", "key", "keystore", "jks"].has(extension):
		return true
	if name.contains("service_account") and extension == "json":
		return true
	if name.contains("credentials") and extension == "json":
		return true

	return false


func _should_scan_text_file(path: String) -> bool:
	var name := path.get_file().to_lower()
	if name == ".gitignore" or name == ".gitattributes" or name == ".gdignore":
		return true
	return TEXT_EXTENSIONS.has(path.get_extension().to_lower())


func _find_secret_like_token(line: String) -> String:
	var lower_line := line.to_lower()
	for prefix in SECRET_PREFIXES:
		var index := line.find(prefix)
		if index >= 0:
			return _read_token_at(line, index)

	var has_secret_word := false
	for word in SECRET_WORDS:
		if lower_line.contains(word):
			has_secret_word = true
			break
	if not has_secret_word:
		return ""

	var quoted := _extract_first_quoted_value(line)
	if quoted.length() >= 16 and not _looks_like_safe_literal(quoted):
		return quoted

	return ""


func _extract_first_quoted_value(line: String) -> String:
	var quote := ""
	var start := -1
	for i in range(line.length()):
		var ch := line.substr(i, 1)
		if quote == "":
			if ch == "\"" or ch == "'":
				quote = ch
				start = i + 1
		elif ch == quote:
			return line.substr(start, i - start)
	return ""


func _read_token_at(line: String, index: int) -> String:
	var result := ""
	for i in range(index, line.length()):
		var ch := line.substr(i, 1)
		if ch == "\"" or ch == "'" or ch == " " or ch == "\t" or ch == "," or ch == ")" or ch == "]" or ch == "}":
			break
		result += ch
	return result


func _looks_like_safe_literal(value: String) -> bool:
	var lower_value := value.to_lower()
	return lower_value.begins_with("res://") \
		or lower_value.begins_with("user://") \
		or lower_value.begins_with("uid://") \
		or lower_value.contains("example") \
		or lower_value.contains("fixture") \
		or lower_value.contains("placeholder")


func _mask_secret(value: String) -> String:
	if value.length() <= 8:
		return "********"
	return "%s...%s" % [value.substr(0, 4), value.substr(value.length() - 4, 4)]


func _extract_http_urls(line: String) -> PackedStringArray:
	var urls := PackedStringArray()
	var index := line.find("http://")
	while index >= 0:
		urls.append(_read_url_at(line, index))
		index = line.find("http://", index + 7)
	return urls


func _read_url_at(line: String, index: int) -> String:
	var result := ""
	for i in range(index, line.length()):
		var ch := line.substr(i, 1)
		if ch == "\"" or ch == "'" or ch == " " or ch == "\t" or ch == "," or ch == ")" or ch == "]" or ch == "}":
			break
		result += ch
	return result


func _is_local_http_url(url: String) -> bool:
	var lower_url := url.to_lower()
	return lower_url.begins_with("http://localhost") \
		or lower_url.begins_with("http://127.") \
		or lower_url.begins_with("http://0.0.0.0") \
		or lower_url.begins_with("http://[::1]")


func _get_ignored_folder_for_path(path: String, ignored_dirs: PackedStringArray) -> String:
	for folder in ignored_dirs:
		if path == folder or path.begins_with("%s/" % folder):
			return folder
	return ""
