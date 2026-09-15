# Changelog

## 1.0.0 - Stable Lite Release

ShipCheck Lite 1.0 turns the free edition into a complete editor-side pre-export check for Godot 4 projects.

### Added

- Added Lite Default and Lite Loose scan presets with in-editor descriptions.
- Added scanner and preset descriptions so users can see what each scan type is meant to catch.
- Added release status and score breakdown summaries in the editor dock.
- Added grouped results by release blockers, category, severity, scanner, and file.
- Added issue detail guidance for why each finding matters and when it is reasonable to ignore.
- Added ignore-by-file from the editor dock.
- Added richer issue metadata for categories, ignore guidance, and report summaries.

### Changed

- Improved Markdown reports with category summaries, blocker summaries, and score breakdowns.
- Improved the editor dock layout around scan presets, filters, grouping, search, and issue details.
- Wrapped the dock UI in a scroll container so ShipCheck no longer forces Godot's bottom panels to collapse on startup.
- Updated scan completion feedback so the details panel no longer stays on "Scanning..." after a scan finishes.
- Changed ignore-file loading so existing `shipcheck_ignore.cfg` path entries are respected instead of silently re-adding removed defaults.
- Improved Lite docs so the free edition explains exactly what it does and how it differs from Pro.

### Packaging

- Fixed `plugin.cfg` encoding so Godot can read ShipCheck Lite in Project Settings > Plugins.
- Updated docs and packaged README content for 1.0.
- Kept README, LICENSE, and CHANGELOG inside `addons/shipcheck` for asset-store packaging.
- Rebuilt the release zip without repository metadata, fixtures, temp files, or test-only content.

## 0.10.0 - Lite/Pro Split

- Added Lite/Pro edition foundation.
- Added shared scanner registry used by the dock.
- Added scanner metadata for edition, category, defaults, and descriptions.
- Added stable issue IDs with legacy ID compatibility for existing ignores.
- Added ShipCheck inline ignore directives for `.gd` files.
- Fixed first-scan ignore consistency by applying built-in defaults even before `shipcheck_ignore.cfg` exists.
- Added `include_addons=false` default so third-party addons are not scanned unless requested.
- Fixed Broken Resource false positives from pure GDScript comments/doc comments.
- Hardened `res://` extraction around BBCode/Markdown wrappers and trailing punctuation.
- Improved scan status timing and disabled scan buttons while a scan is running.
- Kept casing mismatches owned by the Case-Sensitive Path scanner rather than double-counting as broken resources.

## 0.9.2

- Fixed Linux/Windows casing double-count behavior in Broken Resource scanner.
- Improved fixture determinism.

## 0.9.1

- Added hidden-file release-risk coverage for `.env` and `.gdignore`.
- Added CI pre-import guidance.
