extends Node

signal conversations_changed
signal messages_changed(conversation_id: String)

var conversations: Array[Dictionary] = []

func _ready() -> void:
	var saved: Dictionary = SaveManager.load_payload()
	var stored: Variant = saved.get("conversations", [])
	if stored is Array and not stored.is_empty():
		for entry: Variant in stored:
			if entry is Dictionary:
				conversations.append(entry)
	else:
		_seed_conversations()
		_persist()

func get_conversations() -> Array[Dictionary]:
	return conversations

func get_conversation(conversation_id: String) -> Dictionary:
	for conversation: Dictionary in conversations:
		if str(conversation.get("id", "")) == conversation_id:
			return conversation
	return {}

func get_messages(conversation_id: String) -> Array:
	var conversation: Dictionary = get_conversation(conversation_id)
	var value: Variant = conversation.get("messages", [])
	if value is Array:
		return value
	return []

func mark_read(conversation_id: String) -> void:
	for index: int in range(conversations.size()):
		if str(conversations[index].get("id", "")) == conversation_id:
			conversations[index]["unread"] = 0
			_persist()
			conversations_changed.emit()
			return

func send_message(conversation_id: String, message_text: String) -> bool:
	var clean_text: String = message_text.strip_edges()
	if clean_text.is_empty():
		return false
	for index: int in range(conversations.size()):
		if str(conversations[index].get("id", "")) == conversation_id:
			var messages: Array = conversations[index].get("messages", [])
			messages.append({
				"id": str(Time.get_unix_time_from_system()) + "_" + str(messages.size()),
				"sender": "player",
				"text": clean_text,
				"time": Time.get_time_string_from_system()
			})
			conversations[index]["messages"] = messages
			conversations[index]["preview"] = clean_text
			conversations[index]["updated"] = Time.get_unix_time_from_system()
			_persist()
			messages_changed.emit(conversation_id)
			conversations_changed.emit()
			return true
	return false

func _seed_conversations() -> void:
	conversations = [
		{
			"id": "unknown_signal",
			"name": "Unknown Contact",
			"subtitle": "Encrypted channel",
			"presence": "SIGNAL ACTIVE",
			"preview": "If this screen is open, the signal reached you.",
			"unread": 1,
			"updated": 2,
			"messages": [
				{"id": "seed_1", "sender": "contact", "text": "If this screen is open, the signal reached you.", "time": "23:41"},
				{"id": "seed_2", "sender": "contact", "text": "Keep this conversation on this device. For now, that's safer.", "time": "23:41"}
			]
		},
		{
			"id": "local_archive",
			"name": "Local Archive",
			"subtitle": "This device only",
			"presence": "OFFLINE",
			"preview": "No evidence has been saved yet.",
			"unread": 0,
			"updated": 1,
			"messages": [
				{"id": "archive_1", "sender": "contact", "text": "Evidence you collect will appear here when the dossier system is connected.", "time": "SYSTEM"}
			]
		}
	]

func _persist() -> void:
	SaveManager.save_payload({"version": 1, "conversations": conversations})
