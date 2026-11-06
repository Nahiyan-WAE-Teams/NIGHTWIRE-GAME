extends Control

const BG: Color = Color("#08080A")
const SURFACE: Color = Color("#111116")
const SURFACE_RAISED: Color = Color("#191920")
const BORDER: Color = Color("#292932")
const TEXT_MAIN: Color = Color("#EAEAEA")
const TEXT_MUTED: Color = Color("#858591")
const ACCENT_RED: Color = Color("#FF3B30")
const ACCENT_CYAN: Color = Color("#00E5FF")

var page: VBoxContainer
var active_conversation_id: String = ""
var message_input: LineEdit
var message_scroll: ScrollContainer

func _ready() -> void:
	_build_shell()
	_render_inbox()
	ChatManager.conversations_changed.connect(_on_conversations_changed)

func _build_shell() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background: ColorRect = ColorRect.new()
	background.color = BG
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var safe_margin: MarginContainer = MarginContainer.new()
	safe_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	safe_margin.add_theme_constant_override("margin_left", 34)
	safe_margin.add_theme_constant_override("margin_right", 34)
	safe_margin.add_theme_constant_override("margin_top", 48)
	safe_margin.add_theme_constant_override("margin_bottom", 30)
	add_child(safe_margin)

	page = VBoxContainer.new()
	page.add_theme_constant_override("separation", 22)
	safe_margin.add_child(page)

func _render_inbox() -> void:
	_clear_page()
	_add_brand_header()
	var section: HBoxContainer = HBoxContainer.new()
	section.alignment = BoxContainer.ALIGNMENT_CENTER
	var title: Label = _label("INBOX", 28, TEXT_MAIN, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_child(title)
	section.add_child(_label("LOCAL SESSION", 15, ACCENT_CYAN, true))
	page.add_child(section)

	var divider: ColorRect = ColorRect.new()
	divider.color = BORDER
	divider.custom_minimum_size.y = 1
	page.add_child(divider)

	var conversations: Array[Dictionary] = ChatManager.get_conversations()
	for conversation: Dictionary in conversations:
		var conversation_id: String = str(conversation.get("id", ""))
		var row: Button = Button.new()
		row.custom_minimum_size = Vector2(0, 132)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.text = ""
		row.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 22))
		row.add_theme_stylebox_override("hover", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 22))
		row.add_theme_stylebox_override("pressed", _panel_style(Color("#20202A"), ACCENT_CYAN, 22))
		row.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		row.pressed.connect(_open_chat.bind(conversation_id))
		var row_margin: MarginContainer = MarginContainer.new()
		row_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row_margin.add_theme_constant_override("margin_left", 20)
		row_margin.add_theme_constant_override("margin_right", 20)
		row_margin.add_theme_constant_override("margin_top", 14)
		row_margin.add_theme_constant_override("margin_bottom", 14)
		row.add_child(row_margin)
		var row_layout: HBoxContainer = HBoxContainer.new()
		row_layout.add_theme_constant_override("separation", 16)
		row_layout.alignment = BoxContainer.ALIGNMENT_CENTER
		row_margin.add_child(row_layout)
		var avatar: PanelContainer = PanelContainer.new()
		avatar.custom_minimum_size = Vector2(76, 76)
		avatar.add_theme_stylebox_override("panel", _panel_style(Color("#20202A"), ACCENT_CYAN if conversation_id == "unknown_signal" else BORDER, 38))
		var avatar_label: Label = _label("?", 28, ACCENT_CYAN if conversation_id == "unknown_signal" else TEXT_MUTED, true)
		avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar.add_child(avatar_label)
		row_layout.add_child(avatar)
		var details: VBoxContainer = VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_theme_constant_override("separation", 7)
		var name_row: HBoxContainer = HBoxContainer.new()
		var name_label: Label = _label(str(conversation.get("name", "Unknown")), 21, TEXT_MAIN, true)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_row.add_child(name_label)
		var unread: int = int(conversation.get("unread", 0))
		if unread > 0:
			name_row.add_child(_label(str(unread).pad_zeros(2), 14, ACCENT_RED, true))
		details.add_child(name_row)
		details.add_child(_label(str(conversation.get("subtitle", "")), 14, TEXT_MUTED))
		var preview: Label = _label(str(conversation.get("preview", "")), 15, TEXT_MUTED)
		preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		details.add_child(preview)
		row_layout.add_child(details)
		page.add_child(row)

	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(spacer)
	page.add_child(_footer_note())

func _render_chat() -> void:
	_clear_page()
	var conversation: Dictionary = ChatManager.get_conversation(active_conversation_id)
	if conversation.is_empty():
		_render_inbox()
		return
	var top: HBoxContainer = HBoxContainer.new()
	top.add_child(_small_button("‹", _render_inbox, 64))
	var identity: VBoxContainer = VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(_label(str(conversation.get("name", "Unknown")), 23, TEXT_MAIN, true))
	identity.add_child(_label(str(conversation.get("presence", "OFFLINE")), 13, ACCENT_CYAN, true))
	top.add_child(identity)
	top.add_child(_label("E2E  •  LOCAL", 12, TEXT_MUTED, true))
	page.add_child(top)

	var divider: ColorRect = ColorRect.new()
	divider.color = BORDER
	divider.custom_minimum_size.y = 1
	page.add_child(divider)

	message_scroll = ScrollContainer.new()
	message_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(message_scroll)
	var message_stack: VBoxContainer = VBoxContainer.new()
	message_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_stack.add_theme_constant_override("separation", 14)
	message_scroll.add_child(message_stack)

	for message: Dictionary in ChatManager.get_messages(active_conversation_id):
		message_stack.add_child(_message_bubble(message))

	var composer: HBoxContainer = HBoxContainer.new()
	composer.add_theme_constant_override("separation", 10)
	message_input = LineEdit.new()
	message_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_input.custom_minimum_size.y = 66
	message_input.placeholder_text = "Write a message..."
	message_input.clear_button_enabled = false
	message_input.add_theme_font_size_override("font_size", 18)
	message_input.add_theme_color_override("font_color", TEXT_MAIN)
	message_input.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	message_input.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 18))
	message_input.add_theme_stylebox_override("focus", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 18))
	message_input.text_submitted.connect(_send_message)
	composer.add_child(message_input)
	composer.add_child(_small_button("↑", _send_current_message, 66))
	page.add_child(composer)
	_scroll_to_latest.call_deferred()

func _message_bubble(message: Dictionary) -> Control:
	var is_player: bool = str(message.get("sender", "")) == "player"
	var line: HBoxContainer = HBoxContainer.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bubble: PanelContainer = PanelContainer.new()
	bubble.custom_minimum_size.x = 120
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.add_theme_stylebox_override("panel", _panel_style(Color("#17242A") if is_player else SURFACE_RAISED, ACCENT_CYAN if is_player else BORDER, 18))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 17)
	margin.add_theme_constant_override("margin_right", 17)
	margin.add_theme_constant_override("margin_top", 13)
	margin.add_theme_constant_override("margin_bottom", 12)
	bubble.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	margin.add_child(content)
	var body: Label = _label(str(message.get("text", "")), 18, TEXT_MAIN)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 250
	content.add_child(body)
	var time_label: Label = _label(str(message.get("time", "")), 11, TEXT_MUTED)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	content.add_child(time_label)
	if is_player:
		var left_space: Control = Control.new()
		left_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(left_space)
		line.add_child(bubble)
	else:
		line.add_child(bubble)
		var right_space: Control = Control.new()
		right_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(right_space)
	return line

func _add_brand_header() -> void:
	var brand_row: HBoxContainer = HBoxContainer.new()
	var brand: VBoxContainer = VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(_label("NIGHTWIRE", 34, TEXT_MAIN, true))
	brand.add_child(_label("SOMEONE IS ALWAYS LISTENING.", 12, TEXT_MUTED, true))
	brand_row.add_child(brand)
	var status: PanelContainer = PanelContainer.new()
	status.add_theme_stylebox_override("panel", _panel_style(Color("#171216"), Color("#4B2427"), 16))
	var status_label: Label = _label("●  OFFLINE", 13, ACCENT_RED, true)
	status.add_child(status_label)
	brand_row.add_child(status)
	page.add_child(brand_row)

func _footer_note() -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#101015"), BORDER, 18))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var note: Label = _label("PRIVATE DEVICE  /  NO NETWORK REQUIRED\nYour messages stay on this device.", 13, TEXT_MUTED)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(note)
	return panel

func _small_button(caption: String, action: Callable, height: int) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(height, height)
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", ACCENT_CYAN)
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 18))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 18))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#20202A"), ACCENT_CYAN, 18))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(action)
	return button

func _label(caption: String, size: int, color: Color, bold: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = caption
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
	return label

func _panel_style(fill: Color, stroke: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = stroke
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _open_chat(conversation_id: String) -> void:
	active_conversation_id = conversation_id
	ChatManager.mark_read(conversation_id)
	_render_chat()

func _send_current_message() -> void:
	if message_input != null:
		_send_message(message_input.text)

func _send_message(value: String) -> void:
	if ChatManager.send_message(active_conversation_id, value):
		_render_chat()

func _on_conversations_changed() -> void:
	if active_conversation_id.is_empty():
		_render_inbox()

func _scroll_to_latest() -> void:
	if is_instance_valid(message_scroll):
		message_scroll.scroll_vertical = int(message_scroll.get_v_scroll_bar().max_value)

func _clear_page() -> void:
	for child: Node in page.get_children():
		child.queue_free()
