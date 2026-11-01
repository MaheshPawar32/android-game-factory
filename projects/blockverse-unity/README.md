# BLOCKVERSE — Unity Edition

- Engine: Unity 6.0.60f1
- Language: C#
- Target: Android
- Package: `com.dev.blockverse`
- Orientation: Portrait

## Implemented foundation
- Grid board with touch drag-and-drop placement and three-piece tray.
- Special pieces: Bomb damages a 3×3 area, Rainbow damages a row, and Lightning damages a column.
- Special pieces appear occasionally and use distinct colors in the tray.
- Stone breaks in one hit; ice requires two hits from line clears or special effects.
- Simultaneous row/column clearing and score calculation.
- Best score and coins persist locally with PlayerPrefs.
- Deterministic obstacles and procedural level configuration.
- Editor setup menu creates the starter scene and configures Android identity/build scene.

## Create and play
1. Open this folder in Unity 6.0.60f1.
2. Wait for package import and C# compilation.
3. Choose **BLOCKVERSE → Setup Starter Scene**.
4. Open `Assets/Scenes/Game.unity` and press Play.
5. Drag pieces onto the board. Special colors: red = Bomb, purple = Rainbow, yellow = Lightning.

This is still an early playable prototype. Objective completion, win/game-over screens, polished animations/audio, missions, shop, and release-ready UI remain future work.

## Android build
Use the **BLOCKVERSE Unity Android** workflow after configuring Unity licensing secrets in GitHub. Validate on a physical Android device before release.