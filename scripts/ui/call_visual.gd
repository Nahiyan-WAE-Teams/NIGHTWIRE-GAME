extends Control

var pulse: float = 0.0
var frame_index: int = 0
var elapsed_seconds: int = 0
var animation_timer: Timer

func _ready() -> void:
	custom_minimum_size = Vector2(0, 430)
	animation_timer = Timer.new()
	animation_timer.wait_time = 0.18
	animation_timer.timeout.connect(_advance_frame)
	add_child(animation_timer)
	animation_timer.start()

func _advance_frame() -> void:
	frame_index += 1
	pulse = 0.5 + 0.5 * sin(float(frame_index) * 0.22)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#171A18"), true)
	for line_index: int in range(18):
		var y: float = fmod(float(line_index) * 29.0 + float(frame_index % 29) * 2.0, maxf(size.y, 1.0))
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.45, 0.52, 0.43, 0.035), 1.0)
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x * 0.25, 92.0)
	draw_circle(center, radius + 18.0 + pulse * 8.0, Color(0.0, 0.9, 1.0, 0.035))
	draw_arc(center, radius + 10.0, 0.0, TAU, 64, Color("#899782"), 2.0, true)
	draw_circle(center, radius, Color("#1D211E"))
	draw_circle(center, radius - 4.0, Color("#272C27"))
	draw_string(ThemeDB.fallback_font, center + Vector2(-27, 10), "NW", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("#00E5FF"))
	for bar_index: int in range(25):
		var height: float = 8.0 + absf(sin(float(bar_index) * 0.8 + float(frame_index) * 0.16)) * 30.0
		var x: float = size.x * 0.18 + float(bar_index) * size.x * 0.026
		draw_rect(Rect2(Vector2(x, size.y - 62.0 - height * 0.5), Vector2(5, height)), Color(0.55, 0.62, 0.52, 0.78), true)
	if frame_index % 17 == 0:
		draw_rect(Rect2(Vector2(0, center.y - 28), Vector2(size.x, 3)), Color(0.65, 0.40, 0.36, 0.16), true)
