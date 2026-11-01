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

The classic board, special blocks, adventure starter path, local progression, feedback, and core navigation are implemented. Multiple additional modes, full 100-level/world content, AdMob, music tracks, notification scheduling, cosmetics/shop, and final art/animation polish remain future milestones.

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

## Batch 4 — Special blocks and effects

Implemented in the classic gameplay path:
- Weighted special-piece generation: 4% bomb, 4% rainbow, 4% lightning, 5% treasure; remaining rolls are normal pieces.
- Bomb clears the bounded 3×3 area around its placement origin.
- Rainbow clears the more occupied of the placement row or column (row wins ties), making its targeting deterministic without a modal interruption.
- Lightning clears the four-directionally connected occupied cluster from its placement origin.
- Treasure grants 25 local coins through the save manager without clearing board cells.
- Special pieces have distinct tray labels/colors and board target-flash feedback.
- Global touch/mouse drag tracking handles release outside the source tray control.

### Validation status

Special resolution and generation tests were added to the headless test runner. Source commits were retrieved from GitHub. The Godot runtime test workflow has not yet been observed completing, so runtime test status remains **NOT VERIFIED**. Effects are lightweight draw flashes rather than particle-based explosion/chain animations; those are visual polish work for a later batch.

## Custom board dimensions

- Default board: **5 × 5**.
- User-selectable sizes: **5 × 5 through 10 × 10**.
- Maximum board: **10 × 10**.
- The size control is in the Classic gameplay header.
- Selection is saved locally and used for new sessions.
- Changing size resets the current board and starts a fresh round.
- Placement validation, row/column clears, game-over checks, board rendering, snapshots, and special-block target bounds all use the active board dimension.
- Existing saves migrate to a default board size of 5; invalid stored values are clamped to 5–10.

## Batch 5 — Game flow and adventure screens

Implemented:
- In-game pause control and pause dialog with resume behavior.
- Improved round-over results showing final and best score, plus replay.
- First-launch tutorial covering placement, line clears, combos, and special blocks; completion is saved locally.
- Treasure reward popup after coin rewards are granted.
- Adventure world map with four world cards and unlock-state presentation.
- Level selection grid with 12 levels and locked/unlocked states.
- Level launch saves the selected level and activates adventure objective mode.
- Adventure gameplay tracks cleared lines against a level objective; completion unlocks the next level, grants a coin reward, and opens the victory dialog.
- Home-screen Adventure card now opens the world map directly.

### Validation status

The screen scripts and scene/router changes are committed and available in the repository. Godot runtime parsing, scene navigation, input behavior, and Android device layout have **not been executed or verified** in this session. The world map currently presents four themed world cards with the first world playable; world-specific progression and art assets remain future polish.

## Batch 6 — Gameplay polish, feedback and transitions

Implemented:
- Procedural lightweight sound effects generated at runtime for placement, invalid moves, line clears, combos, and treasure rewards; no imported audio files or paid sound packs are required.
- Android haptic feedback for placement, invalid moves, line clears, treasure, and level victory, respecting the saved vibration setting.
- Sound playback respects the saved sound setting.
- Placed-cell flash animation with a short tween.
- Existing line-clear and special-cell flashes retained and integrated with feedback sounds/haptics.
- Square board now centers itself inside the available gameplay area, improving fit across different portrait aspect ratios and board sizes.
- Scene navigation now uses a short fade transition overlay.

### Validation status

All changes are committed and source was retrieved from GitHub for inspection. No Godot runtime, Android device, audio output, or haptic device test was run in this session. Audio synthesis, Android vibration permissions/device behavior, fade transitions, and layout on small screens remain **NOT VERIFIED** until tested in Godot 4.4 and on a physical Android device.

## Batch 7 — Player progression and daily retention

Implemented:
- Version 3 local-save migration while preserving existing player data and settings.
- XP awards for block placement, line clears, completed rounds, missions, and achievements.
- Progressive level thresholds and 25-coin level-up rewards.
- Three daily missions: place 25 blocks, clear 5 lines, and play 2 rounds.
- Daily mission progress and claim state reset by the device's local calendar date.
- Five one-time achievements with coin rewards.
- Coin wallet with a recent 20-entry reward history.
- New progression screen showing level/XP, missions, achievements, and wallet history.
- Home screen missions, wallet, profile, and daily challenge shortcuts route to the progression hub.
- Interactive saved sound, music, vibration, and notification toggles.
- Gameplay events now update progression and mission progress.

### Batch 7 validation

GitHub Actions headless engine tests and Android export are being run against the current branch. The initial engine test run exposed legacy test references to the removed fixed board-size constant; those tests have been updated to use the dynamic board dimensions. Do not mark the latest run passed until its final GitHub Actions result is successful.

## Android cloud build

- Added an Android export preset for com.dev.blockverse (ARM64).
- Added a push-triggered GitHub Actions workflow that exports a debug APK and uploads it as the BLOCKVERSE-Android-APK artifact.
- The APK can be downloaded from the successful workflow run's Artifacts section.
- This is a debug APK for device testing, not a signed Play Store release. A production release requires your own signing keystore and credentials.

## Remaining release work

- Implement and validate Daily Challenge, Zen, Combo Rush, and Time Attack as distinct playable modes.
- Expand Adventure beyond the current first-world/12-level starter path and complete all world-specific content.
- Implement a real cosmetic shop/inventory and player profile editing.
- Integrate and test AdMob with consent and Android app IDs before enabling ads.
- Add music, notification scheduling, more complete screen coverage, and production art.
- Run full Android device testing (touch layouts, lifecycle, sound, vibration, save migration, performance) and prepare a signed release build.
