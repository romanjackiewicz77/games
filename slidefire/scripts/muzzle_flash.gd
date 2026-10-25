class_name MuzzleFlash
extends Node2D
## Krótki rozbłysk przy lufie.

const LIFE := 0.07

var color := Color(1.0, 0.85, 0.3)
var size := 1.0
var _age := 0.0


static func spawn(parent: Node, pos: Vector2, dir: Vector2, col: Color, scale := 1.0) -> void:
	var f := MuzzleFlash.new()
	f.position = pos
	f.rotation = dir.angle()
	f.color = col
	f.size = scale
	f.z_index = 5
	parent.add_child(f)


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var k := 1.0 - _age / LIFE
	var s := size * (0.8 + 0.4 * k)
	draw_circle(Vector2(4, 0) * s, 16.0 * s * k, Color(color, 0.25 * k))
	var star := PackedVector2Array([
		Vector2(0, 0), Vector2(10, -6), Vector2(30, 0) * s, Vector2(10, 6),
	])
	draw_colored_polygon(star, Color(color, 0.95 * k))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -3), Vector2(6, -9) * s, Vector2(10, 0), Vector2(6, 9) * s,
	]), Color(color, 0.7 * k))
	draw_circle(Vector2(3, 0), 5.0 * s * k, Color(1, 1, 0.95, k))
