extends Control

signal evidence_selected(record: Dictionary)

const CARD_WIDTH: float = 310.0
const CARD_HEIGHT: float = 154.0
const COLUMN_GAP: float = 24.0
const ROW_GAP: float = 34.0
const BOARD_INSET: float = 12.0

var records: Array[Dictionary] = []

func _ready() -> void:
	custom_minimum_size = Vector2(1000.0, maxf(220.0, _row_count() * (CARD_HEIGHT + ROW_GAP) + 32.0))
	_build_cards()
	queue_redraw()

func _row_count() -> int:
	return ceili(float(records.size()) / 3.0)

func _card_position(index: int) -> Vector2:
	var column: int = index % 3
	var row: int = index / 3
	return Vector2(BOARD_INSET + column * (CARD_WIDTH + COLUMN_GAP), BOARD_INSET + row * (CARD_HEIGHT + ROW_GAP))

func _draw() -> void:
	for index: int in range(records.size() - 1):
		var start: Vector2 = _card_position(index) + Vector2(CARD_WIDTH * 0.5, CARD_HEIGHT * 0.5)
		var finish: Vector2 = _card_position(index + 1) + Vector2(CARD_WIDTH * 0.5, CARD_HEIGHT * 0.5)
		draw_line(start, finish, Color("#8D292B"), 3.0, true)
		draw_circle(start, 5.0, Color("#FF3B30"))
	if not records.is_empty():
		var last: Vector2 = _card_position(records.size() - 1) + Vector2(CARD_WIDTH * 0.5, CARD_HEIGHT * 0.5)
		draw_circle(last, 5.0, Color("#FF3B30"))

func _build_cards() -> void:
	for index: int in range(records.size()):
		var record: Dictionary = records[index]
		var card: Button = Button.new()
		card.position = _card_position(index)
		card.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card.size = card.custom_minimum_size
		card.text = "▰  " + str(record.get("title", "Evidence")) + "\\n\\n" + str(record.get("description", "Unclassified clue"))
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 16)
		card.add_theme_color_override("font_color", Color("#EAEAEA"))
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color("#17171D")
		style.border_color = Color("#633033")
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.content_margin_left = 14.0
		style.content_margin_right = 14.0
		style.content_margin_top = 12.0
		style.content_margin_bottom = 12.0
		card.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover.border_color = Color("#FF3B30")
		card.add_theme_stylebox_override("hover", hover)
		card.pressed.connect(_select_record.bind(record))
		add_child(card)

func _select_record(record: Dictionary) -> void:
	evidence_selected.emit(record)
