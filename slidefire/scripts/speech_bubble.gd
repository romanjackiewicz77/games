class_name SpeechBubble
extends Node2D

const FONT_SIZE := 14
const SHOW_TIME := 2.2

var _text := ""
var _left := 0.0
var _offset := Vector2(0, -52)
var _target: Node2D


func _init() -> void:
	top_level = true
	z_index = 90
	visible = false


func attach(target: Node2D) -> void:
	_target = target


func say(text: String) -> void:
	_text = text
	_left = SHOW_TIME
	visible = true
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	global_position = _target.global_position + _offset
	_left -= delta
	if _left <= 0.0:
		visible = false
	elif _left < 0.4:
		modulate.a = _left / 0.4
	else:
		modulate.a = 1.0


func _draw() -> void:
	if _text == "":
		return
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var rect := Rect2(Vector2(-size.x / 2.0 - 7.0, -size.y - 8.0), size + Vector2(14.0, 10.0))
	draw_rect(rect, Color(1, 1, 1, 0.95))
	draw_rect(rect, Color(0.1, 0.1, 0.1), false, 1.5)
	var tail_y := rect.end.y
	draw_colored_polygon(PackedVector2Array([Vector2(-5, tail_y - 1), Vector2(5, tail_y - 1), Vector2(0, tail_y + 8)]), Color(1, 1, 1, 0.95))
	draw_string(font, Vector2(rect.position.x + 7.0, rect.end.y - 7.0), _text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.1, 0.1, 0.1))
