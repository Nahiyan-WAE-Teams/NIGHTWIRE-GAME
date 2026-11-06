extends Node

signal evidence_changed

const CATALOG_PATH: String = "res://data/evidence/catalog.json"

var catalog: Dictionary = {}
var unlocked_ids: Array[String] = []

func _ready() -> void:
	_load_catalog()
	var stored: Variant = SaveManager.get_value("evidence", [])
	if stored is Array:
		for item: Variant in stored:
			var evidence_id: String = str(item)
			if not evidence_id.is_empty() and not unlocked_ids.has(evidence_id):
				unlocked_ids.append(evidence_id)

func unlock(evidence_id: String) -> bool:
	var clean_id: String = evidence_id.strip_edges()
	if clean_id.is_empty() or unlocked_ids.has(clean_id):
		return false
	unlocked_ids.append(clean_id)
	SaveManager.set_value("evidence", unlocked_ids)
	evidence_changed.emit()
	return true

func get_unlocked() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for evidence_id: String in unlocked_ids:
		var details: Dictionary = catalog.get(evidence_id, {})
		if details.is_empty():
			details = {"id": evidence_id, "title": evidence_id.replace("_", " ").capitalize(), "description": "Evidence record awaiting its content definition."}
		result.append(details.duplicate(true))
	return result

func get_unlocked_ids() -> Array[String]:
	return unlocked_ids.duplicate()

func clear_evidence() -> void:
	unlocked_ids.clear()
	SaveManager.set_value("evidence", [])
	evidence_changed.emit()

func _load_catalog() -> void:
	if not FileAccess.file_exists(CATALOG_PATH):
		return
	var file: FileAccess = FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		var entries: Variant = parsed.get("evidence", [])
		if entries is Array:
			for item: Variant in entries:
				if item is Dictionary:
					var evidence_id: String = str(item.get("id", ""))
					if not evidence_id.is_empty():
						catalog[evidence_id] = item.duplicate(true)
