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
