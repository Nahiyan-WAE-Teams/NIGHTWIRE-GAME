extends Node

signal conversations_changed
signal messages_changed(conversation_id: String)

var conversations: Array[Dictionary] = []

func _ready() -> void:
	var stored: Variant = SaveManager.get_value("conversations", [])
	if stored is Array:
		for entry: Variant in stored:
			if entry is Dictionary:
				conversations.append(entry.duplicate(true))
	_sync_roster()

func get_conversations() -> Array[Dictionary]:
	return conversations.duplicate(true)

func get_conversation(conversation_id: String) -> Dictionary:
	for conversation: Dictionary in conversations:
		if str(conversation.get("id", "")) == conversation_id:
			return conversation.duplicate(true)
	return {}

func get_messages(conversation_id: String) -> Array[Dictionary]:
	var conversation: Dictionary = get_conversation(conversation_id)
	var raw_messages: Variant = conversation.get("messages", [])
	var result: Array[Dictionary] = []
	if raw_messages is Array:
		for item: Variant in raw_messages:
			if item is Dictionary:
				result.append(item.duplicate(true))
	return result

func send_message(conversation_id: String, message_text: String) -> bool:
	var clean_text: String = message_text.strip_edges()
	if clean_text.is_empty():
		return false
	return _append_message(conversation_id, "player", clean_text)

func append_character_message(conversation_id: String, message_text: String) -> bool:
	var clean_text: String = message_text.strip_edges()
	if clean_text.is_empty():
		return false
	return _append_message(conversation_id, "character", clean_text)

func mark_read(conversation_id: String) -> void:
	var index: int = _find_index(conversation_id)
	if index < 0 or int(conversations[index].get("unread", 0)) == 0:
		return
	conversations[index]["unread"] = 0
	_persist()
	conversations_changed.emit()

func get_unread_total() -> int:
	var total: int = 0
	for conversation: Dictionary in conversations:
		total += int(conversation.get("unread", 0))
	return total

func _append_message(conversation_id: String, sender: String, message_text: String) -> bool:
	var index: int = _find_index(conversation_id)
	if index < 0:
		return false
	var messages: Array = conversations[index].get("messages", [])
	messages.append({
		"id": str(Time.get_ticks_usec()),
		"sender": sender,
		"text": message_text,
		"time": Time.get_time_string_from_system()
	})
	conversations[index]["messages"] = messages
	conversations[index]["preview"] = message_text
	conversations[index]["unread"] = int(conversations[index].get("unread", 0)) + (1 if sender == "character" else 0)
	conversations[index]["updated"] = Time.get_unix_time_from_system()
	_persist()
	messages_changed.emit(conversation_id)
	conversations_changed.emit()
	return true

func _find_index(conversation_id: String) -> int:
	for index: int in range(conversations.size()):
		if str(conversations[index].get("id", "")) == conversation_id:
			return index
	return -1

func _sync_roster() -> void:
	var changed: bool = false
	for profile: Dictionary in ContentManager.get_characters():
		var character_id: String = str(profile.get("id", ""))
		if _find_index(character_id) >= 0:
			continue
		conversations.append({
			"id": character_id,
			"name": str(profile.get("name", "Unknown Contact")),
			"role": str(profile.get("role", "")),
			"status": str(profile.get("status", "inactive")),
			"preview": "No messages yet",
			"unread": 0,
			"updated": 0,
			"messages": []
		})
		changed = true
	if changed or conversations.is_empty():
		_persist()
	conversations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("updated", 0)) > float(b.get("updated", 0))
	)
	conversations_changed.emit()

func reset_conversations() -> void:
	conversations.clear()
	_sync_roster()

func _persist() -> void:
	SaveManager.set_value("conversations", conversations)
