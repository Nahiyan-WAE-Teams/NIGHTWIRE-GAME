extends Node

signal story_node_changed(episode_id: String, node_id: String, node: Dictionary)
signal story_error(message: String)
signal story_completed(episode_id: String)

var active_episode_id: String = ""
var current_node_id: String = ""
var trust: Dictionary = {}
var flags: Dictionary = {}

func _ready() -> void:
	var saved_trust: Variant = SaveManager.get_value("trust", {})
	var saved_flags: Variant = SaveManager.get_value("story_flags", {})
	if saved_trust is Dictionary:
		trust = saved_trust.duplicate(true)
	if saved_flags is Dictionary:
		flags = saved_flags.duplicate(true)
	active_episode_id = str(SaveManager.get_value("active_episode_id", ""))
	current_node_id = str(SaveManager.get_value("current_node_id", ""))

func start_episode(episode_id: String) -> bool:
	var episode: Dictionary = ContentManager.get_episode(episode_id)
	if episode.is_empty():
		story_error.emit("Episode '%s' was not found or failed validation." % episode_id)
		return false
	active_episode_id = episode_id
	current_node_id = str(episode.get("start_node", ""))
	_persist()
	_emit_current_node()
	return true

func get_current_node() -> Dictionary:
	if active_episode_id.is_empty() or current_node_id.is_empty():
		return {}
	var episode: Dictionary = ContentManager.get_episode(active_episode_id)
	var nodes: Dictionary = episode.get("nodes", {})
	var node: Variant = nodes.get(current_node_id, {})
	if node is Dictionary:
		return node.duplicate(true)
	return {}

func get_trust(character_id: String) -> int:
	return int(trust.get(character_id, 0))

func get_flags() -> Dictionary:
	return flags.duplicate(true)

func choose(choice_index: int) -> bool:
	var node: Dictionary = get_current_node()
	var choices: Variant = node.get("choices", [])
	if not (choices is Array) or choice_index < 0 or choice_index >= choices.size():
		story_error.emit("That choice is not available.")
		return false
	var choice_value: Variant = choices[choice_index]
	if not (choice_value is Dictionary):
		return false
	var choice: Dictionary = choice_value
	if not _requirements_met(choice):
		story_error.emit("The required trust, evidence, or story flags have not been met.")
		return false
	var trust_changes: Variant = choice.get("trust_changes", {})
	if trust_changes is Dictionary:
		for character_id: Variant in trust_changes.keys():
			trust[str(character_id)] = get_trust(str(character_id)) + int(trust_changes[character_id])
	var flag_changes: Variant = choice.get("set_flags", {})
	if flag_changes is Dictionary:
		for flag_id: Variant in flag_changes.keys():
			flags[str(flag_id)] = flag_changes[flag_id]
	var evidence: Variant = choice.get("evidence", [])
	if evidence is Array:
		for evidence_id: Variant in evidence:
			EvidenceManager.unlock(str(evidence_id))
	var next_id: String = str(choice.get("next_id", ""))
	if next_id.is_empty():
		story_completed.emit(active_episode_id)
		current_node_id = ""
	else:
		current_node_id = next_id
	_persist()
	_emit_current_node()
	return true

func _requirements_met(choice: Dictionary) -> bool:
	var required_trust: Variant = choice.get("requires_trust", {})
	if required_trust is Dictionary:
		for character_id: Variant in required_trust.keys():
			if get_trust(str(character_id)) < int(required_trust[character_id]):
				return false
	var required_flags: Variant = choice.get("requires_flags", [])
	if required_flags is Array:
		for flag_id: Variant in required_flags:
			if not bool(flags.get(str(flag_id), false)):
				return false
	var required_evidence: Variant = choice.get("requires_evidence", [])
	if required_evidence is Array:
		for evidence_id: Variant in required_evidence:
			if not EvidenceManager.get_unlocked_ids().has(str(evidence_id)):
				return false
	return true

func _emit_current_node() -> void:
	if current_node_id.is_empty():
		return
	story_node_changed.emit(active_episode_id, current_node_id, get_current_node())

func _persist() -> void:
	SaveManager.set_value("trust", trust)
	SaveManager.set_value("story_flags", flags)
	SaveManager.set_value("active_episode_id", active_episode_id)
	SaveManager.set_value("current_node_id", current_node_id)
