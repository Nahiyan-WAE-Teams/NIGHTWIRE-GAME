extends RefCounted
class_name NightwireContentValidator

static func validate_roster(data: Variant) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not (data is Dictionary):
		errors.append("Roster root must be a JSON object.")
		return errors
	var characters: Variant = data.get("characters", null)
	if not (characters is Array):
		errors.append("Roster must contain a characters array.")
		return errors
	if characters.size() != 20:
		errors.append("Roster must contain exactly 20 character slots.")
	var seen_ids: Dictionary = {}
	for index: int in range(characters.size()):
		var item: Variant = characters[index]
		if not (item is Dictionary):
			errors.append("Character entry %d must be an object." % index)
			continue
		var character_id: String = str(item.get("id", "")).strip_edges()
		var character_name: String = str(item.get("name", "")).strip_edges()
		if character_id.is_empty():
			errors.append("Character entry %d is missing its id." % index)
		elif seen_ids.has(character_id):
			errors.append("Duplicate character id: %s." % character_id)
		else:
			seen_ids[character_id] = true
		if character_name.is_empty():
			errors.append("Character entry %d is missing its name." % index)
		if str(item.get("status", "")).strip_edges().is_empty():
			errors.append("Character %s is missing its status." % character_id)
	return errors

static func validate_episode(data: Variant) -> PackedStringArray:
	var errors: PackedStringArray = PackedStringArray()
	if not (data is Dictionary):
		errors.append("Episode root must be a JSON object.")
		return errors
	for required_key: String in ["id", "title", "start_node", "nodes"]:
		if not data.has(required_key):
			errors.append("Episode is missing required field '%s'." % required_key)
	var nodes_value: Variant = data.get("nodes", null)
	if not (nodes_value is Dictionary):
		errors.append("Episode nodes must be an object keyed by node id.")
		return errors
	var nodes: Dictionary = nodes_value
	var start_node: String = str(data.get("start_node", ""))
	if not nodes.has(start_node):
		errors.append("Episode start_node '%s' does not exist." % start_node)
	for node_key: Variant in nodes.keys():
		var node_value: Variant = nodes[node_key]
		var node_id: String = str(node_key)
		if not (node_value is Dictionary):
			errors.append("Node '%s' must be an object." % node_id)
			continue
		var node: Dictionary = node_value
		if str(node.get("speaker", "")).strip_edges().is_empty():
			errors.append("Node '%s' is missing speaker." % node_id)
		if str(node.get("text", "")).strip_edges().is_empty():
			errors.append("Node '%s' is missing text." % node_id)
		var choices_value: Variant = node.get("choices", [])
		if not (choices_value is Array):
			errors.append("Node '%s' choices must be an array." % node_id)
			continue
		for choice_index: int in range(choices_value.size()):
			var choice_value: Variant = choices_value[choice_index]
			if not (choice_value is Dictionary):
				errors.append("Choice %d in node '%s' must be an object." % [choice_index, node_id])
				continue
			var choice: Dictionary = choice_value
			if str(choice.get("text", "")).strip_edges().is_empty():
				errors.append("Choice %d in node '%s' is missing text." % [choice_index, node_id])
			var next_id: String = str(choice.get("next_id", ""))
			if next_id.is_empty() or not nodes.has(next_id):
				errors.append("Choice %d in node '%s' points to missing node '%s'." % [choice_index, node_id, next_id])
		var automatic_next: String = str(node.get("next_id", ""))
		if not automatic_next.is_empty() and not nodes.has(automatic_next):
			errors.append("Node '%s' points to missing next node '%s'." % [node_id, automatic_next])
	return errors
