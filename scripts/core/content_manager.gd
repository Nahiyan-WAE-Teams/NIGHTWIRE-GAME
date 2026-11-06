extends Node

signal content_loaded
signal content_error(message: String)

const ROSTER_PATH: String = "res://data/characters/roster.json"
const EPISODE_DIRECTORY: String = "res://data/episodes"

var characters: Array[Dictionary] = []
var episodes: Dictionary = {}

func _ready() -> void:
	_load_roster()
	_load_episodes()
	content_loaded.emit()

func get_characters() -> Array[Dictionary]:
	return characters.duplicate(true)

func get_character(character_id: String) -> Dictionary:
	for character: Dictionary in characters:
		if str(character.get("id", "")) == character_id:
			return character.duplicate(true)
	return {}

func get_episodes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for episode_id: Variant in episodes.keys():
		var episode: Dictionary = episodes[episode_id]
		result.append({
			"id": str(episode.get("id", episode_id)),
			"title": str(episode.get("title", episode_id)),
			"description": str(episode.get("description", ""))
		})
	return result

func get_episode(episode_id: String) -> Dictionary:
	if not episodes.has(episode_id):
		return {}
	return (episodes[episode_id] as Dictionary).duplicate(true)

func reload_content() -> void:
	characters.clear()
	episodes.clear()
	_load_roster()
	_load_episodes()
	content_loaded.emit()

func _load_roster() -> void:
	var parsed: Variant = _read_json(ROSTER_PATH)
	var errors: PackedStringArray = NightwireContentValidator.validate_roster(parsed)
	if not errors.is_empty():
		for error_message: String in errors:
			push_error("NIGHTWIRE roster: " + error_message)
		content_error.emit("Character roster is invalid.")
		return
	var entries: Array = parsed.get("characters", [])
	for entry: Variant in entries:
		if entry is Dictionary:
			characters.append(entry.duplicate(true))

func _load_episodes() -> void:
	if not DirAccess.dir_exists_absolute(EPISODE_DIRECTORY):
		return
	var files: PackedStringArray = DirAccess.get_files_at(EPISODE_DIRECTORY)
	files.sort()
	for file_name: String in files:
		if not file_name.ends_with(".json") or file_name.begins_with("_"):
			continue
		var path: String = EPISODE_DIRECTORY.path_join(file_name)
		var parsed: Variant = _read_json(path)
		var errors: PackedStringArray = NightwireContentValidator.validate_episode(parsed)
		if not errors.is_empty():
			for error_message: String in errors:
				push_error("NIGHTWIRE episode %s: %s" % [file_name, error_message])
			content_error.emit("Episode file %s is invalid." % file_name)
			continue
		var episode_id: String = str(parsed.get("id", "")).strip_edges()
		if episode_id.is_empty():
			push_error("NIGHTWIRE episode %s has an empty id." % file_name)
			continue
		if episodes.has(episode_id):
			push_error("NIGHTWIRE has duplicate episode id '%s'." % episode_id)
			continue
		episodes[episode_id] = parsed.duplicate(true)

func _read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("NIGHTWIRE content file not found: " + path)
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("NIGHTWIRE could not open content file: " + path)
		return null
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null:
		push_error("NIGHTWIRE could not parse JSON: " + path)
	return parsed
