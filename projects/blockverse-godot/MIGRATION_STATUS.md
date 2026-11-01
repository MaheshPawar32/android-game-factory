# BLOCKVERSE migration status

## Source backup
Original Unity project: `projects/blockverse-unity/` (preserved; no Unity files changed).

## Godot copy
New project: `projects/blockverse-godot/`

## Implemented gameplay batches

### Batch 1 — playable board foundation
- Godot 4.x portrait project, runtime UI, 8×8 board and three-piece tray.
- Tap-to-select/tap-to-place, placement validation, row/column clearing and score.

### Batch 2 — special pieces and obstacles
- Bomb, Rainbow and Lightning special pieces.
- Stone and two-hit Ice obstacles; specials and line clears can damage them.

### Batch 3 — objectives, moves and boss stages
- Level-based line-clear objectives with a move limit.
- Every fifth level is a boss stage requiring all obstacles to be cleared.
- Win bonus, retry and next-level button flow.

## Earlier migration notes

### First migration batch
- Godot project metadata and portrait viewport.
- Main scene and runtime-created UI.
- 8×8 board model.
- Three-piece tray and tap-to-select/tap-to-place controls.
- Invalid placement checks.
- Full row and column clearing.
- Basic score counter and new-game reset.

## Not yet migrated
Persistent level/score saving; daily rewards; shop and themes; daily missions; achievements; pause; revive; undo; audio; haptics; drag-and-drop controls.

## Validation
Files have been committed only. Open/import in Godot Android Editor and test on device before treating this batch as passing. APK/AAB export has not been performed.
