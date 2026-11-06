extends Control

signal evidence_selected(record: Dictionary)

const CARD_HEIGHT: float = 154.0
const COLUMN_GAP: float = 16.0
const ROW_GAP: float = 28.0
const BOARD_INSET: float = 12.0

var records: Array[Dictionary] = []
var card_buttons: Array[Button] = []

func _ready() -> void:
	custom_minimum_size = Vector2(440.0, 220.0)
	_build_cards()
	resized.connect(_layout_cards)
	_layout_cards()
	queue_redraw()

func _column_count() -> int:
	return 3 if size.x >= 780.0 else 2

func _card_width() -> float:
	var columns: int = _column_count()
	var available: float = maxf(size.x, 440.0)
	return maxf(150.0, (available - BOARD_INSET * 2.0 - COLUMN_GAP * float(columns - 1)) / float(columns))

func _row_count() -> int:
	return ceili(float(records.size()) / float(_column_count()))

func _card_position(index: int) -> Vector2:
	var columns: int = _column_count()
	var column: int = index % columns
	var row: int = index / columns
	return Vector2(BOARD_INSET + float(column) * (_card_width() + COLUMN_GAP), BOARD_INSET + float(row) * (CARD_HEIGHT + ROW_GAP))

func _draw() -> void:
	for index: int in range(records.size() - 1):
		var start: Vector2 = _card_position(index) + Vector2(_card_width() * 0.5, CARD_HEIGHT * 0.5)
		var finish: Vector2 = _card_position(index + 1) + Vector2(_card_width() * 0.5, CARD_HEIGHT * 0.5)
		draw_line(start, finish, Color("#8D292B"), 3.0, true)
		draw_circle(start, 5.0, Color("#FF3B30"))
	if not records.is_empty():
		var last: Vector2 = _card_position(records.size() - 1) + Vector2(_card_width() * 0.5, CARD_HEIGHT * 0.5)
		draw_circle(last, 5.0, Color("#FF3B30"))

func _build_cards() -> void:
	for record: Dictionary in records:
		var card: Button = Button.new()
		card.custom_minimum_size.y = CARD_HEIGHT
		card.text = "▰  " + str(record.get("title", "Evidence")) + "\\n\\n" + str(record.get("description", "Unclassified clue"))
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 14)
		card.add_theme_color_override("font_color", Color("#EAEAEA"))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("#17171D")
		style.border_color = Color("#633033")
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 10.0
		style.content_margin_bottom = 10.0
		card.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover.border_color = Color("#FF3B30")
		card.add_theme_stylebox_override("hover", hover)
		card.pressed.connect(_select_record.bind(record))
		card_buttons.append(card)
		add_child(card)

func _layout_cards() -> void:
	for index: int in range(card_buttons.size()):
		var card: Button = card_buttons[index]
		card.position = _card_position(index)
		card.custom_minimum_size = Vector2(_card_width(), CARD_HEIGHT)
		card.size = card.custom_minimum_size
	custom_minimum_size.y = maxf(220.0, float(_row_count()) * (CARD_HEIGHT + ROW_GAP) + BOARD_INSET * 2.0)
	queue_redraw()

func _select_record(record: Dictionary) -> void:
	evidence_selected.emit(record)
