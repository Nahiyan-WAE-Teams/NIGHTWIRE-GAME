extends Node

signal call_state_changed(active: bool, character_id: String, muted: bool)

var active: bool = false
var character_id: String = ""
var muted: bool = false

func begin_call(target_character_id: String) -> bool:
	if active or ContentManager.get_character(target_character_id).is_empty():
		return false
	active = true
	character_id = target_character_id
	muted = false
	call_state_changed.emit(active, character_id, muted)
	return true

func set_muted(value: bool) -> void:
	if not active:
		return
	muted = value
	call_state_changed.emit(active, character_id, muted)

func end_call() -> void:
	if not active:
		return
	active = false
	character_id = ""
	muted = false
	call_state_changed.emit(active, character_id, muted)
