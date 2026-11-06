extends Node

func _ready() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	var failures: int = 0
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
