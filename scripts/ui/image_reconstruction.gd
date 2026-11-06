extends VBoxContainer

signal order_verified

const EXPECTED_ORDER: Array[int] = [1, 2, 3, 4]
const START_ORDER: Array[int] = [3, 1, 4, 2]
const TILE_NAMES: Array[String] = ["FRAME 01", "FRAME 02", "FRAME 03", "FRAME 04"]

var tile_order: Array[int] = START_ORDER.duplicate()
var selected_index: int = -1
var tile_buttons: Array[Button] = []
var status_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("#111116")
	style.border_color = Color("#292932")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	var title: Label = Label.new()
	title.text = "03  IMAGE RECONSTRUCTION"
	title.add_theme_color_override("font_color", Color("#00E5FF"))
	title.add_theme_font_size_override("font_size", 17)
	content.add_child(title)
	var hint: Label = Label.new()
	hint.text = "Select two frames to swap their positions. Rebuild the sequence."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Color("#858591"))
	content.add_child(hint)
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)
	for index: int in range(tile_order.size()):
		var tile: Button = Button.new()
		tile.custom_minimum_size = Vector2(0, 64)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.add_theme_color_override("font_color", Color("#EAEAEA"))
		tile.add_theme_stylebox_override("normal", _tile_style(false))
		tile.pressed.connect(_select_tile.bind(index))
		tile_buttons.append(tile)
		grid.add_child(tile)
	status_label = Label.new()
	status_label.text = "SEQUENCE CORRUPTED"
	status_label.add_theme_color_override("font_color", Color("#858591"))
	content.add_child(status_label)
	var verify: Button = Button.new()
	verify.text = "RECONSTRUCT FRAME ORDER"
	verify.custom_minimum_size.y = 52
	verify.add_theme_color_override("font_color", Color("#00E5FF"))
	verify.pressed.connect(_verify_order)
	content.add_child(verify)
	_refresh_tiles()

func _tile_style(selected: bool) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("#20202A") if selected else Color("#191920")
	style.border_color = Color("#00E5FF") if selected else Color("#292932")
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(12)
	return style

func _select_tile(index: int) -> void:
	if selected_index == -1:
		selected_index = index
	else:
		if selected_index != index:
			swap_positions(selected_index, index)
		selected_index = -1
	_refresh_tiles()

func swap_positions(first: int, second: int) -> bool:
	if first < 0 or second < 0 or first >= tile_order.size() or second >= tile_order.size() or first == second:
		return false
	var value: int = tile_order[first]
	tile_order[first] = tile_order[second]
	tile_order[second] = value
	return true

func get_order() -> Array[int]:
	return tile_order.duplicate()

func is_solved() -> bool:
	return PuzzleManager.validate_image_order(EXPECTED_ORDER, tile_order)

func _verify_order() -> void:
	if is_solved():
		status_label.text = "IMAGE RESTORED  /  CLUE SYNCHRONIZED"
		status_label.add_theme_color_override("font_color", Color("#00E5FF"))
		order_verified.emit()
	else:
		status_label.text = "NOT YET  /  CHECK THE FRAME ORDER"
		status_label.add_theme_color_override("font_color", Color("#FF3B30"))

func _refresh_tiles() -> void:
	for index: int in range(tile_buttons.size()):
		var button: Button = tile_buttons[index]
		button.text = TILE_NAMES[tile_order[index] - 1] + "  /  " + str(tile_order[index])
		button.add_theme_stylebox_override("normal", _tile_style(index == selected_index))
