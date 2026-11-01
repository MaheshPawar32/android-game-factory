# BLOCKVERSE — Unity Edition

- Engine: Unity 6.0.60f1
- Language: C#
- Target: Android
- Package: `com.dev.blockverse`
- Orientation: Portrait

## Implemented gameplay
- 8×8 starting grid with touch drag-and-drop and three-piece tray.
- Special pieces: Bomb damages a 3×3 area, Rainbow damages a row, and Lightning damages a column.
- Stone breaks in one hit; ice requires two hits.
- Simultaneous row/column clearing, score calculation and consecutive-clear combo bonuses.
- Board rendering safely ignores non-cell visual effects when mapping model cells.
- Best score and coins persist locally with PlayerPrefs.
- Level objectives: clear a line target, reach a score target, clear lines within a move limit, and boss levels that require clearing all obstacles.
- Successful levels unlock the next level, award bonus coins, and save a three-star completion record.
- Failure overlay appears when the move limit is reached or no remaining piece can be placed.
- Runtime win/fail overlay provides Next Level or Retry actions.
- Animated board pulse and special-block burst particles.
- Procedurally generated placement, clear, bomb, win, and fail sound effects (no external audio assets required).
- Persistent in-game sound toggle saved locally.
- Main menu with Play, Level Select, Daily Reward and Settings.
- 20-level selection grid with locked/unlocked progression.
- Daily login reward with a seven-day streak cycle, claimed once per local calendar day.
- Persistent vibration preference and haptic feedback on successful placements.
- Coin shop with four block-and-board color themes, permanent unlocks and equip selection.
- Deterministic obstacles and procedural level configuration.
- Editor setup menu creates the starter scene and configures Android identity/build scene.

## Create and play
1. Open this folder in Unity 6.0.60f1.
2. Wait for package import and C# compilation.
3. Choose **BLOCKVERSE → Setup Starter Scene**.
4. Open `Assets/Scenes/Game.unity` and press Play.
5. Drag pieces onto the board. Special colors: red = Bomb, purple = Rainbow, yellow = Lightning.

This remains an early prototype. The UI is generated at runtime using Unity UGUI; polished art, transitions, background music, missions, and release-ready balancing remain future work.

## Android build
Use the **BLOCKVERSE Unity Android** workflow after configuring Unity licensing secrets in GitHub. Validate compilation, gameplay, and touch interactions on a physical Android device before release.