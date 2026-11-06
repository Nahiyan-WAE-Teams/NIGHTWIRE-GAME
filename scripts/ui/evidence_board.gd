extends Control

signal evidence_selected(record: Dictionary)

const CARD_HEIGHT: float = 176.0
const COLUMN_GAP: float = 14.0
const ROW_GAP: float = 16.0
const BOARD_INSET: float = 10.0
const MIN_BOARD_WIDTH: float = 300.0

var records: Array[Dictionary] = []
var card_buttons: Array[Button] = []
var layout_queued: bool = false

func _ready() -> void:
	custom_minimum_size = Vector2(MIN_BOARD_WIDTH, 220.0)
	_build_cards()
	resized.connect(_queue_layout)
	_queue_layout()

func _column_count() -> int:
	return 2 if size.x < 700.0 else 3

func _card_width() -> float:
	var columns: int = _column_count()
	var available: float = maxf(size.x, MIN_BOARD_WIDTH)
	return maxf(0.0, (available - BOARD_INSET * 2.0 - COLUMN_GAP * float(columns - 1)) / float(columns))

func _row_count() -> int:
	if records.is_empty():
		return 0
	return ceili(float(records.size()) / float(_column_count()))

func _card_position(index: int) -> Vector2:
	var columns: int = _column_count()
	var column: int = index % columns
	var row: int = floori(float(index) / float(columns))
	return Vector2(BOARD_INSET + float(column) * (_card_width() + COLUMN_GAP), BOARD_INSET + float(row) * (CARD_HEIGHT + ROW_GAP))

func _draw() -> void:
	if records.size() < 2:
		return
	for index: int in range(records.size() - 1):
		var start: Vector2 = _card_position(index) + Vector2(_card_width() * 0.5, CARD_HEIGHT * 0.5)
		var finish: Vector2 = _card_position(index + 1) + Vector2(_card_width() * 0.5, CARD_HEIGHT * 0.5)
		draw_line(start, finish, Color("#8D292B"), 2.0, true)
		draw_circle(start, 4.0, Color("#FF3B30"))
	var last: Vector2 = _card_position(records.size() - 1) + Vector2(_card_width() * 0.5, CARD_HEIGHT * 0.5)
	draw_circle(last, 4.0, Color("#FF3B30"))

func _build_cards() -> void:
	for record: Dictionary in records:
		var card: Button = Button.new()
		card.custom_minimum_size = Vector2(MIN_BOARD_WIDTH * 0.5, CARD_HEIGHT)
		card.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		card.text = "▰  " + str(record.get("title", "Evidence")) + "\n\n" + str(record.get("description", "Unclassified clue"))
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_font_size_override("font_size", 16)
		card.add_theme_color_override("font_color", Color("#EAEAEA"))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("#17171D")
		style.border_color = Color("#633033")
		style.set_border_width_all(1)
		style.set_corner_radius_all(14)
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 12.0
		style.content_margin_bottom = 12.0
		card.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover.border_color = Color("#FF3B30")
		card.add_theme_stylebox_override("hover", hover)
		card.pressed.connect(_select_record.bind(record))
		card_buttons.append(card)
		add_child(card)

func _queue_layout() -> void:
	if layout_queued:
		return
	layout_queued = true
	call_deferred("_apply_layout")

func _apply_layout() -> void:
	layout_queued = false
	if not is_inside_tree():
		return
	var card_width: float = _card_width()
	for index: int in range(card_buttons.size()):
		var card: Button = card_buttons[index]
		if not is_instance_valid(card):
			continue
		card.position = _card_position(index)
		card.size = Vector2(card_width, CARD_HEIGHT)
	var required_height: float = maxf(220.0, float(_row_count()) * (CARD_HEIGHT + ROW_GAP) + BOARD_INSET * 2.0)
	if not is_equal_approx(custom_minimum_size.y, required_height):
		custom_minimum_size.y = required_height
	queue_redraw()

func _select_record(record: Dictionary) -> void:
	evidence_selected.emit(record)
