extends Node

var failures: int = 0

func _ready() -> void:
	call_deferred("_run_checks")

func _run_checks() -> void:
	if get_node_or_null("/root/SpyManager") == null or get_node_or_null("/root/PuzzleManager") == null:
		_fail("spy and puzzle managers are registered as autoloads")
	if get_node_or_null("/root/NotificationManager") == null or get_node_or_null("/root/CallManager") == null or get_node_or_null("/root/MediaManager") == null:
		_fail("notification and call managers are registered as autoloads")
	_expect(not MediaManager.play_voice_note("res://missing_voice.ogg"), "missing voice-note assets fail safely")
	_expect(MediaManager.load_image("res://missing_image.png") == null, "missing image assets fail safely")
	_expect(ContentManager.get_characters().size() == 20, "all twenty character slots load")
	_expect(ChatManager.get_conversations().size() == 20, "all twenty characters receive an inbox channel")
	_expect(ContentManager.get_episodes().is_empty(), "no authored episode is required to boot the framework")
	_expect(PuzzleManager.validate_pattern([2, 4, 1, 3], [2, 4, 1, 3]), "pattern puzzle accepts the correct sequence")
	_expect(not PuzzleManager.validate_pattern([2, 4, 1, 3], [2, 3, 4, 1]), "pattern puzzle rejects an incorrect sequence")
	_expect(PuzzleManager.validate_anagram("NIGHT", "htgin"), "password puzzle accepts case-insensitive anagrams")
	_expect(not PuzzleManager.validate_anagram("NIGHT", "nightwire"), "password puzzle rejects unrelated text")
	var reconstruction: Variant = load("res://scripts/ui/image_reconstruction.gd").new()
	_expect(not reconstruction.is_solved(), "image reconstruction starts in a scrambled state")
	_expect(reconstruction.swap_positions(0, 1), "image reconstruction allows a valid tile swap")
	_expect(not reconstruction.swap_positions(-1, 2), "image reconstruction rejects out-of-range tile swaps")
	_expect(reconstruction.get_order() == [1, 3, 4, 2], "image reconstruction preserves the resulting frame order")
	reconstruction.free()
	PuzzleManager.complete_puzzle("runtime_test_flag")
	_expect(bool(StoryManager.get_flags().get("runtime_test_flag", false)), "puzzle completion writes a persistent story flag")
	SpyManager.reset_suspicion("contact_01")
	var first_read: Dictionary = SpyManager.inspect_private_messages("contact_01")
	var second_read: Dictionary = SpyManager.inspect_private_messages("contact_01")
	var third_read: Dictionary = SpyManager.inspect_private_messages("contact_01")
	_expect(not bool(first_read.get("caught", true)) and not bool(second_read.get("caught", true)), "spy mode allows two quiet inspections")
	_expect(bool(third_read.get("caught", false)), "spy mode triggers an alert on the third inspection")
	_expect(StoryManager.get_trust("contact_01") == -5, "being caught reduces the target character trust")
	StoryManager.adjust_trust("contact_01", 5)
	SpyManager.reset_suspicion("contact_01")
	_expect(CallManager.begin_call("contact_01"), "call manager starts a simulated call for a valid character")
	CallManager.set_muted(true)
	_expect(CallManager.muted, "call manager stores mute state")
	CallManager.end_call()
	_expect(not CallManager.active, "call manager ends the simulated call cleanly")
	if failures == 0:
		print("NIGHTWIRE RUNTIME TESTS: all checks passed.")
		get_tree().quit(0)
	else:
		push_error("NIGHTWIRE RUNTIME TESTS: %d check(s) failed." % failures)
		get_tree().quit(1)

func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_fail(description)

func _fail(description: String) -> void:
	failures += 1
	push_error("FAIL: " + description)
