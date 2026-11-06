extends Node

const SAVE_PATH: String = "user://nightwire_save.json"

func load_payload() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("NIGHTWIRE: save file could not be opened for reading.")
		return {}
	var raw_text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed is Dictionary:
		return parsed
	push_warning("NIGHTWIRE: save data was invalid. A fresh local session will be created.")
	return {}

func save_payload(payload: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("NIGHTWIRE: save file could not be opened for writing.")
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return true

func erase_save() -> bool:
	if FileAccess.file_exists(SAVE_PATH):
		return DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH)) == OK
	return true
