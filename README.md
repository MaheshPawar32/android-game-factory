# Android Game Factory

Browser-first development workspace for Android games built with **Unity 6 and C#**.

## Current game

- **BLOCKVERSE** — mobile block puzzle game
- Engine: Unity 6
- Language: C#
- Platform: Android
- Application ID: `com.dev.blockverse`
- Project: `projects/blockverse-unity/`

## Repository layout

```text
projects/blockverse-unity/   Unity game project
docs/                        Development and cloud-build guides
.github/workflows/           GitHub Actions automation
```

## Development workflow

1. Open the repository in GitHub Codespaces or edit files through GitHub.
2. Use an installed Unity 6 editor when you need to inspect scenes, run the game, or make visual changes.
3. Commit and push changes to the `unity-migration` branch while the migration is in progress.
4. Configure Unity licensing secrets in GitHub repository settings.
5. Run **Actions → BLOCKVERSE Unity Android** to build Android artifacts.

## GitHub Actions secrets

The Unity build workflow expects:
- `UNITY_LICENSE`
- `UNITY_EMAIL`
- `UNITY_PASSWORD`

These must be added by the repository owner. Never commit Unity license files, signing keys, or passwords.

## Important

GitHub stores the Unity project and can run cloud builds, but it does not replace the Unity Editor for visual scene editing and live gameplay testing. A successful Android build also requires a valid Unity license and Android build support.

## Status

Unity migration started. Core board model, procedural level configuration, piece definitions, starter scene generator, and Android CI workflow are in place. Runtime validation and APK/AAB export are not yet verified.
