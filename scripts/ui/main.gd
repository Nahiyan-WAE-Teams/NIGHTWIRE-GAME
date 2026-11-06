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
var call_mute_button: Button
var navigation: HBoxContainer
var nav_buttons: Dictionary = {}
var inbox_search: LineEdit
var inbox_list: VBoxContainer
var nav_popup: PopupMenu
var brand_header: HBoxContainer
var navigation_dock: PanelContainer
var pattern_entry: Array[int] = []
var pattern_feedback: String = "NO INPUT YET"
var password_feedback: String = "AWAITING DECRYPTION"

func _ready() -> void:
	_build_shell()
	_render_screen()
	ChatManager.conversations_changed.connect(_on_conversations_changed)
	EvidenceManager.evidence_changed.connect(_on_evidence_changed)
	StoryManager.story_node_changed.connect(_on_story_node_changed)

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
	safe_margin.add_theme_constant_override("margin_left", 14)
	safe_margin.add_theme_constant_override("margin_right", 14)
	safe_margin.add_theme_constant_override("margin_top", 10)
	safe_margin.add_theme_constant_override("margin_bottom", 8)
	add_child(safe_margin)

	var shell: VBoxContainer = VBoxContainer.new()
	shell.add_theme_constant_override("separation", 8)
	safe_margin.add_child(shell)
	brand_header = _add_brand_header(shell)

	page = VBoxContainer.new()
	page.name = "ScreenContent"
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 14)
	shell.add_child(page)
	navigation_dock = PanelContainer.new()
	navigation_dock.name = "NavigationDock"
	navigation_dock.add_theme_stylebox_override("panel", _panel_style(Color("#101015"), Color("#30303B"), 22))
	var dock_margin: MarginContainer = MarginContainer.new()
	dock_margin.add_theme_constant_override("margin_left", 7)
	dock_margin.add_theme_constant_override("margin_right", 7)
	dock_margin.add_theme_constant_override("margin_top", 7)
	dock_margin.add_theme_constant_override("margin_bottom", 7)
	navigation_dock.add_child(dock_margin)
	navigation = _build_navigation()
	dock_margin.add_child(navigation)
	shell.add_child(navigation_dock)

func _add_brand_header(parent: VBoxContainer) -> HBoxContainer:
	var header: HBoxContainer = HBoxContainer.new()
	header.custom_minimum_size.y = 34.0
	header.add_theme_constant_override("separation", 8)
	var brand: Label = _label("NIGHTWIRE", 17, TEXT_MAIN, true)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	var status: HBoxContainer = HBoxContainer.new()
	status.add_theme_constant_override("separation", 5)
	var signal_dot: Label = _label("●", 9, ACCENT_RED, true)
	status.add_child(signal_dot)
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(signal_dot, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(signal_dot, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	status.add_child(_label("PRIVATE SIGNAL", 9, TEXT_MUTED, true))
	header.add_child(status)
	parent.add_child(header)
	var hairline: ColorRect = ColorRect.new()
	hairline.color = Color("#25252E")
	hairline.custom_minimum_size.y = 1
	parent.add_child(hairline)
	return header

func _build_navigation() -> HBoxContainer:
	var nav: HBoxContainer = HBoxContainer.new()
	nav.name = "NavigationButtons"
	nav.add_theme_constant_override("separation", 2)
	nav.add_child(_nav_button("MESSAGES", "inbox"))
	nav.add_child(_nav_button("CONTACTS", "people"))
	nav.add_child(_nav_button("CLUES", "evidence"))
	nav.add_child(_nav_button("MORE", "more"))
	return nav

func _nav_button(caption: String, screen_id: String) -> Button:
	var button: Button = Button.new()
	button.name = "Nav_" + screen_id.capitalize()
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", ACCENT_CYAN if active_screen == screen_id else TEXT_MUTED)
	button.add_theme_stylebox_override("normal", _panel_style(Color("#20232B") if active_screen == screen_id else Color("#101015"), Color("#24515A") if active_screen == screen_id else Color("#101015"), 15))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#20232B"), Color("#247B87"), 15))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#26323A"), ACCENT_CYAN, 15))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if screen_id == "more":
		button.pressed.connect(_open_more_menu)
	else:
		button.pressed.connect(_navigate.bind(screen_id))
	button.pressed.connect(_pulse_haptic)
	button.pressed.connect(_animate_press.bind(button))
	nav_buttons[screen_id] = button
	return button

func _open_more_menu() -> void:
	if nav_popup == null:
		nav_popup = PopupMenu.new()
		nav_popup.add_item("CITY MAP", 0)
		nav_popup.add_item("STORY FILES", 1)
		nav_popup.add_item("SIGNAL LAB", 2)
		nav_popup.add_item("SYSTEM SETTINGS", 3)
		nav_popup.id_pressed.connect(_on_more_menu_selected)
		add_child(nav_popup)
	nav_popup.popup_centered(Vector2i(280, 250))

func _on_more_menu_selected(item_id: int) -> void:
	match item_id:
		0:
			_navigate("map")
		1:
			_navigate("story")
		2:
			_navigate("hack")
		3:
			_navigate("settings")

func _render_screen() -> void:
	var immersive_chat: bool = active_screen == "chat"
	brand_header.visible = not immersive_chat
	navigation_dock.visible = not immersive_chat
	page.add_theme_constant_override("separation", 8 if immersive_chat else 14)
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
		"map":
			_render_map()
		"story":
			_render_story()
		"hack":
			_render_hack()
		"settings":
			_render_settings()
		_:
			active_screen = "inbox"
			_render_inbox()
	_animate_page()

func _render_inbox() -> void:
	var heading: HBoxContainer = HBoxContainer.new()
	var title_group: VBoxContainer = VBoxContainer.new()
	title_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_group.add_child(_label("Messages", 27, TEXT_MAIN, true))
	title_group.add_child(_label("PRIVATE CONVERSATIONS", 9, TEXT_MUTED, true))
	heading.add_child(title_group)
	var count: PanelContainer = PanelContainer.new()
	count.add_theme_stylebox_override("panel", _panel_style(Color("#111116"), Color("#292932"), 12))
	count.add_child(_label("%02d" % ChatManager.get_conversations().size(), 13, TEXT_MUTED, true))
	heading.add_child(count)
	page.add_child(heading)
	inbox_search = LineEdit.new()
	inbox_search.name = "InboxSearch"
	inbox_search.placeholder_text = "Search contacts or messages"
	inbox_search.clear_button_enabled = true
	inbox_search.custom_minimum_size.y = 42
	inbox_search.add_theme_font_size_override("font_size", 13)
	inbox_search.add_theme_color_override("font_color", TEXT_MAIN)
	inbox_search.add_theme_color_override("font_placeholder_color", Color("#686875"))
	inbox_search.add_theme_stylebox_override("normal", _panel_style(Color("#111117"), Color("#292A35"), 15))
	inbox_search.add_theme_stylebox_override("focus", _panel_style(Color("#151A20"), Color("#247B87"), 15))
	inbox_search.text_changed.connect(_filter_conversations)
	page.add_child(inbox_search)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	inbox_list = VBoxContainer.new()
	inbox_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inbox_list.add_theme_constant_override("separation", 0)
	scroll.add_child(inbox_list)

	var index: int = 0
	for conversation: Dictionary in ChatManager.get_conversations():
		var card: Control = _conversation_card(conversation)
		inbox_list.add_child(card)
		_animate_in(card, float(index) * 0.025)
		index += 1

func _filter_conversations(query: String) -> void:
	var normalized: String = query.strip_edges().to_lower()
	if not is_instance_valid(inbox_list):
		return
	for child: Node in inbox_list.get_children():
		if child is Control:
			var searchable: String = str(child.get_meta("search_text", ""))
			child.visible = normalized.is_empty() or searchable.contains(normalized)

func _update_navigation() -> void:
	var more_selected: bool = active_screen in ["map", "story", "hack", "settings"]
	for screen_id: Variant in nav_buttons.keys():
		var button: Button = nav_buttons[screen_id]
		var selected: bool = (str(screen_id) == active_screen) or (str(screen_id) == "inbox" and active_screen == "chat") or (str(screen_id) == "more" and more_selected)
		button.add_theme_color_override("font_color", ACCENT_CYAN if selected else TEXT_MUTED)
		button.add_theme_stylebox_override("normal", _panel_style(Color("#20232B") if selected else Color("#101015"), Color("#24515A") if selected else Color("#101015"), 15))

func _animate_page() -> void:
	if not is_instance_valid(page):
		return
	page.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(page, "modulate:a", 1.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _animate_press(control: Control) -> void:
	if not is_instance_valid(control):
		return
	control.pivot_offset = control.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(control, "scale", Vector2(0.965, 0.965), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_in(control: Control, delay: float = 0.0) -> void:
	control.modulate.a = 0.0
	var destination: Vector2 = control.position
	control.position = destination + Vector2(0.0, 12.0)
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, 0.24).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "position", destination, 0.28).set_delay(delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _conversation_card(conversation: Dictionary) -> Control:
	var conversation_id: String = str(conversation.get("id", ""))
	var button: Button = Button.new()
	button.custom_minimum_size.y = 86.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("search_text", ("%s %s %s" % [str(conversation.get("name", "")), str(conversation.get("role", "")), str(conversation.get("preview", ""))]).to_lower())
	button.text = ""
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", _panel_style(Color("#17171D"), Color("#292932"), 10))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#20202A"), Color("#343440"), 10))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.pressed.connect(_open_chat.bind(conversation_id))
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 5)
	margin.add_theme_constant_override("margin_right", 5)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	button.add_child(margin)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 13)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(row)
	var avatar: PanelContainer = PanelContainer.new()
	avatar.custom_minimum_size = Vector2(58, 58)
	avatar.add_theme_stylebox_override("panel", _panel_style(Color("#25252D"), Color("#3A3A46"), 29))
	var initials: String = str(conversation.get("name", "??")).substr(0, 1).to_upper()
	var avatar_text: Label = _label(initials, 23, Color("#D8D8E0"), true)
	avatar_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(avatar_text)
	row.add_child(avatar)
	var details: VBoxContainer = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	var name_row: HBoxContainer = HBoxContainer.new()
	var name_label: Label = _label(str(conversation.get("name", "Unknown")), 17, TEXT_MAIN, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(name_label)
	var unread: int = int(conversation.get("unread", 0))
	if unread > 0:
		name_row.add_child(_label(str(unread), 11, ACCENT_RED, true))
	details.add_child(name_row)
	var preview: Label = _label(str(conversation.get("preview", "Tap to open conversation")), 13, Color("#A0A0AA"))
	preview.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	details.add_child(preview)
	row.add_child(details)
	var separator: ColorRect = ColorRect.new()
	separator.color = Color("#24242B")
	separator.custom_minimum_size = Vector2(0, 1)
	separator.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	button.add_child(separator)
	return button

func _render_chat() -> void:
	var conversation: Dictionary = ChatManager.get_conversation(active_conversation_id)
	if conversation.is_empty():
		active_screen = "inbox"
		_render_inbox()
		return
	var top: HBoxContainer = HBoxContainer.new()
	top.add_child(_small_button("‹", _back_to_inbox, 44))
	var avatar: PanelContainer = PanelContainer.new()
	avatar.custom_minimum_size = Vector2(42, 42)
	avatar.add_theme_stylebox_override("panel", _panel_style(Color("#25252D"), Color("#3A3A46"), 21))
	var avatar_label: Label = _label(str(conversation.get("name", "?")).substr(0, 1).to_upper(), 18, TEXT_MAIN, true)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(avatar_label)
	top.add_child(avatar)
	var identity: VBoxContainer = VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 2)
	identity.add_child(_label(str(conversation.get("name", "Unknown")), 17, TEXT_MAIN, true))
	var status_text: String = "online" if str(conversation.get("status", "")) == "online" else "last seen recently"
	identity.add_child(_label(status_text, 10, Color("#8FBA9A") if status_text == "online" else TEXT_MUTED))
	top.add_child(identity)
	top.add_child(_small_button("☎", _open_simulated_call, 44))
	top.add_child(_small_button("⋮", _inspect_private_chat, 38))
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
	stack.add_theme_constant_override("separation", 10)
	message_scroll.add_child(stack)
	var messages: Array[Dictionary] = ChatManager.get_messages(active_conversation_id)
	if messages.is_empty():
		var empty: PanelContainer = PanelContainer.new()
		empty.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 18))
		empty.add_child(_label("This channel is quiet.\nConversation content will appear when you add an episode file.", 16, TEXT_MUTED))
		stack.add_child(empty)
	else:
		var message_index: int = 0
		for message: Dictionary in messages:
			var bubble: Control = _message_bubble(message)
			stack.add_child(bubble)
			_animate_in(bubble, minf(float(message_index) * 0.035, 0.35))
			message_index += 1

	var composer: HBoxContainer = HBoxContainer.new()
	composer.add_theme_constant_override("separation", 10)
	message_input = LineEdit.new()
	message_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message_input.custom_minimum_size.y = 48
	message_input.placeholder_text = "Message..."
	message_input.add_theme_font_size_override("font_size", 17)
	message_input.add_theme_color_override("font_color", TEXT_MAIN)
	message_input.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 16))
	message_input.add_theme_stylebox_override("focus", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 16))
	message_input.text_submitted.connect(_send_message)
	composer.add_child(message_input)
	composer.add_child(_small_button("➤", _send_current_message, 42))
	page.add_child(composer)
	_scroll_to_latest.call_deferred()

func _message_bubble(message: Dictionary) -> Control:
	var is_player: bool = str(message.get("sender", "")) == "player"
	var line: HBoxContainer = HBoxContainer.new()
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bubble: PanelContainer = PanelContainer.new()
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bubble.add_theme_stylebox_override("panel", _panel_style(Color("#24343A") if is_player else Color("#1B1B22"), Color("#35464B") if is_player else Color("#292932"), 15))
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	bubble.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)
	var message_kind: String = str(message.get("kind", "text"))
	var media_path: String = str(message.get("media_path", ""))
	var body_text: String = str(message.get("text", ""))
	match message_kind:
		"image":
			body_text = "▧  IMAGE ATTACHMENT\\n" + media_path.get_file() + ("\\n" + body_text if not body_text.is_empty() else "")
		"video":
			body_text = "▣  VIDEO CLIP\\n" + media_path.get_file() + ("\\n" + body_text if not body_text.is_empty() else "")
		"document":
			body_text = "▤  FILE ATTACHMENT\\n" + media_path.get_file() + ("\\n" + body_text if not body_text.is_empty() else "")
		"voice":
			body_text = "VOICE NOTE  •  %0.1fs" % float(message.get("duration", 0.0))
	var body: Label = _label(body_text, 17, TEXT_MAIN)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 190
	body.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.add_child(body)
	if message_kind == "voice":
		var waveform: HBoxContainer = HBoxContainer.new()
		waveform.custom_minimum_size.y = 34
		waveform.add_theme_constant_override("separation", 3)
		var heights: Array[int] = [8, 15, 22, 12, 28, 18, 32, 16, 24, 10, 27, 18, 13, 30, 17, 9]
		for bar_height: int in heights:
			var bar: ColorRect = ColorRect.new()
			bar.color = ACCENT_CYAN
			bar.custom_minimum_size = Vector2(5, float(bar_height))
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			waveform.add_child(bar)
		content.add_child(waveform)
		content.add_child(_action_button("PLAY VOICE NOTE", MediaManager.play_voice_note.bind(media_path)))
	elif message_kind == "image":
		content.add_child(_action_button("OPEN IMAGE", _open_image_viewer.bind(media_path)))
	elif message_kind == "document":
		content.add_child(_action_button("OPEN FILE", _open_document_viewer.bind(media_path)))
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



func _open_image_viewer(media_path: String) -> void:
	var texture: Texture2D = MediaManager.load_image(media_path)
	if texture == null:
		_show_media_error("Image unavailable", "The image file could not be loaded: " + media_path)
		return
	var window: Window = Window.new()
	window.title = "NIGHTWIRE  /  IMAGE EVIDENCE"
	window.size = Vector2i(440, 760)
	window.min_size = Vector2i(360, 560)
	window.transient = true
	window.exclusive = true
	add_child(window)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 10)
	window.add_child(layout)
	var zoom_row: HBoxContainer = HBoxContainer.new()
	var zoom_label: Label = _label("ZOOM", 12, TEXT_MUTED, true)
	zoom_row.add_child(zoom_label)
	var zoom: HSlider = HSlider.new()
	zoom.min_value = 0.5
	zoom.max_value = 2.5
	zoom.step = 0.1
	zoom.value = 1.0
	zoom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_row.add_child(zoom)
	layout.add_child(zoom_row)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var preview: TextureRect = TextureRect.new()
	preview.texture = texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(texture.get_width(), texture.get_height())
	preview.size = preview.custom_minimum_size
	scroll.add_child(preview)
	zoom.value_changed.connect(func(value: float) -> void:
		preview.custom_minimum_size = Vector2(texture.get_width(), texture.get_height()) * value
		preview.size = preview.custom_minimum_size
	)
	window.close_requested.connect(window.queue_free)
	window.popup_centered()

func _open_document_viewer(media_path: String) -> void:
	if not FileAccess.file_exists(media_path):
		_show_media_error("File unavailable", "The document could not be found: " + media_path)
		return
	var file: FileAccess = FileAccess.open(media_path, FileAccess.READ)
	if file == null:
		_show_media_error("File unavailable", "The document could not be opened.")
		return
	var content_text: String = file.get_as_text()
	file.close()
	if content_text.length() > 50000:
		content_text = content_text.substr(0, 50000) + "\\n\\n[Preview truncated at 50,000 characters]"
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = "NIGHTWIRE  /  DOCUMENT"
	var preview: RichTextLabel = RichTextLabel.new()
	preview.custom_minimum_size = Vector2(360, 520)
	preview.bbcode_enabled = false
	preview.text = content_text
	preview.fit_content = false
	dialog.add_child(preview)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(420, 700))

func _show_media_error(title_text: String, detail: String) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = title_text
	dialog.dialog_text = detail
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 280))

func _open_simulated_call() -> void:
	if not CallManager.begin_call(active_conversation_id):
		return
	var window: Window = Window.new()
	window.title = "NIGHTWIRE  /  ENCRYPTED VOICE LINK"
	window.size = Vector2i(440, 760)
	window.min_size = Vector2i(360, 560)
	window.transient = true
	window.exclusive = true
	add_child(window)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.add_theme_constant_override("separation", 14)
	window.add_child(layout)
	var identity: VBoxContainer = VBoxContainer.new()
	identity.add_child(_label("INCOMING CHANNEL", 12, ACCENT_RED, true))
	identity.add_child(_label(str(ChatManager.get_conversation(active_conversation_id).get("name", "UNKNOWN")), 25, TEXT_MAIN, true))
	identity.add_child(_label("ENCRYPTED LINK  /  VIDEO STREAM NOT CONNECTED", 11, TEXT_MUTED))
	layout.add_child(identity)
	var visual: Control = load("res://scripts/ui/call_visual.gd").new()
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(visual)
	var status: Label = _label("SIGNAL STABLE  •  LOCAL SIMULATION", 12, ACCENT_CYAN, true)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status)
	var controls: HBoxContainer = HBoxContainer.new()
	call_mute_button = _action_button("MUTE MIC", _toggle_call_mute)
	controls.add_child(call_mute_button)
	var end_button: Button = _action_button("END CALL", func() -> void:
		_end_call_window(window)
	)
	end_button.add_theme_color_override("font_color", ACCENT_RED)
	controls.add_child(end_button)
	layout.add_child(controls)
	window.close_requested.connect(_end_call_window.bind(window))
	window.popup_centered()

func _toggle_call_mute() -> void:
	CallManager.set_muted(not CallManager.muted)
	if is_instance_valid(call_mute_button):
		call_mute_button.text = "UNMUTE MIC" if CallManager.muted else "MUTE MIC"

func _end_call_window(window: Window) -> void:
	CallManager.end_call()
	if is_instance_valid(window):
		window.queue_free()

func _inspect_private_chat() -> void:
	var result: Dictionary = SpyManager.inspect_private_messages(active_conversation_id)
	var dialog: AcceptDialog = AcceptDialog.new()
	if bool(result.get("caught", false)):
		dialog.dialog_text = "ACCESS DETECTED\\nThe contact noticed the intrusion. Trust decreased."
	else:
		var messages: Variant = result.get("messages", [])
		var lines: PackedStringArray = PackedStringArray()
		if messages is Array:
			for message: Variant in messages:
				lines.append(str(message))
		dialog.dialog_text = "PRIVATE CACHE\\n" + ("\\n".join(lines) if not lines.is_empty() else "No private messages are stored for this contact.")
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 360))

func _render_evidence() -> void:
	page.add_child(_label("Clues", 27, TEXT_MAIN, true))
	page.add_child(_label("PHOTOS  ·  RECORDINGS  ·  FILES", 10, TEXT_MUTED, true))
	var records: Array[Dictionary] = EvidenceManager.get_unlocked()
	if records.is_empty():
		page.add_child(_empty_panel("No evidence collected yet.\\nEpisode choices can unlock photos, files, recordings and clues here."))
		return
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var board: Variant = load("res://scripts/ui/evidence_board.gd").new()
	board.records = records
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(board)
	board.evidence_selected.connect(_show_evidence_detail)
	board.queue_redraw()

func _show_evidence_detail(record: Dictionary) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = str(record.get("title", "EVIDENCE")).to_upper()
	dialog.dialog_text = str(record.get("description", "No details attached."))
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 320))

func _render_people() -> void:
	page.add_child(_label("Contacts", 27, TEXT_MAIN, true))
	page.add_child(_label("PEOPLE IN YOUR NETWORK", 10, TEXT_MUTED, true))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)
	scroll.add_child(list)
	for profile: Dictionary in ContentManager.get_characters():
		var profile_id: String = str(profile.get("id", ""))
		var card: Button = Button.new()
		card.custom_minimum_size.y = 76
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.text = ""
		card.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		card.add_theme_stylebox_override("hover", _panel_style(Color("#17171D"), Color("#292932"), 8))
		card.pressed.connect(_open_chat.bind(profile_id))
		var row: HBoxContainer = HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.add_theme_constant_override("separation", 12)
		var avatar: PanelContainer = PanelContainer.new()
		avatar.custom_minimum_size = Vector2(50, 50)
		avatar.add_theme_stylebox_override("panel", _panel_style(Color("#25252D"), Color("#3A3A46"), 25))
		var initials: Label = _label(str(profile.get("name", "C")).substr(0, 1).to_upper(), 20, TEXT_MAIN, true)
		initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initials.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		avatar.add_child(initials)
		row.add_child(avatar)
		var info: VBoxContainer = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.add_child(_label(str(profile.get("name", "Character")), 16, TEXT_MAIN, true))
		info.add_child(_label(str(profile.get("role", "Unassigned")), 12, TEXT_MUTED))
		row.add_child(info)
		row.add_child(_label("›", 24, TEXT_MUTED))
		card.add_child(row)
		list.add_child(card)


func _render_map() -> void:
	page.add_child(_label("CITY GRID", 25, TEXT_MAIN, true))
	page.add_child(_label("LOCATION DATA IS EDITABLE  /  EPISODES CAN REFERENCE THESE IDS", 11, TEXT_MUTED))
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var town_map: Control = load("res://scripts/ui/town_map.gd").new()
	town_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(town_map)
	town_map.location_selected.connect(_show_map_location)

func _show_map_location(location: Dictionary) -> void:
	var dialog: AcceptDialog = AcceptDialog.new()
	dialog.title = str(location.get("name", "LOCATION"))
	dialog.dialog_text = str(location.get("type", "LOCATION")) + "\\n\\n" + str(location.get("description", "No details available."))
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(560, 320))

func _render_story() -> void:
	page.add_child(_label("STORY FILES", 25, TEXT_MAIN, true))
	page.add_child(_label("EPISODES ARE LOADED FROM JSON. NO STORY IS HARD-CODED.", 11, TEXT_MUTED))
	var current_node: Dictionary = StoryManager.get_current_node()
	if not current_node.is_empty():
		var current_panel: PanelContainer = PanelContainer.new()
		current_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE_RAISED, ACCENT_CYAN, 18))
		var current_content: VBoxContainer = VBoxContainer.new()
		current_content.add_child(_label("NOW PLAYING  /  " + StoryManager.active_episode_id.to_upper(), 12, ACCENT_CYAN, true))
		current_content.add_child(_label(str(current_node.get("speaker", "SYSTEM")).to_upper(), 13, TEXT_MUTED, true))
		var story_text: Label = _label(str(current_node.get("text", "")), 17, TEXT_MAIN)
		story_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		current_content.add_child(story_text)
		var choices: Variant = current_node.get("choices", [])
		if choices is Array and not choices.is_empty():
			for choice_index: int in range(choices.size()):
				var choice: Dictionary = choices[choice_index]
				var choice_button: Button = Button.new()
				choice_button.text = str(choice.get("text", "Continue"))
				choice_button.custom_minimum_size.y = 56
				choice_button.add_theme_color_override("font_color", ACCENT_CYAN)
				choice_button.add_theme_stylebox_override("normal", _panel_style(SURFACE, BORDER, 14))
				choice_button.add_theme_stylebox_override("hover", _panel_style(Color("#20202A"), ACCENT_CYAN, 14))
				choice_button.pressed.connect(_choose_story_choice.bind(choice_index))
				current_content.add_child(choice_button)
		else:
			current_content.add_child(_label("END OF THIS STORY PATH", 12, ACCENT_RED, true))
		current_panel.add_child(current_content)
		page.add_child(current_panel)
	else:
		page.add_child(_empty_panel("No active episode. Add an episode JSON file to data/episodes/ and it will appear below."))
	var episodes: Array[Dictionary] = ContentManager.get_episodes()
	if episodes.is_empty():
		page.add_child(_empty_panel("No episode files have been added yet. The complete story engine is ready for your own episode files."))
		return
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var list: VBoxContainer = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	for episode: Dictionary in episodes:
		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 16))
		var layout: HBoxContainer = HBoxContainer.new()
		var details: VBoxContainer = VBoxContainer.new()
		details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		details.add_child(_label(str(episode.get("title", "Untitled episode")), 17, TEXT_MAIN, true))
		details.add_child(_label(str(episode.get("description", "")), 12, TEXT_MUTED))
		layout.add_child(details)
		var launch: Button = Button.new()
		launch.text = "OPEN"
		launch.custom_minimum_size = Vector2(86, 48)
		launch.add_theme_color_override("font_color", ACCENT_CYAN)
		launch.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED, BORDER, 12))
		launch.pressed.connect(_start_episode.bind(str(episode.get("id", ""))))
		layout.add_child(launch)
		card.add_child(layout)
		list.add_child(card)

func _start_episode(episode_id: String) -> void:
	if StoryManager.start_episode(episode_id):
		_render_screen()

func _choose_story_choice(choice_index: int) -> void:
	if StoryManager.choose(choice_index):
		_render_screen()

func _on_story_node_changed(_episode_id: String, _node_id: String, _node: Dictionary) -> void:
	if active_screen == "story":
		_render_screen()


func _render_hack() -> void:
	page.add_child(_label("SIGNAL LAB", 25, TEXT_MAIN, true))
	page.add_child(_label("LOCAL PUZZLES  /  PROGRESS FLAGS SAVE WITH YOUR STORY", 11, TEXT_MUTED))
	var pattern_panel: PanelContainer = PanelContainer.new()
	pattern_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 18))
	var pattern_box: VBoxContainer = VBoxContainer.new()
	pattern_box.add_child(_label("01  PATTERN TRACE", 17, ACCENT_CYAN, true))
	pattern_box.add_child(_label("Reconstruct the four-step access pattern.", 13, TEXT_MUTED))
	pattern_box.add_child(_label("INPUT: " + ("  ›  ".join(_pattern_strings()) if not pattern_entry.is_empty() else "—"), 18, TEXT_MAIN, true))
	pattern_box.add_child(_label(pattern_feedback, 12, ACCENT_RED if pattern_feedback.begins_with("DENIED") else TEXT_MUTED))
	var number_row: HBoxContainer = HBoxContainer.new()
	for number: int in range(1, 5):
		var number_button: Button = Button.new()
		number_button.text = str(number)
		number_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		number_button.custom_minimum_size.y = 56
		number_button.add_theme_color_override("font_color", ACCENT_CYAN)
		number_button.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED, BORDER, 14))
		number_button.pressed.connect(_append_pattern_number.bind(number))
		number_row.add_child(number_button)
	pattern_box.add_child(number_row)
	var pattern_actions: HBoxContainer = HBoxContainer.new()
	pattern_actions.add_child(_action_button("CLEAR", _clear_pattern))
	pattern_actions.add_child(_action_button("VERIFY", _submit_pattern))
	pattern_box.add_child(pattern_actions)
	pattern_panel.add_child(pattern_box)
	page.add_child(pattern_panel)

	var password_panel: PanelContainer = PanelContainer.new()
	password_panel.add_theme_stylebox_override("panel", _panel_style(SURFACE, BORDER, 18))
	var password_box: VBoxContainer = VBoxContainer.new()
	password_box.add_child(_label("02  PASSWORD ANAGRAM", 17, ACCENT_CYAN, true))
	password_box.add_child(_label("DECODE: HTGIN", 13, TEXT_MUTED, true))
	var password_input: LineEdit = LineEdit.new()
	password_input.placeholder_text = "Enter decrypted word"
	password_input.add_theme_font_size_override("font_size", 17)
	password_input.add_theme_color_override("font_color", TEXT_MAIN)
	password_input.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED, BORDER, 14))
	password_input.text_submitted.connect(_submit_password)
	password_box.add_child(password_input)
	password_box.add_child(_label(password_feedback, 12, TEXT_MUTED))
	password_box.add_child(_action_button("DECRYPT", func(): _submit_password(password_input.text)))
	password_panel.add_child(password_box)
	page.add_child(password_panel)

	var reconstruction: Variant = load("res://scripts/ui/image_reconstruction.gd").new()
	reconstruction.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reconstruction.order_verified.connect(_on_image_reconstruction_solved)
	page.add_child(reconstruction)

func _on_image_reconstruction_solved() -> void:
	PuzzleManager.complete_puzzle("image_reconstruction_solved")

func _pattern_strings() -> PackedStringArray:
	var values: PackedStringArray = PackedStringArray()
	for number: int in pattern_entry:
		values.append(str(number))
	return values

func _append_pattern_number(number: int) -> void:
	if pattern_entry.size() >= 4:
		return
	pattern_entry.append(number)
	pattern_feedback = "PATTERN CAPTURED"
	_render_screen()

func _clear_pattern() -> void:
	pattern_entry.clear()
	pattern_feedback = "NO INPUT YET"
	_render_screen()

func _submit_pattern() -> void:
	if PuzzleManager.validate_pattern([2, 4, 1, 3], pattern_entry):
		PuzzleManager.complete_puzzle("signal_pattern_solved")
		pattern_feedback = "ACCESS GRANTED  /  FLAG SAVED"
	else:
		pattern_feedback = "DENIED  /  PATTERN DOES NOT MATCH"
	_render_screen()

func _submit_password(value: String) -> void:
	if PuzzleManager.validate_anagram("NIGHT", value):
		PuzzleManager.complete_puzzle("password_anagram_solved")
		password_feedback = "DECRYPTED  /  FLAG SAVED"
	else:
		password_feedback = "DECRYPTION FAILED"
	_render_screen()

func _action_button(caption: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = caption
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size.y = 52
	button.add_theme_color_override("font_color", ACCENT_CYAN)
	button.add_theme_stylebox_override("normal", _panel_style(SURFACE_RAISED, BORDER, 14))
	button.pressed.connect(action)
	button.pressed.connect(_pulse_haptic)
	return button

func _render_settings() -> void:
	page.add_child(_label("SYSTEM", 25, TEXT_MAIN, true))
	page.add_child(_empty_panel("NIGHTWIRE runs offline.\nMessages, trust, flags and evidence are stored locally with encrypted save-file support."))
	var haptics_toggle: CheckBox = CheckBox.new()
	haptics_toggle.text = "ENABLE HAPTIC FEEDBACK"
	haptics_toggle.button_pressed = HapticsManager.is_enabled()
	haptics_toggle.add_theme_color_override("font_color", TEXT_MAIN)
	haptics_toggle.toggled.connect(HapticsManager.set_enabled)
	page.add_child(haptics_toggle)
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
	button.pressed.connect(_pulse_haptic)
	return button

func _pulse_haptic() -> void:
	HapticsManager.pulse(24)

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
	style.content_margin_top = 9
	style.content_margin_bottom = 9
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
