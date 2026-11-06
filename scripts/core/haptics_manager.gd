extends Node

const SETTINGS_PATH: String = "user://nightwire_settings.cfg"
const SETTINGS_SECTION: String = "feedback"
const HAPTICS_KEY: String = "haptics_enabled"

var enabled: bool = true

func _ready() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		enabled = bool(config.get_value(SETTINGS_SECTION, HAPTICS_KEY, true))

func is_enabled() -> bool:
	return enabled

func set_enabled(value: bool) -> void:
	enabled = value
	var config: ConfigFile = ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SETTINGS_SECTION, HAPTICS_KEY, enabled)
	var result: Error = config.save(SETTINGS_PATH)
	if result != OK:
		push_warning("NIGHTWIRE: unable to save feedback preferences.")

func pulse(duration_ms: int = 24) -> bool:
	if not enabled or not OS.has_feature("mobile") or duration_ms <= 0:
		return false
	Input.vibrate_handheld(clampi(duration_ms, 1, 250))
	return true
