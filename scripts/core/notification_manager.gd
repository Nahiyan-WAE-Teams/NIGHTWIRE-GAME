extends Node

signal notification_received(character_id: String, title: String, body: String)

var _next_schedule_id: int = 0
var _scheduled: Dictionary = {}

func schedule_character_message(character_id: String, body: String, delay_seconds: float) -> int:
	if character_id.strip_edges().is_empty() or body.strip_edges().is_empty():
		return -1
	_next_schedule_id += 1
	var schedule_id: int = _next_schedule_id
	_scheduled[schedule_id] = true
	_deliver_after(schedule_id, character_id, body, maxf(delay_seconds, 0.1))
	return schedule_id

func cancel_scheduled(schedule_id: int) -> void:
	_scheduled.erase(schedule_id)

func cancel_all() -> void:
	_scheduled.clear()

func _deliver_after(schedule_id: int, character_id: String, body: String, delay_seconds: float) -> void:
	await get_tree().create_timer(delay_seconds).timeout
	if not _scheduled.has(schedule_id):
		return
	_scheduled.erase(schedule_id)
	ChatManager.append_character_message(character_id, body)
	var profile: Dictionary = ContentManager.get_character(character_id)
	var display_name: String = str(profile.get("name", "NIGHTWIRE"))
	notification_received.emit(character_id, display_name, body)
