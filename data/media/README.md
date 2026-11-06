# NIGHTWIRE media assets

Place media under `res://assets/media/` and reference those paths in episode message data.

Supported attachment kinds in the chat model:

- `image`: image resource path.
- `voice`: audio stream path plus optional duration in seconds.
- `video`: video file path metadata. A dedicated video decoder/viewer is not enabled yet.
- `document`: document path metadata for the future file viewer.

Voice playback uses Godot's `AudioStreamPlayer`. Missing or incompatible files are rejected safely. Keep assets optimized for Android memory and storage.
