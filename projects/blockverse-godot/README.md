# BLOCKVERSE — Godot phone-first migration

This is a **separate migration copy**. The original Unity project remains untouched at `projects/blockverse-unity/` for a future return to Unity.

## Target
- Engine: Godot 4.x
- Language: GDScript
- Platform: Android
- Orientation: Portrait

## Phone-only workflow
1. Install Godot Android Editor from https://godotengine.org/download/android/
2. Open this project folder in the Android editor.
3. Follow the official GABE setup instructions: https://godotengine.org/article/gabe-stable-release/
4. Run the project on the phone and export a test APK.
5. Keep the project in GitHub as the source-of-truth backup.

## Migration status
- [x] Separate Godot project scaffold.
- [x] Portrait project configuration.
- [x] Initial 8×8 board, piece selection, placement, and row/column clear prototype.
- [x] Special pieces (Bomb, Rainbow, Lightning) and Stone/Ice obstacles.
- [x] Level line objectives, move limits, every-fifth-level boss objective, win/retry/next-level flow.
- [x] Local save for best score, coins, selected theme and daily reward claim date.
- [x] Daily 100-coin reward and basic 3-theme palette shop.
- [ ] Persistent level/board progression, full shop inventory, missions, achievements, pause, revive, undo, audio, haptics and drag-and-drop.
- [ ] Android Editor import and runtime validation.
- [ ] GABE setup and APK export verification.

The current GDScript is an initial migration foundation, not a complete replacement for the Unity game. Do not delete or overwrite the Unity project. No APK has been built or tested yet.
