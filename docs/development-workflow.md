# Browser-first development workflow

## 1. Open the workspace

1. Open the repository on GitHub.
2. Select **Code → Codespaces → Create codespace on main**.
3. Use the browser editor to edit GDScript, scenes, resources, and project configuration.
4. Commit and push your changes.

Codespaces is a browser-based development environment, not the full Godot visual editor. You can edit text-based Godot files and run command-line tools there. Scene editing that depends on Godot's GUI editor may require a separate remote-desktop/editor solution or a local Godot editor.

## 2. Start a game

Choose a starter under `templates/godot-2d` or `templates/godot-3d`, copy it into a new folder under `projects/`, then open that folder as the Godot project in your preferred Godot editor.

Keep each game self-contained:
- `project.godot`
- `scenes/`
- `scripts/`
- `assets/`
- `export_presets.cfg` (configure Android export in Godot; do not commit signing secrets)

## 3. Android export prerequisites

Before building an Android package:
- Install the matching Godot export templates for the Godot version used by the project.
- Configure Android SDK, platform-tools, build-tools, command-line tools, and Java.
- In Godot, configure the Android SDK paths and create an Android export preset.
- Set a unique application ID, version, orientation, permissions, and package format.
- For a release build, store keystore and passwords in GitHub Actions secrets. Never commit a keystore or passwords.

## 4. Cloud builds

Use **Actions → Android Export** and provide:
- `project_path`: folder containing `project.godot`, e.g. `projects/my-game`.
- `export_preset`: exact preset name from that project's `export_presets.cfg`, e.g. `Android`.

The workflow is a configurable starting point. It expects the runner image to contain a compatible Godot CLI, export templates, Android SDK, and Java. Verify the image/tool versions against your project before relying on it for release builds.

## 5. Artifacts

Successful runs upload APK and AAB files as workflow artifacts. Open the completed workflow run in GitHub Actions and download its **android-build** artifact.
