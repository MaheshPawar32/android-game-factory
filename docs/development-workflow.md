# Unity browser-first development workflow

## 1. Project location

The active game project is `projects/blockverse-unity`. It uses Unity 6 and C#.

You can edit scripts and configuration in GitHub or Codespaces. The Unity Editor is still needed for visual scene editing, Play Mode testing, importing assets, and final device testing.

## 2. Generate the starter scene

1. Open `projects/blockverse-unity` in Unity 6.0.60f1.
2. Wait for package import and script compilation.
3. Select **BLOCKVERSE → Setup Starter Scene** from the editor menu.
4. Open `Assets/Scenes/Game.unity` and press Play.

The starter scene generator creates a basic canvas, score/level labels, board container, and restart button. It is a foundation, not the completed game.

## 3. Android settings

In Unity:
- Install Android Build Support, Android SDK & NDK Tools, and OpenJDK through Unity Hub.
- Set the package identifier to `com.dev.blockverse`.
- Set orientation to Portrait.
- Configure app icon, version, permissions, and scripting backend before release.
- Use a private keystore for production signing; never commit it.

## 4. GitHub cloud builds

The workflow is **Actions → BLOCKVERSE Unity Android**. It builds the Unity project at `projects/blockverse-unity` for Android and uploads available outputs as an artifact.

Required repository secrets:
- `UNITY_LICENSE`: Unity serial or license activation content supported by GameCI.
- `UNITY_EMAIL`: Unity account email.
- `UNITY_PASSWORD`: Unity account password.

Keep these values in GitHub Actions secrets, not in project files. The first build may fail until a valid license and Android module compatibility are configured.

## 5. Validation

Before publishing:
- Open the project in the exact Unity editor version in `ProjectSettings/ProjectVersion.txt`.
- Resolve all compiler errors.
- Run EditMode/PlayMode tests.
- Build and test on a physical Android device.
- Configure release signing and verify the AAB in Google Play Console.
