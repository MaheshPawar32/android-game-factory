# Block Puzzle — MVP

A portrait-first Godot 4 puzzle game prototype.

## Current gameplay
- 10 × 10 placement grid.
- Three shape choices per round.
- Select a shape, then tap a board cell to place it.
- Complete full rows and columns to clear them.
- Score, combo multiplier, best score for the current app session, and game-over detection.
- Restart button.

## Open in Godot
Open this folder in Godot 4.4.x:
`projects/block-puzzle/project.godot`

## Current limitations
This is the first playable prototype. It uses tap-to-select and tap-to-place rather than drag-and-drop. Best score is currently session-only. Audio, haptics, persistence, tutorial, progression, special blocks, daily challenges, monetization, and release signing are planned for later milestones.

## Android export
Create an Android export preset named `Android` in Godot and configure the SDK/export templates for the matching Godot version. The repository workflow can then be run with:
- project_path: `projects/block-puzzle`
- export_preset: `Android`
