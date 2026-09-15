# Rule Reference

Each issue includes:

- `scanner_id`
- `rule_id`
- `scanner_id.rule_id`
- severity
- file path and line when available
- detail/evidence
- suggested fix
- stable ID

Lite scanners:

- `missing_script`
- `broken_resource`
- `case_sensitive_path`
- `project_settings`
- `input_map`
- `debug_code`
- `export_preset`
- `large_asset`
- `release_risk`

Rule IDs are generated from rule titles unless a scanner supplies a more specific ID. Use the issue detail panel or Markdown report to copy the exact rule key.
