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

### Batch 4 — local economy and cosmetics
- Local player save file using Godot `ConfigFile` in `user://`.
- Best score, coin balance, selected theme and daily claim date are saved.
- Daily reward grants 100 coins once per device-local calendar day.
- Three palette themes; the first is free and the next themes cost 150 coins each.
- Clearing lines awards 5 coins per cleared row/column.

## Not yet migrated
Persistent level/board state; full shop inventory and owned-theme catalogue; daily missions; achievements; pause; revive; undo; audio; haptics; drag-and-drop controls.

## Validation
Files have been committed only. Open/import in Godot Android Editor and test on device before treating this batch as passing. APK/AAB export has not been performed.
