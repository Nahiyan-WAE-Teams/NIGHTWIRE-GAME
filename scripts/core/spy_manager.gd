extends Node

var suspicion: Dictionary = {}

func _ready() -> void:
	var stored: Variant = SaveManager.get_value("spy_suspicion", {})
	if stored is Dictionary:
		suspicion = stored.duplicate(true)

func inspect_private_messages(character_id: String) -> Dictionary:
	var profile: Dictionary = ContentManager.get_character(character_id)
	if profile.is_empty():
		return {"caught": false, "messages": []}
	var level: int = int(suspicion.get(character_id, 0)) + 1
	suspicion[character_id] = level
	SaveManager.set_value("spy_suspicion", suspicion)
	var caught: bool = level >= 3
	if caught:
		StoryManager.adjust_trust(character_id, -5)
		return {"caught": true, "messages": []}
	var messages: Variant = profile.get("private_messages", [])
	if not (messages is Array):
		messages = []
	return {"caught": false, "messages": messages.duplicate(true), "suspicion": level}

func get_suspicion(character_id: String) -> int:
	return int(suspicion.get(character_id, 0))

func reset_suspicion(character_id: String) -> void:
	suspicion.erase(character_id)
	SaveManager.set_value("spy_suspicion", suspicion)
