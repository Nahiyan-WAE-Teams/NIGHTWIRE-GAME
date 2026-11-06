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
var active_screen: String = "inbox"
var active_conversation_id: String = ""
var message_input: LineEdit
var message_scroll: ScrollContainer
var navigation: HBoxContainer
var nav_buttons: Dictionary = {}

func _ready() -> void:
	_build_shell()
	_render_screen()
	ChatManager.conversations_changed.connect(_on_conversations_changed)
	EvidenceManager.evidence_changed.connect(_on_evidence_changed)

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
	safe_margin.add_theme_constant_override("margin_left", 32)
	safe_margin.add_theme_constant_override("margin_right", 32)
	safe_margin.add_theme_constant_override("margin_top", 48)
	safe_margin.add_theme_constant_override("margin_bottom", 28)
	add_child(safe_margin)

	var shell: VBoxContainer = VBoxContainer.new()
	shell.add_theme_constant_override("separation", 20)
	safe_margin.add_child(shell)
	_add_brand_header(shell)

	page = VBoxContainer.new()
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 18)
	shell.add_child(page)
	navigation = _build_navigation()
	shell.add_child(navigation)

func _add_brand_header(parent: VBoxContainer) -> void:
	var header: HBoxContainer = HBoxContainer.new()
	var brand: VBoxContainer = VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.add_child(_label("NIGHTWIRE", 34, TEXT_MAIN, true))
	brand.add_child(_label("SOMEONE IS ALWAYS LISTENING.", 12, TEXT_MUTED, true))
	header.add_child(brand)
	var status: PanelContainer = PanelContainer.new()
	status.add_theme_stylebox_override("panel", _panel_style(Color("#171216"), Color("#4B2427"), 16))
	status.add_child(_label("●  OFFLINE", 13, ACCENT_RED, true))
	header.add_child(status)
	parent.add_child(header)

func _build_navigation() -> HBoxContainer:
	var nav: HBoxContainer = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 8)
	nav.add_child(_nav_button("CHATS", "inbox"))
	nav.add_child(_nav_button("EVIDENCE", "evidence"))
	nav.add_child(_nav_button("PEOPLE", "people"))
	nav.add_child(_nav_button("SETTINGS", "settings"))
	return nav

func _nav_button(caption: String, screen_id: String) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 58
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", ACCENT_CYAN if active_screen == screen_id else TEXT_MUTED)
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED if active_screen == screen_id else SURFACE, ACCENT_CYAN if active_screen == screen_id else BORDER, 14))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 14))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(_navigate.bind(screen_id))
	nav_buttons[screen_id] = button
	return button

func _render_screen() -> void:
	_update_navigation()
	_clear_page()
	match active_screen:
		"inbox":
			_render_inbox()
		"chat":
			_render_chat()
		"evidence":
			_render_evidence()
		"people":
			_render_people()
		"settings":
			_render_settings()
		_:
			active_screen = "inbox"
			_render_inbox()

func _render_inbox() -> void:
	var heading: HBoxContainer = HBoxContainer.new()
	var title: Label = _label("MESSAGES", 25, TEXT_MAIN, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(_label("%02d CONTACTS" % ChatManager.get_conversations().size(), 13, ACCENT_CYAN, true))
	page.add_child(heading)
	page.add_child(_label("PRIVATE CHANNELS  /  DEVICE STORAGE", 12, TEXT_MUTED))

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)

	for conversation: Dictionary in ChatManager.get_conversations():
		list.add_child(_conversation_card(conversation))

func _update_navigation() -> void:
	for screen_id: Variant in nav_buttons.keys():
		var button: Button = nav_buttons[screen_id]
		var selected: bool = str(screen_id) == active_screen
		button.add_theme_color_override("font_color", ACCENT_CYAN if selected else TEXT_MUTED)
		button.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED if selected else SURFACE, ACCENT_CYAN if selected else BORDER, 14))

func _conversation_card(conversation: Dictionary) -> Control:
	var conversation_id: String = str(conversation.get("id", ""))
	var button: Button = Button.new()
	button.custom_minimum_size.y = 112
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = ""
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 20))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 20))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#20202A"), ACCENT_CYAN, 20))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(_open_chat.bind(conversation_id))
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	button.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)
	var avatar: PanelContainer = PanelContainer.new()
	avatar.custom_minimum_size = Vector2(68, 68)
	avatar.add_theme_stylebox_override("panel", _panel_style(Color("#20202A"), ACCENT_CYAN if str(conversation.get("status", "")) == "online" else BORDER, 34))
	var initials: String = str(conversation.get("name", "??")).substr(0, 1).to_upper()
	var avatar_text: Label = _label(initials, 25, ACCENT_CYAN, true)
	avatar_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(avatar_text)
	row.add_child(avatar)
	var details: VBoxContainer = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 5)
	var name_row: HBoxContainer = HBoxContainer.new()
	var name_label: Label = _label(str(conversation.get("name", "Unknown")), 19, TEXT_MAIN, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	var unread: int = int(conversation.get("unread", 0))
	if unread > 0:
		name_row.add_child(_label(str(unread).pad_zeros(2), 13, ACCENT_RED, true))
	details.add_child(name_row)
	details.add_child(_label(str(conversation.get("role", "Story character")), 13, TEXT_MUTED))
	var preview: Label = _label(str(conversation.get("preview", "No messages yet")), 14, TEXT_MUTED)
	preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(preview)
	row.add_child(details)
	row.add_child(_label("›", 28, ACCENT_CYAN))
	return button

func _render_chat() -> void:
	var conversation: Dictionary = ChatManager.get_conversation(active_conversation_id)
	if conversation.is_empty():
		active_screen = "inbox"
		_render_inbox()
		return
	var top: HBoxContainer = HBoxContainer.new()
	top.add_child(_small_button("‹", _back_to_inbox, 58))
	var identity: VBoxContainer = VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_child(_label(str(conversation.get("name", "Unknown")), 21, TEXT_MAIN, true))
	identity.add_child(_label(str(conversation.get("role", "STORY CONTACT")), 12, ACCENT_CYAN, true))
	top.add_child(identity)
	top.add_child(_label("LOCAL", 12, TEXT_MUTED, true))
	page.add_child(top)
	var divider: ColorRect = ColorRect.new()
	divider.color = BORDER
	divider.custom_minimum_size.y = 1
	page.add_child(divider)

	message_scroll = ScrollContainer.new()
	message_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(message_scroll)
	var stack: VBoxContainer = VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 14)
	message_scroll.add_child(stack)
	var messages: Array[Dictionary] = ChatManager.get_messages(active_conversation_id)
	if messages.is_empty():
		var empty: PanelContainer = PanelContainer.new()
		empty.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 18))
		empty.add_child(_label("This channel is quiet.\nConversation content will appear when you add an episode file.", 16, TEXT_MUTED))
		stack.add_child(empty)
	else:
		for message: Dictionary in messages:
			stack.add_child(_message_bubble(message))

	var composer: HBoxContainer = HBoxContainer.new()
	composer.add_theme_constant_override("separation", 10)
	message_input = LineEdit.new()
	message_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_input.custom_minimum_size.y = 62
	message_input.placeholder_text = "Write a message..."
	message_input.add_theme_font_size_override("font_size", 17)
	message_input.add_theme_color_override("font_color", TEXT_MAIN)
	message_input.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 16))
	message_input.add_theme_stylebox_override("focus", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 16))
	message_input.text_submitted.connect(_send_message)
	composer.add_child(message_input)
	composer.add_child(_small_button("↑", _send_current_message, 62))
	page.add_child(composer)
	_scroll_to_latest.call_deferred()

func _message_bubble(message: Dictionary) -> Control:
	var is_player: bool = str(message.get("sender", "")) == "player"
	var line: HBoxContainer = HBoxContainer.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bubble: PanelContainer = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.add_theme_stylebox_override("panel", _panel_style(Color("#17242A") if is_player else SURFACE_RAISED, ACCENT_CYAN if is_player else BORDER, 18))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	bubble.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var body: Label = _label(str(message.get("text", "")), 17, TEXT_MAIN)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 240
	content.add_child(body)
	var time_label: Label = _label(str(message.get("time", "")), 10, TEXT_MUTED)
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

func _render_evidence() -> void:
	page.add_child(_label("EVIDENCE", 25, TEXT_MAIN, true))
	page.add_child(_label("THE DETAILS THAT REFUSE TO STAY BURIED.", 12, TEXT_MUTED))
	var records: Array[Dictionary] = EvidenceManager.get_unlocked()
	if records.is_empty():
		page.add_child(_empty_panel("No evidence collected yet.\nEpisode choices can unlock photos, files, recordings and clues here."))
		return
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	for record: Dictionary in records:
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 18))
		var content: VBoxContainer = VBoxContainer.new()
		content.add_child(_label(str(record.get("title", "Evidence")), 18, TEXT_MAIN, true))
		content.add_child(_label(str(record.get("description", "")), 14, TEXT_MUTED))
		card.add_child(content)
		list.add_child(card)

func _render_people() -> void:
	page.add_child(_label("THE CONTACTS", 25, TEXT_MAIN, true))
	page.add_child(_label("20 CHARACTER SLOTS  /  PROFILES ARE CONTENT-DRIVEN", 12, TEXT_MUTED))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for profile: Dictionary in ContentManager.get_characters():
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 16))
		var row: HBoxContainer = HBoxContainer.new()
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_child(_label(str(profile.get("name", "Character")), 17, TEXT_MAIN, true))
		info.add_child(_label(str(profile.get("role", "Unassigned role")), 13, TEXT_MUTED))
		row.add_child(info)
		row.add_child(_label(str(profile.get("status", "inactive")).to_upper(), 11, ACCENT_CYAN))
		card.add_child(row)
		list.add_child(card)

func _render_settings() -> void:
	page.add_child(_label("SYSTEM", 25, TEXT_MAIN, true))
	page.add_child(_empty_panel("NIGHTWIRE runs offline.\nMessages, trust, flags and evidence are stored locally with encrypted save-file support."))
	page.add_child(_label("CONTENT PIPELINE", 15, ACCENT_CYAN, true))
	page.add_child(_empty_panel("Add character profiles in data/characters/roster.json.\nAdd one JSON file per episode in data/episodes/.\nThe content validator checks node links before an episode is loaded."))
	var reset_button: Button = Button.new()
	reset_button.text = "RESET LOCAL GAME DATA"
	reset_button.custom_minimum_size.y = 60
	reset_button.add_theme_color_override("font_color", ACCENT_RED)
	reset_button.add_theme_stylebox_override("normal", _panel_style(Color("#171216"), Color("#4B2427"), 16))
	reset_button.pressed.connect(_confirm_reset)
	page.add_child(reset_button)

func _empty_panel(message: String) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 18))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var label: Label = _label(message, 15, TEXT_MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	margin.add_child(label)
	return panel

func _small_button(caption: String, action: Callable, side: int) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(side, side)
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", ACCENT_CYAN)
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 16))
	button.add_theme_stylebox_override("hover", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 16))
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
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _open_chat(conversation_id: String) -> void:
	active_conversation_id = conversation_id
	ChatManager.mark_read(conversation_id)
	active_screen = "chat"
	_render_screen()

func _back_to_inbox() -> void:
	active_screen = "inbox"
	_render_screen()

func _send_current_message() -> void:
	if is_instance_valid(message_input):
		_send_message(message_input.text)

func _send_message(value: String) -> void:
	if ChatManager.send_message(active_conversation_id, value):
		_render_screen()

func _navigate(screen_id: String) -> void:
	active_screen = screen_id
	active_conversation_id = ""
	_render_screen()

func _confirm_reset() -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.dialog_text = "Erase all local conversations, trust, flags and evidence?"
	dialog.confirmed.connect(_reset_local_data)
	add_child(dialog)
	dialog.popup_centered()

func _reset_local_data() -> void:
	SaveManager.reset_all()
	ChatManager.reset_conversations()
	EvidenceManager.clear_evidence()
	StoryManager.reset_progress()
	get_tree().reload_current_scene()

func _on_conversations_changed() -> void:
	if active_screen == "inbox":
		_render_screen()

func _on_evidence_changed() -> void:
	if active_screen == "evidence":
		_render_screen()

func _scroll_to_latest() -> void:
	if is_instance_valid(message_scroll):
		message_scroll.scroll_vertical = int(message_scroll.get_v_scroll_bar().max_value)

func _clear_page() -> void:
	for child: Node in page.get_children():
		child.queue_free()
