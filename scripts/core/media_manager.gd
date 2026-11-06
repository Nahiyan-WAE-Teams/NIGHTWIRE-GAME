extends Node

signal voice_playback_changed(playing: bool, media_path: String)

var audio_player: AudioStreamPlayer
var current_voice_path: String = ""

func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	audio_player.finished.connect(_on_playback_finished)

func play_voice_note(media_path: String) -> bool:
	if media_path.strip_edges().is_empty() or not ResourceLoader.exists(media_path):
		push_warning("NIGHTWIRE: voice note asset is missing: " + media_path)
		return false
	var resource: Resource = load(media_path)
	if not (resource is AudioStream):
		push_warning("NIGHTWIRE: voice note asset is not an AudioStream: " + media_path)
		return false
	audio_player.stop()
	audio_player.stream = resource
	current_voice_path = media_path
	audio_player.play()
	voice_playback_changed.emit(true, current_voice_path)
	return true

func stop_voice_note() -> void:
	if audio_player != null and audio_player.playing:
		audio_player.stop()
		_on_playback_finished()

func is_voice_note_playing() -> bool:
	return audio_player != null and audio_player.playing

func load_image(media_path: String) -> Texture2D:
	if media_path.strip_edges().is_empty() or not ResourceLoader.exists(media_path):
		return null
	var resource: Resource = load(media_path)
	if resource is Texture2D:
		return resource
	return null

func _on_playback_finished() -> void:
	current_voice_path = ""
	voice_playback_changed.emit(false, "")
