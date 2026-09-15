# ShipCheck Lite

ShipCheck Lite is a free Godot 4 editor addon for quick pre-export health checks. It helps catch common project mistakes before you export, share a jam build, or upload a release.

Lite runs inside the Godot editor and does not delete or rewrite project files.

Verified with Godot `4.7.stable.official`.

## 1.0 Features

- Editor dock with preset descriptions, release status, score breakdown, severity filters, search, and grouped results
- Scan presets: `Lite Default` and `Lite Loose`
- Markdown report export
- Project-level config through `res://shipcheck_config.cfg`
- Ignore rules by issue, file, path pattern, scanner, and inline directives
- Issue details with problem, why it matters, suggested fix, and when to ignore guidance
- Script issues open at the reported line when possible

## Lite Scanners

- Missing script references
- Broken `res://` resource references
- Case-sensitive path mismatches
- Project settings, main scene, icon, and autoload problems
- InputMap actions used in code but missing from Project Settings
- Debug leftovers like prints, errors, breakpoints, TODOs, and FIXMEs
- Missing export presets and blank export paths
- Oversized assets based on configurable limits
- Basic release risks such as `.env`, secret-looking strings, `.gdignore` traps, plain HTTP URLs, and VCS gaps

## Scan Presets

- `Lite Default`: core free pre-export scan for common release risks.
- `Lite Loose`: lower-noise scan for early projects. It skips debug leftovers and large asset warnings.

## Install

1. Copy `addons/shipcheck` into your Godot project.
2. Open the project in Godot 4.
3. Go to `Project > Project Settings > Plugins`.
4. Enable `ShipCheck Lite`.
5. Open the ShipCheck dock and run a scan.

## Config And Ignores

Click `Open Config` to create `res://shipcheck_config.cfg` from the commented defaults in `res://addons/shipcheck/shipcheck_defaults.cfg`.

Click `Ignore Issue` or `Ignore File` from the dock to update `res://shipcheck_ignore.cfg`. You can also add inline directives such as `# shipcheck: ignore`, `# shipcheck: ignore-next-line`, `# shipcheck: ignore-file`, `# shipcheck: ignore-start`, and `# shipcheck: ignore-end`.

Lite ignores `res://addons/` by default so third-party addons do not drown out your project issues. Turn on `include_addons=true` in `res://shipcheck_config.cfg` if you intentionally want to scan addon code.

## Pro

ShipCheck Pro adds CLI/headless scans, CI-style fail modes, baselines, new-issue comparison, JSON/HTML reports, advanced GDScript checks, scene connection checks, stale UID checks, asset hygiene checks, performance hot-path checks, and a bundled example HTML report.

Pro repo: [Dragon-Scar-Studio/ShipCheck-Pro](https://github.com/Dragon-Scar-Studio/ShipCheck-Pro)

Pro on itch: [ShipCheck Pro for Godot](https://dragonscarstudio.itch.io/shipcheck-for-godot)

## License

ShipCheck Lite is proprietary software owned by Dragon Scar Studio, LLC. You may use and modify it for your own personal, educational, internal business, or game development projects. You may not redistribute, resell, repackage, upload, or claim ShipCheck Lite as your own product. See `LICENSE`.
