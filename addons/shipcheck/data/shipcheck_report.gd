@tool
extends RefCounted
class_name ShipCheckReport

const ShipCheckIssueScript := preload("res://addons/shipcheck/data/shipcheck_issue.gd")

var issues: Array[ShipCheckIssue] = []
var scanned_files: int = 0
var profile_name: String = "Full"
var created_at_unix: int = 0


func _init() -> void:
	created_at_unix = Time.get_unix_time_from_system()


func add_issues(p_issues: Array[ShipCheckIssue]) -> void:
	issues.append_array(p_issues)


func get_total_count() -> int:
	return issues.size()


func get_count(severity: ShipCheckIssue.Severity) -> int:
	var total := 0
	for issue in issues:
		if issue.severity == severity:
			total += 1
	return total


func get_blocker_count() -> int:
	return get_count(ShipCheckIssue.Severity.CRITICAL) + get_count(ShipCheckIssue.Severity.ERROR)


func get_score() -> int:
	var score := 100
	score -= get_count(ShipCheckIssue.Severity.CRITICAL) * 25
	score -= get_count(ShipCheckIssue.Severity.ERROR) * 10
	score -= get_count(ShipCheckIssue.Severity.WARNING) * 2
	return clampi(score, 0, 100)


func get_release_status() -> String:
	if get_count(ShipCheckIssue.Severity.CRITICAL) > 0:
		return "Blocked"
	if get_count(ShipCheckIssue.Severity.ERROR) > 0:
		return "Needs fixes"
	if get_count(ShipCheckIssue.Severity.WARNING) > 0:
		return "Review warnings"
	return "Ready"


func get_score_breakdown() -> Dictionary:
	return {
		"release_blockers": get_blocker_count(),
		"reference_risk": _count_category("References"),
		"configuration_risk": _count_categories(PackedStringArray(["Project Settings", "Export", "Input"])),
		"release_risk": _count_category("Release Risk"),
		"asset_risk": _count_category("Assets"),
		"code_risk": _count_categories(PackedStringArray(["GDScript Quality", "Style", "Performance"])),
	}


func get_category_counts() -> Dictionary:
	var counts := {}
	for issue in issues:
		var key := issue.category if issue.category != "" else "General"
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


func get_scanner_counts() -> Dictionary:
	var counts := {}
	for issue in issues:
		var key := issue.scanner_name if issue.scanner_name != "" else issue.scanner_id
		if key == "":
			key = "Unknown Scanner"
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


func get_issues_by_category() -> Dictionary:
	var grouped := {}
	for issue in issues:
		var key := issue.category if issue.category != "" else "General"
		if not grouped.has(key):
			grouped[key] = []
		grouped[key].append(issue)
	return grouped


func get_issues_by_scanner() -> Dictionary:
	var grouped := {}
	for issue in issues:
		var key := issue.scanner_name if issue.scanner_name != "" else issue.scanner_id
		if key == "":
			key = "Unknown Scanner"
		if not grouped.has(key):
			grouped[key] = []
		grouped[key].append(issue)
	return grouped


func to_dict(baseline = null) -> Dictionary:
	var issue_dicts := []
	for issue in issues:
		var known: bool = baseline != null and baseline.is_issue_known(issue)
		issue_dicts.append({
			"severity": issue.get_severity_label(),
			"title": issue.title,
			"message": issue.message,
			"file": issue.file_path,
			"line": issue.line_number,
			"scanner": issue.scanner_name,
			"scanner_id": issue.scanner_id,
			"rule_id": issue.rule_id,
			"rule_key": issue.get_rule_key(),
			"category": issue.category,
			"detail": issue.detail,
			"fix_hint": issue.fix_hint,
			"why_this_matters": issue.why_this_matters,
			"ignore_hint": issue.ignore_hint,
			"id": issue.get_issue_id(),
			"legacy_id": issue.get_legacy_issue_id(),
			"known": known,
		})

	var result := {
		"profile": profile_name,
		"release_status": get_release_status(),
		"health_score": get_score(),
		"total": get_total_count(),
		"counts": {
			"critical": get_count(ShipCheckIssue.Severity.CRITICAL),
			"error": get_count(ShipCheckIssue.Severity.ERROR),
			"warning": get_count(ShipCheckIssue.Severity.WARNING),
			"info": get_count(ShipCheckIssue.Severity.INFO),
		},
		"score_breakdown": get_score_breakdown(),
		"categories": get_category_counts(),
		"scanners": get_scanner_counts(),
		"issues": issue_dicts,
	}
	if baseline != null:
		result["baseline"] = {
			"known": baseline.get_known_count(issues),
			"new": baseline.get_new_issues(issues).size(),
			"stale": baseline.get_stale_issue_ids(issues).size() if baseline.has_method("get_stale_issue_ids") else 0,
		}
	return result


func to_markdown() -> String:
	var lines: Array[String] = []
	lines.append("# ShipCheck Report")
	lines.append("")
	lines.append("- Profile: %s" % profile_name)
	lines.append("- Release status: %s" % get_release_status())
	lines.append("- Health score: %d/100" % get_score())
	lines.append("- Total issues: %d" % get_total_count())
	lines.append("- Critical: %d" % get_count(ShipCheckIssue.Severity.CRITICAL))
	lines.append("- Errors: %d" % get_count(ShipCheckIssue.Severity.ERROR))
	lines.append("- Warnings: %d" % get_count(ShipCheckIssue.Severity.WARNING))
	lines.append("- Info: %d" % get_count(ShipCheckIssue.Severity.INFO))
	lines.append("")
	lines.append("## Score Breakdown")
	lines.append("")
	for key in get_score_breakdown().keys():
		lines.append("- %s: %d" % [_humanize_key(key), int(get_score_breakdown()[key])])
	lines.append("")

	if issues.is_empty():
		lines.append("No issues found.")
		return "\n".join(lines)

	if get_blocker_count() > 0:
		lines.append("## Release Blockers")
		lines.append("")
		for issue in issues:
			if issue.severity >= ShipCheckIssue.Severity.ERROR:
				lines.append(issue.to_markdown())
				lines.append("")

	lines.append("## Findings By Category")
	lines.append("")
	var grouped := get_issues_by_category()
	for category in _sorted_keys(grouped):
		lines.append("## %s" % category)
		lines.append("")
		for issue in grouped[category]:
			lines.append(issue.to_markdown())
			lines.append("")

	return "\n".join(lines)


func to_html(baseline = null) -> String:
	var lines: Array[String] = []
	lines.append("<!doctype html>")
	lines.append("<html lang=\"en\">")
	lines.append("<head>")
	lines.append("<meta charset=\"utf-8\">")
	lines.append("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
	lines.append("<title>ShipCheck Report</title>")
	lines.append("<style>")
	lines.append("body{font-family:Arial,sans-serif;margin:0;background:#0b1018;color:#e7edf5}main{max-width:1180px;margin:0 auto;padding:32px}h1{margin:0 0 8px}h2{margin-top:32px;border-bottom:1px solid #263244;padding-bottom:8px}.summary{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin:24px 0}.card{background:#121c2a;border:1px solid #263244;border-radius:8px;padding:14px}.card strong{font-size:24px}.issue{border-left:4px solid #888;background:#101824;margin:12px 0;padding:14px;border-radius:6px}.critical{border-color:#ff3333}.error{border-color:#ff7048}.warning{border-color:#ffd44d}.info{border-color:#9ec7ff}.known{opacity:.62}.badge{display:inline-block;font-weight:bold;margin-right:8px}.meta{color:#b7c4d7;font-size:13px}.detail{white-space:pre-wrap}.known-label{color:#95a3b8;font-size:12px;margin-left:6px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px}.pill{display:inline-block;background:#10291f;color:#38e8b6;border:1px solid #1d8f72;border-radius:999px;padding:4px 10px;margin:4px 6px 4px 0}a{color:#38e8b6}</style>")
	lines.append("</head>")
	lines.append("<body><main>")
	lines.append("<h1>ShipCheck Report</h1>")
	lines.append("<div class=\"meta\">Profile: %s</div>" % _escape_html(profile_name))
	lines.append("<div class=\"pill\">%s</div>" % _escape_html(get_release_status()))
	lines.append("<section class=\"summary\">")
	lines.append(_summary_card("Health", "%d/100" % get_score()))
	lines.append(_summary_card("Total", str(get_total_count())))
	lines.append(_summary_card("Blockers", str(get_blocker_count())))
	lines.append(_summary_card("Critical", str(get_count(ShipCheckIssue.Severity.CRITICAL))))
	lines.append(_summary_card("Errors", str(get_count(ShipCheckIssue.Severity.ERROR))))
	lines.append(_summary_card("Warnings", str(get_count(ShipCheckIssue.Severity.WARNING))))
	lines.append(_summary_card("Info", str(get_count(ShipCheckIssue.Severity.INFO))))
	if baseline != null:
		lines.append(_summary_card("Known", str(baseline.get_known_count(issues))))
		lines.append(_summary_card("New", str(baseline.get_new_issues(issues).size())))
		if baseline.has_method("get_stale_issue_ids"):
			lines.append(_summary_card("Stale baseline", str(baseline.get_stale_issue_ids(issues).size())))
	lines.append("</section>")

	lines.append("<h2>Score Breakdown</h2>")
	lines.append("<section class=\"grid\">")
	for key in get_score_breakdown().keys():
		lines.append(_summary_card(_humanize_key(key), str(int(get_score_breakdown()[key]))))
	lines.append("</section>")

	if issues.is_empty():
		lines.append("<p>No issues found.</p>")
	else:
		if get_blocker_count() > 0:
			lines.append("<h2>Release Blockers</h2>")
			for issue in issues:
				if issue.severity >= ShipCheckIssue.Severity.ERROR:
					lines.append(_issue_to_html(issue, baseline))

		lines.append("<h2>Findings By Category</h2>")
		var grouped := get_issues_by_category()
		for category in _sorted_keys(grouped):
			lines.append("<h2>%s</h2>" % _escape_html(category))
			for issue in grouped[category]:
				lines.append(_issue_to_html(issue, baseline))

	lines.append("</main></body></html>")
	return "\n".join(lines)


func _summary_card(label: String, value: String) -> String:
	return "<div class=\"card\"><div class=\"meta\">%s</div><strong>%s</strong></div>" % [_escape_html(label), _escape_html(value)]


func _issue_to_html(issue: ShipCheckIssue, baseline) -> String:
	var known: bool = baseline != null and baseline.is_issue_known(issue)
	var classes := "%s%s" % [_severity_class(issue.severity), " known" if known else ""]
	var location := issue.file_path
	if issue.line_number > 0:
		location += ":%d" % issue.line_number

	var parts: Array[String] = []
	parts.append("<article class=\"issue %s\">" % classes)
	parts.append("<div><span class=\"badge\">%s</span><strong>%s</strong>%s</div>" % [
		_escape_html(issue.get_severity_label()),
		_escape_html(issue.title),
		"<span class=\"known-label\">Known baseline issue</span>" if known else "",
	])
	if issue.scanner_name != "":
		parts.append("<div class=\"meta\">Scanner: %s</div>" % _escape_html(issue.scanner_name))
	if issue.rule_id != "":
		parts.append("<div class=\"meta\">Rule: %s</div>" % _escape_html(issue.get_rule_key()))
	if issue.category != "":
		parts.append("<div class=\"meta\">Category: %s</div>" % _escape_html(issue.category))
	if location != "":
		parts.append("<div class=\"meta\">Location: %s</div>" % _escape_html(location))
	if issue.message != "":
		parts.append("<p>%s</p>" % _escape_html(issue.message))
	if issue.why_this_matters != "":
		parts.append("<p><strong>Why this matters:</strong> %s</p>" % _escape_html(issue.why_this_matters))
	if issue.detail != "":
		parts.append("<div class=\"detail meta\">%s</div>" % _escape_html(issue.detail))
	if issue.fix_hint != "":
		parts.append("<p><strong>Suggested fix:</strong> %s</p>" % _escape_html(issue.fix_hint))
	if issue.ignore_hint != "":
		parts.append("<p><strong>When to ignore:</strong> %s</p>" % _escape_html(issue.ignore_hint))
	parts.append("</article>")
	return "\n".join(parts)


func _count_category(category: String) -> int:
	var total := 0
	for issue in issues:
		if issue.category == category:
			total += 1
	return total


func _count_categories(categories: PackedStringArray) -> int:
	var total := 0
	for issue in issues:
		if categories.has(issue.category):
			total += 1
	return total


func _sorted_keys(values: Dictionary) -> Array:
	var keys := values.keys()
	keys.sort()
	return keys


func _humanize_key(key: String) -> String:
	var parts := key.split("_", false)
	var words: Array[String] = []
	for part in parts:
		words.append(part.capitalize())
	return " ".join(words)


func _severity_class(severity: ShipCheckIssue.Severity) -> String:
	match severity:
		ShipCheckIssue.Severity.CRITICAL:
			return "critical"
		ShipCheckIssue.Severity.ERROR:
			return "error"
		ShipCheckIssue.Severity.WARNING:
			return "warning"
		_:
			return "info"


func _escape_html(value: String) -> String:
	return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")
