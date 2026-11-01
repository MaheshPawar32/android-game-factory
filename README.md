# Android Game Factory

A browser-first Godot workspace for building Android 2D and 3D games with cloud-based builds.

## Goals

- Develop and manage game projects from a browser.
- Use Godot and GDScript for 2D and 3D games.
- Build Android APK and AAB packages with GitHub Actions.
- Keep project templates reusable and version-controlled.

## Repository layout

```text
docs/                 Guides and workflows
templates/godot-2d/   Reusable 2D starter template
templates/godot-3d/   Reusable 3D starter template
projects/             Your actual game projects
.github/workflows/    Cloud Android build workflows
```

## Cloud workflow

1. Open this repository in GitHub Codespaces.
2. Edit project files in the browser.
3. Commit and push changes to GitHub.
4. Run the Android build workflow from the Actions tab.
5. Download the generated APK or AAB from the workflow artifacts.

## Important

Godot's full visual editor is a desktop application. This repository is designed for browser-based source editing and cloud/headless builds; it does not provide a full Godot editor running inside the browser.

Android export requires a compatible Godot version, Android export templates, Android SDK, build-tools, and Java. The workflow will install/configure these in its cloud runner.

## Status

Starter repository setup in progress.
