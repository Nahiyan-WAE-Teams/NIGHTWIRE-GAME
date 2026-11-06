extends Node

static func validate_pattern(expected: Array[int], entered: Array[int]) -> bool:
	if expected.is_empty() or expected.size() != entered.size():
		return false
	for index: int in range(expected.size()):
		if expected[index] != entered[index]:
			return false
	return true

static func validate_anagram(expected: String, entered: String) -> bool:
	var clean_expected: String = expected.to_upper().replace(" ", "")
	var clean_entered: String = entered.to_upper().replace(" ", "")
	if clean_expected.is_empty() or clean_expected.length() != clean_entered.length():
		return false
	return _letter_counts(clean_expected) == _letter_counts(clean_entered)

static func validate_image_order(expected: Array[int], entered: Array[int]) -> bool:
	return validate_pattern(expected, entered)

static func complete_puzzle(flag_id: String) -> void:
	if flag_id.strip_edges().is_empty():
		return
	StoryManager.set_flag(flag_id, true)

static func _letter_counts(value: String) -> Dictionary:
	var counts: Dictionary = {}
	for index: int in range(value.length()):
		var letter: String = value.substr(index, 1)
		counts[letter] = int(counts.get(letter, 0)) + 1
	return counts
