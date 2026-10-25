class_name DamageNumber
extends Node2D

const LIFETIME := 0.8

var text := ""
var color := Color.WHITE
var _age := 0.0


static func spawn(parent: Node, pos: Vector2, amount: float, col: Color) -> void:
	var n := DamageNumber.new()
	n.text = str(maxi(1, roundi(amount)))
	n.color = col
	n.top_level = true
	n.z_index = 100
	n.position = pos + Vector2(randf_range(-8.0, 8.0), -20.0)
	parent.add_child(n)


func _process(delta: float) -> void:
	_age += delta
	position.y -= 40.0 * delta
	modulate.a = clampf(1.0 - _age / LIFETIME, 0.0, 1.0)
	if _age >= LIFETIME:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var pos := Vector2(-12.0, 0.0)
	draw_string(font, pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 0, 0.8))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
