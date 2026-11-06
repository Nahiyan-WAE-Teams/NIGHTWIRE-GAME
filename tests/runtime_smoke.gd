extends Node

func _ready() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var failures: int = 0
	if get_node_or_null("/root/SpyManager") == null or get_node_or_null("/root/PuzzleManager") == null:
		push_error("Runtime check failed: spy or puzzle manager autoload is missing.")
		failures += 1
	if get_node_or_null("/root/NotificationManager") == null or get_node_or_null("/root/CallManager") == null:
		push_error("Runtime check failed: notification or call manager autoload is missing.")
		failures += 1
	if PuzzleManager.validate_pattern([2, 4, 1, 3], [2, 4, 1, 3]) == false:
		push_error("Runtime check failed: valid pattern puzzle input was rejected.")
		failures += 1
	if PuzzleManager.validate_pattern([2, 4, 1, 3], [2, 3, 4, 1]):
		push_error("Runtime check failed: invalid pattern puzzle input was accepted.")
		failures += 1
	if not PuzzleManager.validate_anagram("NIGHT", "htgin"):
		push_error("Runtime check failed: valid password anagram was rejected.")
		failures += 1
	if PuzzleManager.validate_anagram("NIGHT", "nightwire"):
		push_error("Runtime check failed: invalid password anagram was accepted.")
		failures += 1
	if ContentManager.get_characters().size() != 20:
		push_error("Runtime check failed: ContentManager did not load all 20 character slots.")
		failures += 1
	if ChatManager.get_conversations().size() != 20:
		push_error("Runtime check failed: ChatManager did not create 20 inbox channels.")
		failures += 1
	if not ContentManager.get_episodes().is_empty():
		push_error("Runtime check failed: the starter build should not contain authored episodes.")
		failures += 1
	if failures == 0:
		print("NIGHTWIRE RUNTIME TESTS: all autoload checks passed.")
		get_tree().quit(0)
	else:
		get_tree().quit(1)
