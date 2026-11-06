# NIGHTWIRE

**Someone is always listening.**

NIGHTWIRE is an offline-first, portrait psychological thriller built with **Godot 4.4** and **GDScript 2.0**.

## Current foundation

- Portrait-first Godot project using the Mobile renderer.
- OLED-dark visual foundation with restrained cyan and red signal accents.
- Local-only messenger prototype with an inbox and conversation view.
- Message history saved as JSON under `user://nightwire_save.json`.
- No AI API, remote backend, account, or network dependency.

## Open the project

1. Install Godot 4.4.
2. Clone this repository.
3. Import the folder containing `project.godot`.
4. Run the project with F6/F5.

## Controls

- Tap a conversation in the inbox to open it.
- Type a message and press the arrow button or Enter.
- Use the back arrow to return to the inbox.

## Project structure

```
NIGHTWIRE/
├── project.godot
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── core/
│   │   ├── chat_manager.gd
│   │   └── save_manager.gd
│   └── ui/
│       └── main.gd
└── README.md
```

## Development notes

The current repository was empty at initialization, so this commit establishes the first runnable foundation rather than modifying pre-existing game code. Narrative canon, character identities, and episode branches remain intentionally uncommitted until the story premise is confirmed.
