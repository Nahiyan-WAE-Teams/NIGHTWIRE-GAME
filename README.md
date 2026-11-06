# NIGHTWIRE

**Someone is always listening.**

An offline-first, portrait psychological thriller framework built with Godot 4.4 and GDScript 2.0. The game is designed for a 20-character cast and external episode files.

## Design principle

The game engine and the story content are separate. The engine is built first; episodes can be authored and added later without editing GDScript.

## Current systems

- Godot 4.4 project configured for the Mobile renderer and portrait layout.
- Grounded thriller-messenger interface with a muted graphite palette, forest-green accents, readable phone-sized typography, larger touch targets, searchable conversations, contact presence, message timestamps and quiet transitions. Four primary destinations keep the inbox central; the map, story files, signal lab and settings stay in the secondary More menu.
- Inbox, 20-character directory, connected evidence corkboard, story launcher, hacking lab, editable city map and settings.
- Twenty editable character slots loaded from JSON.
- Local conversation history and per-character message storage.
- Encrypted local save file for conversations, trust, story flags, evidence and episode progress.
- Episode JSON loader with validation of required fields and choice destinations.
- Branching choice engine with trust changes, flag requirements and evidence unlocks.
- Interactive town map loaded from `data/world/locations.json`.
- Animated simulated call interface, zoomable image viewer, readable document preview and voice-note waveform.
- Optional Android haptic feedback with a persistent in-game setting.
- Content authoring template and guide.
- GitHub Actions headless import and content-system tests.

## Run

1. Install Godot 4.4.
2. Clone this repository and import `project.godot`.
3. Run the project with F6/F5.
4. Open the **PEOPLE** tab to inspect the 20 character slots.
5. Open **CHATS** to view each local conversation.
6. Open **MAP** to inspect the editable city locations.
6. Open **STORY** to launch any valid episode JSON file you add.

The game currently contains no authored episode, named cast, or fixed mystery. Those are content decisions to be added through JSON.

## Add your story later

- Edit `data/characters/roster.json` to name and describe the 20 characters.
- Copy `data/episodes/_episode_template.json` to a new JSON file in `data/episodes/`.
- Follow `data/episodes/README.md` for node, choice, trust, flag and evidence fields.
- Add evidence metadata to `data/evidence/catalog.json`.

Restart the game to load new content. Invalid episode files are rejected with validation errors rather than crashing the game.

## Layout

```
NIGHTWIRE/
├── project.godot
├── scenes/main.tscn
├── data/
│   ├── characters/roster.json
│   ├── episodes/_episode_template.json
│   ├── episodes/README.md
│   └── evidence/catalog.json
├── scripts/
│   ├── core/
│   │   ├── content_validator.gd
│   │   ├── content_manager.gd
│   │   ├── save_manager.gd
│   │   ├── chat_manager.gd
│   │   ├── evidence_manager.gd
│   │   └── story_manager.gd
│   └── ui/main.gd
└── tests/run_tests.gd
```

## Save security note

Save data is encrypted at rest with Godot's encrypted FileAccess API. The password in the current source is a development key, not a secure per-install secret. Replace it with a release-specific key strategy before shipping a public build.


## Android device testing build

An ARM64 Android debug export preset is included in `export_presets.cfg`. Pushing to `build/**` triggers `.github/workflows/android-apk.yml`, which installs Godot 4.4.1 export templates, Java 17 and the Android SDK, creates an ephemeral debug signing key, exports `NIGHTWIRE-debug.apk`, and uploads it as the `NIGHTWIRE-Android-debug` workflow artifact for 14 days.

The debug signing key is generated only inside the CI runner and is not committed. This APK is for sideloaded device testing, not Play Store release. To install it, download the APK artifact from the successful Android workflow run, open it on the Android device, and allow installation from the browser/files app when Android prompts.
