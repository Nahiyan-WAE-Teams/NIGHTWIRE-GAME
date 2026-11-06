extends SceneTree

const ContentValidator = preload("res://scripts/core/content_validator.gd")

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var roster_file: FileAccess = FileAccess.open("res://data/characters/roster.json", FileAccess.READ)
	if roster_file == null:
		_fail("roster fixture exists")
		_finish()
		return
	var roster: Variant = JSON.parse_string(roster_file.get_as_text())
	roster_file.close()
	_expect(ContentValidator.validate_roster(roster).is_empty(), "the character roster contains exactly twenty unique valid profiles")

	var valid_episode: Dictionary = {
		"id": "test_episode",
		"title": "Test Episode",
		"start_node": "opening",
		"nodes": {
			"opening": {
				"speaker": "contact_01",
				"text": "A test message.",
				"choices": [
					{
						"text": "Continue",
						"next_id": "ending",
						"trust_changes": {"contact_01": 1},
						"set_flags": {"test_flag": true},
						"evidence": ["test_photo"]
					}
				]
			},
			"ending": {
				"speaker": "contact_01",
				"text": "End of test.",
				"choices": []
			}
		}
	}
	_expect(ContentValidator.validate_episode(valid_episode).is_empty(), "a well-formed episode with a connected choice graph is accepted")

	var broken_episode: Dictionary = valid_episode.duplicate(true)
	broken_episode["nodes"]["opening"]["choices"][0]["next_id"] = "missing_node"
	_expect(not ContentValidator.validate_episode(broken_episode).is_empty(), "an episode with a dangling next_id is rejected")

	var broken_roster: Dictionary = {"characters": [{"id": "same"}, {"id": "same"}]}
	_expect(not ContentValidator.validate_roster(broken_roster).is_empty(), "a malformed roster is rejected")
	_finish()

func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		_fail(description)

func _fail(description: String) -> void:
	failures += 1
	push_error("FAIL: " + description)

func _finish() -> void:
	if failures == 0:
		print("NIGHTWIRE TESTS: all checks passed.")
		quit(0)
	else:
		push_error("NIGHTWIRE TESTS: " + str(failures) + " check(s) failed.")
		quit(1)
