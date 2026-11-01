# BLOCKVERSE migration status

## Source backup
Original Unity project: `projects/blockverse-unity/` (preserved; no Unity files changed).

## Godot copy
New project: `projects/blockverse-godot/`

## First migration batch
- Godot project metadata and portrait viewport.
- Main scene and runtime-created UI.
- 8×8 board model.
- Three-piece tray and tap-to-select/tap-to-place controls.
- Invalid placement checks.
- Full row and column clearing.
- Basic score counter and new-game reset.

## Not yet migrated
Bomb/Rainbow/Lightning special pieces; stone/ice obstacles; objectives and boss levels; level unlocks; daily rewards; shop and themes; daily missions; achievements; pause; revive; undo; audio; haptics; save persistence.

## Validation
Files have been committed only. Open/import in Godot Android Editor and test on device before treating this batch as passing. APK/AAB export has not been performed.
