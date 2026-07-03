# CLAUDE.md

Guidance for AI assistants (and humans) working in this repository.

## Project

- **Name:** QuackAttack
- **Purpose:** A mobile, top-down, 2D indie game. You play a duck flying around a
  city hunting for park ponds where old people throw bread. Eating scores points
  **but adds weight**; weight slows you down. Shed weight (metabolism while
  flying, an active offload, or a temporary speed upgrade) to keep flying — get
  too fat and you're grounded, ending the run.
- **Engine:** [Godot](https://godotengine.org) **4.4+**, GDScript. Mobile
  renderer, portrait orientation, iOS/Android export target.
- **Status:** Early development. Core game-state loop and duck flight exist;
  world, food/collection, fail loop, upgrades, and hazards are in progress.

## Core gameplay loop

```
eat food ─► score up AND weight up ─► weight slows the duck
   ▲                                        │
   └──── stay flyable ◄── shed weight ◄─────┘
         (metabolism while flying / offload / temporary upgrade)

   too fat (weight ≥ MAX_WEIGHT) ─► grounded ─► run ends
```

The economy is deliberately tuned so you can't idle to slim down: metabolism is
slow, offload costs score (you're throwing away food), and speed upgrades are
temporary. All tuning lives as constants in `autoload/game_state.gd`.

## Repository structure

```
QuackAttack/
├── project.godot              # engine config: Mobile renderer, portrait, autoloads
├── icon.svg                   # app/window icon (placeholder duck)
├── autoload/                  # singletons (registered in project.godot [autoload])
│   ├── events.gd              # Events — global signal bus
│   └── game_state.gd          # GameState — score, weight/speed, upgrades, save
├── scenes/
│   ├── main.tscn              # root scene (run/main_scene): Duck + UI layer
│   ├── duck/duck.tscn         # player duck: body, beak Area2D, child Camera2D
│   ├── ui/virtual_joystick.tscn
│   ├── world/                 # (M2) city + pond
│   ├── pond/                  # (M3) pond + feeder NPCs + food spawner
│   └── food/                  # (M3) collectible food
├── scripts/                   # scripts not co-located with a single scene
│   ├── duck.gd
│   └── virtual_joystick.gd
└── assets/                    # sprites/ audio/ fonts/ (placeholder art for now)
```

## Architecture

- **Autoload singletons** (see `project.godot` `[autoload]`):
  - **`Events`** (`autoload/events.gd`) — a global **signal bus**. Systems emit
    and listen through it instead of holding direct references. Signals:
    `food_collected`, `score_changed`, `weight_changed`, `duck_grounded`,
    `session_started`, `session_ended`, `upgrade_activated`, `upgrade_expired`.
    Each has a typed `emit_*` helper.
  - **`GameState`** (`autoload/game_state.gd`) — authoritative game state: score,
    high score, `weight`, `speed_multiplier()`, `offload()`, `apply_upgrade()`,
    session lifecycle, and persistence to `user://save.cfg`. It reacts to
    `Events.food_collected`; `_set_weight()` is the single choke point that
    clamps weight, emits `weight_changed`, and triggers grounding at `MAX_WEIGHT`.
- **Decoupling rule:** prefer routing cross-node communication through `Events`
  rather than node paths or hard references. The duck, for example, finds the
  joystick via the `virtual_joystick` group, not a fixed path.
- **The duck** reads `GameState.speed_multiplier()` each physics frame and sets
  `GameState.is_flying`; it does not own score/weight logic.

## Development workflow

### Setup

- Install **Godot 4.4+** (standard/GDScript build — no Mono/C# needed).
- Open the project: `godot --editor --path .` (or open `project.godot` in the
  Godot project manager).

### Common commands

- **Run the game:** open in the editor and press **F5**, or headless-less:
  `godot --path . scenes/main.tscn`
- **Parse/import smoke check (CI-friendly):** `godot --headless --path . --quit`
  — surfaces script parse errors and import issues without a display.
- **Export (later, once presets exist):**
  `godot --headless --path . --export-debug "Android" build/quackattack.apk`

> There is no separate build/lint step: GDScript is parsed by the engine. Treat a
> clean `--headless --quit` (no script errors) as the baseline check.

### Playtesting the current build

- **Move:** drag anywhere (floating virtual joystick) on touch; **arrow keys /
  WASD** in the editor (mouse emulates touch, so the joystick also works with a
  mouse).
- **Offload:** **Space** on desktop (the on-screen button lands with the M3 HUD).

## Conventions

- **Language:** typed GDScript. Annotate vars, params, and returns
  (`func speed_multiplier() -> float:`); use `:=` inference where the type is
  obvious.
- **Files:** `snake_case.gd` / `snake_case.tscn`. **Nodes:** `PascalCase`.
- **Scripts:** one script per scene; give player-facing/reused scripts a
  `class_name` (e.g. `Duck`, `VirtualJoystick`).
- **Signals:** name in past tense (`food_collected`, `session_ended`); go through
  the `Events` bus for anything cross-system.
- **Tuning:** gameplay constants live as named `const`s at the top of the owning
  script (mostly `game_state.gd`), commented as provisional until balanced.
- **Indentation:** tabs (Godot default).
- **Commits:** imperative subject, milestone-prefixed where it applies
  (e.g. `M1: duck flight, virtual joystick, follow camera`).

## Roadmap

`M0 scaffold ✓ → M1 duck flight ✓ → M2 city + pond → M3 food + collection +
weight → M4 fail-when-too-fat + high-score save → M5 in-run upgrades
(rideable/propulsion/drone) → M6 hazards (catch chance scales with fatness) →
M7 polish.` Future/out of scope: persistent meta-progression, open-world
objectives, multiplayer, monetization, endless mode.

## Notes for AI assistants

- This file is the source of truth for project conventions. Keep it current: when
  you learn something durable about how the codebase works, update it here.
- **No Godot in some CI/sandbox environments** — you may not be able to run the
  engine to verify. When that's the case, author valid Godot 4 files carefully
  and say so; the human should open the project locally to playtest.
- Match the style and idioms of the surrounding code and prefer reusing the
  `Events` bus and `GameState` API over adding parallel mechanisms.
