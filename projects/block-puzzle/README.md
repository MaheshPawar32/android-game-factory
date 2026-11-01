# BLOCKVERSE — Godot Android Game

**Tagline:** PLACE. CLEAR. COMBO. CONQUER.

BLOCKVERSE is a portrait-first, offline block puzzle game built with **Godot 4.4 and GDScript**. Flutter is not used.

## Project configuration

- Platform: Android
- Engine: Godot 4.4.x
- Language: GDScript
- Package ID target: `com.dev.blockverse`
- Rendering: Compatibility (mobile-friendly baseline)
- Orientation: Portrait
- Save system: Local versioned ConfigFile (`user://blockverse_save.cfg`)
- No login or backend required

## Open the project

Open `projects/block-puzzle/project.godot` in Godot 4.4.x.

## Current foundation (Batch 1)

- BLOCKVERSE app identity and portrait project settings.
- Premium dark theme tokens based on the supplied 25-screen storyboard.
- Home screen and mode-selection navigation.
- Classic mode opens the existing playable 10×10 prototype.
- Local save layer with defaults, settings, coins, player progression placeholders, and schema version.
- Central scene router.

## Current implementation status

The classic board is an early prototype. The other modes, 100 levels, special blocks, drag-and-drop, progression, ads, audio, notifications, and full screen set are not yet implemented. Buttons for later features are explicitly marked as planned rather than pretending those features are complete.

## Next milestones

1. Core game engine extracted into testable GDScript models.
2. Accurate drag-and-drop and board interaction.
3. Special blocks, scoring, combos, and effects.
4. Game flow screens and six modes.
5. Adventure progression, missions, achievements, inventory, and themes.
6. Audio, haptics, notifications, and optional AdMob integration.
7. Android export, performance testing, and release validation.

## Android export

Set the Android package identifier to `com.dev.blockverse` in the Godot Android export preset. Configure the Android SDK and matching Godot export templates before building.

## Batch 2 — Core engine foundation

Added pure GDScript engine modules:
- `scripts/engine/board_model.gd`: 10×10 board, bounds and overlap validation, placement, simultaneous row/column clearing, snapshots, and move availability.
- `scripts/engine/piece_definitions.gd`: centralized normalized shape catalog.
- `scripts/engine/piece_generator.gd`: seeded deterministic piece generation and tray creation.
- `scripts/engine/scoring_rules.gd`: placement points, line bonuses, and capped combo multiplier.
- `scripts/engine/special_block_resolver.gd`: bounded bomb area, rainbow line targeting, orthogonal lightning cluster, and treasure reward calculation.
- `tests/run_engine_tests.gd`: dependency-free headless test runner covering core rules.

### Run engine tests

From the repository root with Godot 4.4 installed:

```bash
godot --headless --path projects/block-puzzle --script res://tests/run_engine_tests.gd
```

The test runner is committed but has not yet been executed in a Godot runtime. Do not treat the tests as passing until a real Godot run reports success. Special block functions currently calculate deterministic targets/results; visual effects and full gameplay activation are a later integration milestone.

## Batch 3 — Drag-and-drop gameplay integration

Implemented:
- Custom-drawn 10×10 board view with responsive cell sizing.
- Drag start from each available tray piece.
- Pointer tracking and board-cell preview while dragging.
- Valid placement preview and invalid placement feedback.
- Touch and mouse release handling.
- Integration with the pure board model, seeded piece generator, and scoring rules.
- Simultaneous line-clear feedback flash.
- Score/best/combo HUD refresh and game-over dialog.
- Best score persistence through the local SaveData autoload.

### Validation status

Source files were committed and retrieved from GitHub after commit. A Godot executable was not available in this GitHub connector session, so runtime parsing, touch-device testing, and frame-rate profiling are **not yet verified**. Run the committed Godot headless test workflow and open the project on an Android device before marking this batch fully passed.

### Known next improvements

- Drag pointer offset calibration on physical Android touchscreens.
- More polished piece preview positioning and animated placement.
- Line-clear particle effects and score popups.
- Persist and restore full in-progress board sessions.
