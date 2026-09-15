# Known Limitations

ShipCheck is static analysis. It does not replace playtesting.

Known limits:

- Dynamic paths built through string concatenation cannot always be proven safely.
- Dynamic InputMap usage may need manual review.
- Style rules are partly subjective, especially in Strict/Full presets.
- C# scanning is not implemented yet.
- Binary `.res` files are not deeply scanned in this version.
- UID checks depend on Godot's ResourceUID cache being available, so run the editor import step on fresh checkouts before CI scans.
- Addons are ignored by default to reduce noise; set `include_addons=true` when intentionally auditing third-party addon code.
