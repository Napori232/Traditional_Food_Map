---
name: godot-project-conventions
description: Create, edit, or refactor Godot game code and scenes using this project's global reuse, data-scene-UI layering, signal communication, function-naming, and component-design conventions. Use for gameplay, UI, scene, data, and GDScript work in this project.
---

# Godot Project Conventions

Apply these conventions when creating, editing, or refactoring project-owned Godot
scenes and GDScript. Do not impose them on third-party code under `addons/`.

## Inspect Before Editing

Before implementation:

1. Inspect the project structure and the files related to the requested feature.
2. Look for a project-owned `global/` folder and inspect its relevant scripts.
3. Check `project.godot` for autoloads that expose global state, constants, services,
   or signals.
4. Reuse existing project conventions when they are more specific than this skill.

Do not create duplicate constants, signals, services, or components before checking
whether an equivalent project-owned implementation already exists.

## Global Reuse

- Inspect the project's `global/` folder and autoloads before adding shared values or
  cross-system communication.
- If an existing global constant or signal has the same meaning, prefer it over a
  duplicate local definition.
- If no suitable global value exists, keep the value local to the feature. Do not
  create a global variable merely to avoid repeating a small local value.
- Add a global constant only when it is stable, genuinely shared, and has clear
  project-wide meaning.
- Add a global signal only when the event crosses independent systems and a global
  signal is already the project's established communication pattern. Local signals
  are preferred for component-owned events.
- Feature data, temporary UI state, and component-specific values should remain in
  the owning feature unless multiple systems truly need the same data.
- Never use global state as a shortcut for a direct component dependency.

## Feature Architecture

For features with meaningful data, runtime scenes, and interface, organize the
project into three explicit layers:

- **Data layer:** Owns domain data, data loading, filtering/query logic, and
  persistent or session state. Store records such as shops, items, coordinates,
  favorites, blocks, and comments here. Do not duplicate domain records in UI or
  scene scripts.
- **Scene layer:** Owns the runtime world and visual scene behavior. A map belongs
  here. Keep the map background/world in a dedicated scene and generate repeated
  runtime nodes, such as shop markers, from data supplied by the data layer.
- **UI layer:** Owns presentation and user interaction, split into focused
  components such as search, category filters, detail panels, and notifications.
  UI reads data and emits user intent; it should not own the domain model.

The entry scene or coordinator should primarily assemble these layers, connect their
signals, and pass data between them. It should not become the store for all data,
the complete map renderer, or the implementation of every UI control.

Split a feature further when a part has its own state, visual lifecycle, interaction
contract, or plausible reuse. Keep tiny one-off pieces local when extracting them
would only add indirection.

## Scene Layers

Separate runtime scenes into:

- **Game scene layer:** The world and gameplay content that runs as part of the
  game, including maps, players, enemies, interactables, simulation, and gameplay
  systems.
- **UI layer:** Interface presented above gameplay, including HUD, menus, dialogs,
  overlays, prompts, notifications, search, filters, and detail panels.

Keep UI independent from gameplay scene internals:

- UI should observe gameplay through stable public APIs, local signals, shared state
  services, or global signals when the project already uses them.
- Gameplay code should not search deeply through UI node paths or manipulate UI
  implementation details.
- Use `CanvasLayer` or the project's equivalent UI root when UI must remain visually
  above the game scene.
- Reusable UI elements should be their own scenes when they have independent
  behavior, state, styling, or repeated use.

For map-like features:

- Keep the whole map/background in one dedicated map scene.
- Keep one marker/node script responsible for one shop or map item.
- Let the map instantiate, position, refresh, and remove marker nodes from data.
- Do not put the full shop dataset or detail-panel construction inside the map.
- Do not make the coordinator reach through deep node paths to mutate markers or UI.

## GDScript Function Naming

Use PascalCase for functions intentionally exposed to callers outside the script:

```gdscript
## Starts the interaction for the given actor.
func UseInteraction(actor: Node) -> void:
    _validate_actor(actor)
    _start_interaction(actor)
```

Public functions must have a concise `##` documentation comment that explains their
external contract. Document important parameters, return meaning, side effects, and
preconditions when they are not obvious.

Use a leading underscore and snake_case for functions used only inside the script:

```gdscript
func _validate_actor(actor: Node) -> void:
    pass


func _start_interaction(actor: Node) -> void:
    pass
```

Godot lifecycle callbacks and engine virtual methods keep their required Godot names,
such as `_ready`, `_process`, `_physics_process`, and `_input`.

Do not expose a function only because another script can technically call it. Treat a
function as public only when it is part of the component's intended external API.

## Component Design

- Give each component one clear responsibility.
- Prefer composition of focused scenes, nodes, resources, and scripts over one large
  script controlling unrelated behavior.
- Extract the smallest useful reusable component when behavior has independent
  state, can be tested or reasoned about separately, or is used in more than one
  place.
- Keep component ownership explicit. A parent may coordinate child components, but
  it should not duplicate their internal logic.
- Expose a small public API and keep implementation details private.
- Connect components through direct references for close parent-child ownership and
  through signals for events or looser coupling.
- Do not split trivial one-off behavior into extra files when extraction would add
  indirection without meaningful reuse or separation.

## Completion Check

Before finishing:

1. Confirm relevant global constants and signals were considered and reused where
   semantically correct.
2. Confirm meaningful features have clear Data, Scene, and UI ownership.
3. Confirm repeated scene elements are generated from Data rather than duplicated.
4. Confirm the coordinator only assembles layers and routes signals.
5. Confirm externally callable functions use PascalCase and have `##` documentation.
6. Confirm local helper functions use leading-underscore snake_case.
7. Confirm components are focused without unnecessary fragmentation.
8. Run the most relevant Godot validation, scene load, or project test available.
