# BLOCKVERSE — Android build and device test guide

## 1. One-time GitHub setup

Open the repository's **Settings → Secrets and variables → Actions** and add these repository secrets:

- `UNITY_LICENSE` — Unity license contents in the format supported by GameCI.
- `UNITY_EMAIL` — email for the Unity account used by the license.
- `UNITY_PASSWORD` — Unity account password used by GameCI.

Do not put these values in source files, commits, workflow YAML, or screenshots. The workflow checks that all three values exist before starting the licensed build. The check cannot validate whether the license is valid.

## 2. Run the cloud build

1. Push a commit that changes `projects/blockverse-unity/**`, or open **Actions → BLOCKVERSE Unity Android → Run workflow**.
2. Wait for **Project preflight** and **Build BLOCKVERSE Android** to finish.
3. Open the successful workflow run and download the `BLOCKVERSE-Android-<run number>` artifact.
4. Extract the artifact and locate the generated APK and AAB. The APK is for direct device installation; the AAB is for Google Play upload.

The preflight job checks project structure and the declared Unity version only. It is not a C# compilation test. A successful licensed Unity build is the first CI compilation evidence.

## 3. Install on an Android phone

For a direct APK test:

1. Transfer the APK to the phone.
2. Open it and allow installation from that source if Android asks.
3. Install and launch BLOCKVERSE.
4. If Android blocks installation, check that the APK is a debug/test build and that the device permits installing it.

Do not upload an untested prototype AAB to production.

## 4. Manual test checklist

### Launch and navigation
- [ ] App launches without crashing.
- [ ] Portrait layout fits the screen; no clipped buttons or overlapping labels.
- [ ] Play, Level Select, Daily Reward, Shop, Settings, Missions and Achievements open.
- [ ] Back/navigation actions return to the expected screen.

### Core gameplay
- [ ] Pieces can be dragged and dropped using touch.
- [ ] Valid placements occupy the intended cells.
- [ ] Invalid placements do not change the board or score.
- [ ] Full rows and columns clear correctly, including simultaneous clears.
- [ ] Bomb, Rainbow and Lightning affect the intended area/line.
- [ ] Stone and ice obstacles take the expected number of hits.
- [ ] Score, combo, moves and level objectives update correctly.
- [ ] Win, fail, retry and next-level flows work.

### Pause, revive and undo
- [ ] Pause freezes gameplay; Resume restores it.
- [ ] Restart and Main Menu work from pause.
- [ ] Revive deducts the correct coin amount only once per level.
- [ ] Revive does not leave the game in a failed or unresponsive state.
- [ ] Undo restores the previous board and tray exactly.
- [ ] Undo cannot be used more than once per level.
- [ ] Undo from a failure screen works when offered.

### Saving, rewards and settings
- [ ] Close and relaunch the app; coins, best score, progress and theme remain saved.
- [ ] Daily reward can only be claimed once per local calendar day.
- [ ] Daily mission progress and claim state behave correctly.
- [ ] Achievements unlock and reward only once.
- [ ] Sound and vibration preferences persist after relaunch.
- [ ] Purchased themes remain unlocked and the selected theme is applied.

### Device and lifecycle
- [ ] Test on at least one real Android device, not only the Unity Editor.
- [ ] Test a smaller screen and a tall-screen device if available.
- [ ] Background and resume the app during gameplay.
- [ ] Rotate is not required; confirm the app stays portrait.
- [ ] Check touch accuracy near screen edges and system navigation areas.
- [ ] Play for 10–15 minutes and watch for freezes, crashes, overheating or abnormal battery drain.

## 5. Report a test issue

For each issue, record:
- Phone model and Android version.
- APK build/run number.
- Screen or level where it happened.
- Exact steps to reproduce.
- Expected result and actual result.
- Screenshot or screen recording, if possible.

## Current verification status

No Unity Editor compile, Play Mode run, Android APK install, or physical-device test is claimed by this repository change. Those checks must be performed by the Unity build runner and on a real Android device.
