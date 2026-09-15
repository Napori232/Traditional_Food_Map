# Ignore Rules

ShipCheck always applies built-in ignores before project ignores:

- `res://addons/`, unless `include_addons=true`
- `res://.godot/`
- generated ShipCheck reports
- `shipcheck_ignore.cfg`
- `shipcheck_config.cfg`

Project ignores live in `res://shipcheck_ignore.cfg`.

Inline directives are supported in `.gd` files:

```gdscript
print("debug") # shipcheck: ignore-line debug_code.debug_print_found
# shipcheck: ignore-next-line debug_code.todo_found
# TODO: old note I am keeping for now
# shipcheck: ignore-file debug_code
# shipcheck: ignore-start debug_code
# shipcheck: ignore-end debug_code
```

Use scanner IDs, rule IDs, or full rule keys such as `debug_code.debug_print_found`.
