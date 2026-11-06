extends Control

signal location_selected(location: Dictionary)

const DATA_PATH: String = "res://data/world/locations.json"
const MAP_COLOR: Color = Color("#0E151A")
const ROAD_COLOR: Color = Color("#29363D")
const GRID_COLOR: Color = Color("#17252B")
const PIN_COLOR: Color = Color("#FF3B30")
const TEXT_COLOR: Color = Color("#DCE7E9")

var locations: Array[Dictionary] = []
var pin_buttons: Array[Button] = []
var selected_id: String = ""

func _ready() -> void:
	custom_minimum_size = Vector2(900.0, 900.0)
	load_location_data(DATA_PATH)
	_build_pins()
	resized.connect(_layout_pins)
	queue_redraw()

func load_location_data(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_warning("NIGHTWIRE: town map data is missing: " + path)
		return false
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not parsed.get("locations", null) is Array:
		push_warning("NIGHTWIRE: town map data has an invalid structure.")
		return false
	var candidate: Array[Dictionary] = []
	var seen: Dictionary = {}
	for item: Variant in parsed["locations"]:
		if not item is Dictionary:
			return false
		var location: Dictionary = item
		var id: String = str(location.get("id", ""))
		var name: String = str(location.get("name", ""))
		var position: Variant = location.get("position", null)
		if id.is_empty() or name.is_empty() or seen.has(id) or not position is Array or position.size() != 2:
			return false
		var x: float = float(position[0])
		var y: float = float(position[1])
		if x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0:
			return false
		seen[id] = true
		candidate.append(location)
	locations = candidate
	return true

func get_locations() -> Array[Dictionary]:
	return locations.duplicate(true)

func select_location(location_id: String) -> bool:
	for location: Dictionary in locations:
		if str(location.get("id", "")) == location_id:
			selected_id = location_id
			location_selected.emit(location.duplicate(true))
			queue_redraw()
			return true
	return false

func _draw() -> void:
	var bounds: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(bounds, MAP_COLOR, true)
	var step: float = 56.0
	var x: float = 0.0
	while x < size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), GRID_COLOR, 1.0)
		x += step
	var y: float = 0.0
	while y < size.y:
		draw_line(Vector2(0, y), Vector2(size.x, y), GRID_COLOR, 1.0)
		y += step
	var road_paths: Array[PackedVector2Array] = [
		PackedVector2Array([_point(0.04, 0.30), _point(0.32, 0.30), _point(0.50, 0.18), _point(0.72, 0.30), _point(0.96, 0.30)]),
		PackedVector2Array([_point(0.08, 0.52), _point(0.30, 0.52), _point(0.50, 0.58), _point(0.72, 0.52), _point(0.94, 0.52)]),
		PackedVector2Array([_point(0.12, 0.88), _point(0.32, 0.72), _point(0.50, 0.58), _point(0.68, 0.72), _point(0.90, 0.88)]),
		PackedVector2Array([_point(0.32, 0.08), _point(0.32, 0.30), _point(0.30, 0.52), _point(0.32, 0.72), _point(0.32, 0.94)]),
		PackedVector2Array([_point(0.68, 0.08), _point(0.72, 0.30), _point(0.72, 0.52), _point(0.68, 0.72), _point(0.68, 0.94)])
	]
	for path: PackedVector2Array in road_paths:
		draw_polyline(path, ROAD_COLOR, 12.0, true)
		draw_polyline(path, Color("#34464F"), 2.0, true)
	for location: Dictionary in locations:
		var pos: Vector2 = _location_point(location)
		var is_selected: bool = str(location.get("id", "")) == selected_id
		draw_circle(pos, 18.0 if is_selected else 13.0, Color("#FF3B30", 0.18))
		draw_circle(pos, 7.0 if is_selected else 5.0, PIN_COLOR)
		draw_string(ThemeDB.fallback_font, pos + Vector2(14, -12), str(location.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, TEXT_COLOR)
	var label_pos: Vector2 = Vector2(20, size.y - 24)
	draw_string(ThemeDB.fallback_font, label_pos, "NIGHTWIRE CITY GRID  /  LOCAL MAP DATA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#00E5FF"))

func _point(x: float, y: float) -> Vector2:
	return Vector2(size.x * x, size.y * y)

func _location_point(location: Dictionary) -> Vector2:
	var position: Array = location.get("position", [0.5, 0.5])
	return _point(float(position[0]), float(position[1]))

func _build_pins() -> void:
	for button: Button in pin_buttons:
		button.queue_free()
	pin_buttons.clear()
	for location: Dictionary in locations:
		var button: Button = Button.new()
		button.text = "＋"
		button.tooltip_text = str(location.get("name", "Location"))
		button.custom_minimum_size = Vector2(44, 44)
		button.add_theme_color_override("font_color", Color("#FFFFFF"))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("#241416")
		style.border_color = PIN_COLOR
		style.set_border_width_all(1)
		style.set_corner_radius_all(22)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style.duplicate())
		button.pressed.connect(select_location.bind(str(location.get("id", ""))))
		add_child(button)
		pin_buttons.append(button)
	_layout_pins()

func _layout_pins() -> void:
	for index: int in range(mini(pin_buttons.size(), locations.size())):
		var point: Vector2 = _location_point(locations[index])
		pin_buttons[index].position = point - pin_buttons[index].custom_minimum_size * 0.5
