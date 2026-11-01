# BLOCKVERSE — Unity Edition

- Engine: Unity 6.0.60f1
- Language: C#
- Target: Android
- Package: `com.dev.blockverse`
- Orientation: Portrait

## Implemented foundation

- Grid board model with validated block placement.
- Touch/pointer drag-and-drop piece tray with three pieces per turn.
- Full row and column clearing, including simultaneous line handling.
- Stone obstacles and two-hit ice obstacles.
- Deterministic obstacle placement based on the level seed.
- Procedural level configuration with regular, move-limited, score-trial, and boss goal types.
- Starter piece shape library.
- Score and status feedback.
- Editor menu command that creates the starter scene and configures Android identity and build scene.

## Create and play the starter scene

1. Open this folder in Unity 6.0.60f1.
2. Wait for package import and C# compilation.
3. Choose **BLOCKVERSE → Setup Starter Scene** from the Unity menu.
4. Open `Assets/Scenes/Game.unity` and press Play.
5. Drag one of the three pieces from the tray onto the board. Invalid placements return the piece to its tray slot.

The current playable foundation is an early prototype. Full progression, objectives, special blocks, missions, shop, persistence, polished animation/audio, and release-ready UI are still to be implemented.

## Android build

Use the repository workflow **BLOCKVERSE Unity Android** after adding the Unity licensing secrets described in the repository README. Test the resulting build on a physical Android device before release.
