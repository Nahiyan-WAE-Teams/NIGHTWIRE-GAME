extends Node

const SAVE_PATH: String = "user://nightwire_save.dat"
const LEGACY_SAVE_PATH: String = "user://nightwire_save.json"
const ENCRYPTION_PASSWORD: String = "NIGHTWIRE_LOCAL_SAVE_V1_CHANGE_FOR_RELEASE"

var state: Dictionary = {}

func _ready() -> void:
	_load_state()

func get_value(key: String, default_value: Variant = null) -> Variant:
	return state.get(key, default_value)

func set_value(key: String, value: Variant) -> void:
	state[key] = value
	save_now()

func get_state() -> Dictionary:
	return state.duplicate(true)

func replace_state(new_state: Dictionary) -> void:
	state = new_state.duplicate(true)
	save_now()

func save_now() -> bool:
	var file: FileAccess = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENCRYPTION_PASSWORD)
	if file == null:
		push_error("NIGHTWIRE could not open encrypted save file for writing.")
		return false
	file.store_string(JSON.stringify({"version": 1, "state": state}))
	file.close()
	return true

func reset_all() -> bool:
	state.clear()
	var encrypted_removed: bool = true
	var legacy_removed: bool = true
	if FileAccess.file_exists(SAVE_PATH):
		encrypted_removed = DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH)) == OK
	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		legacy_removed = DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH)) == OK
	return encrypted_removed and legacy_removed

func _load_state() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var encrypted_file: FileAccess = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENCRYPTION_PASSWORD)
		if encrypted_file != null:
			var encrypted_text: String = encrypted_file.get_as_text()
			encrypted_file.close()
			_apply_payload(encrypted_text)
			return
		push_warning("NIGHTWIRE encrypted save could not be opened. Trying legacy local save.")
	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		var legacy_file: FileAccess = FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
		if legacy_file != null:
			var legacy_text: String = legacy_file.get_as_text()
			legacy_file.close()
			_apply_payload(legacy_text)
			save_now()

func _apply_payload(raw_text: String) -> void:
	var parsed: Variant = JSON.parse_string(raw_text)
	if not (parsed is Dictionary):
		push_warning("NIGHTWIRE save data is invalid. Starting a clean session.")
		return
	var loaded_state: Variant = parsed.get("state", parsed)
	if loaded_state is Dictionary:
		state = loaded_state.duplicate(true)
