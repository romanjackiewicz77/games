class_name MenuArt
extends Control
## Animowane tło menu: widok z góry na mieszkanie, do którego wchodzi grupa SWAT.

const LOOP := 7.0
const WALL := 36.0
const NAVY := Color(0.12, 0.17, 0.3)
const HELMET := Color(0.2, 0.27, 0.42)

var _t := 0.0
var _gap := Rect2()
var _room := Rect2()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


func _draw() -> void:
	var s := size
	var p := fmod(_t, LOOP)
	_room = Rect2(150, WALL, s.x - 150 - WALL, s.y - WALL * 2)
	var gy := s.y * 0.5
	_gap = Rect2(_room.position.x - 6, gy - 60, 12, 120)

	draw_rect(Rect2(Vector2.ZERO, s), Color(0.04, 0.05, 0.07))
	draw_rect(Rect2(0, 0, _room.position.x, s.y), Color(0.09, 0.1, 0.13))
	_draw_floor()
	_draw_furniture(s)
	_draw_walls(s)
	_draw_door(p)

	var target := Vector2(s.x * 0.8, gy + 10)
	_draw_intruder(target, p)
	var ops := [
		[Vector2(-30, gy - 14), Vector2(330, gy - 130)],
		[Vector2(-90, gy + 8), Vector2(280, gy + 120)],
		[Vector2(-150, gy - 4), Vector2(420, gy + 10)],
		[Vector2(-210, gy + 4), Vector2(360, gy - 40)],
	]
	for i in ops.size():
		var k: float = _ease((p - 0.9 - 0.3 * i) / 1.8)
		var pos: Vector2 = ops[i][0].lerp(ops[i][1], k)
		_draw_operator(pos, target, p, i)
	_draw_smoke(p, gy)


func _draw_floor() -> void:
	var y := _room.position.y
	var i := 0
	while y < _room.end.y:
		var shade := 0.34 + 0.03 * float(i % 3)
		draw_rect(Rect2(_room.position.x, y, _room.size.x, 28), Color(shade, shade * 0.72, shade * 0.45))
		draw_line(Vector2(_room.position.x, y), Vector2(_room.end.x, y), Color(0, 0, 0, 0.35), 2)
		y += 28
		i += 1


func _draw_furniture(s: Vector2) -> void:
	var r := _room
	draw_rect(Rect2(r.position.x + 300, r.position.y + 250, 520, 300), Color(0.45, 0.16, 0.16, 0.85))
	draw_rect(Rect2(r.end.x - 170, r.position.y + 14, 150, 220), Color(0.8, 0.8, 0.85))
	draw_rect(Rect2(r.end.x - 160, r.position.y + 24, 130, 200), Color(0.35, 0.4, 0.55))
	draw_rect(Rect2(r.end.x - 160, r.position.y + 24, 130, 50), Color(0.9, 0.9, 0.95))
	draw_rect(Rect2(r.position.x + 40, r.position.y + 20, 260, 80), Color(0.3, 0.2, 0.14))
	draw_rect(Rect2(r.position.x + 40, r.position.y + 20, 260, 80), Color(0, 0, 0, 0.5), false, 3)
	draw_rect(Rect2(r.end.x - 330, r.end.y - 110, 280, 90), Color(0.5, 0.25, 0.2))
	draw_rect(Rect2(r.end.x - 330, r.end.y - 110, 280, 28), Color(0.4, 0.18, 0.14))
	draw_circle(Vector2(r.position.x + 520, r.position.y + 400), 70, Color(0.28, 0.2, 0.12))
	draw_circle(Vector2(r.position.x + 520, r.position.y + 400), 70, Color(0, 0, 0, 0.5), false, 3)
	draw_rect(Rect2(r.position.x + 40, r.end.y - 90, 90, 70), Color(0.2, 0.28, 0.2))
	draw_circle(Vector2(r.end.x - 60, r.end.y - 220), 22, Color(0.15, 0.4, 0.15))


func _draw_walls(s: Vector2) -> void:
	var c := Color(0.2, 0.2, 0.22)
	var x := _room.position.x
	draw_rect(Rect2(x - WALL, 0, WALL, _gap.position.y), c)
	draw_rect(Rect2(x - WALL, _gap.end.y, WALL, s.y - _gap.end.y), c)
	draw_rect(Rect2(x - WALL, 0, s.x - x + WALL, WALL), c)
	draw_rect(Rect2(x - WALL, s.y - WALL, s.x - x + WALL, WALL), c)
	draw_rect(Rect2(s.x - WALL, 0, WALL, s.y), c)


func _draw_door(p: float) -> void:
	var k := _ease((p - 0.5) / 0.7)
	var center := Vector2(_gap.position.x + 6, _gap.position.y + 60)
	center += Vector2(k * 190.0, k * 55.0)
	var ang := k * 1.2
	var door_size := Vector2(12, 120)
	draw_set_transform(center, ang, Vector2.ONE)
	draw_rect(Rect2(-door_size * 0.5, door_size), Color(0.5, 0.32, 0.16))
	draw_rect(Rect2(-door_size * 0.5, door_size), Color(0.2, 0.1, 0.05), false, 2)
	draw_circle(Vector2(0, 20), 3, Color(0.85, 0.75, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if p > 0.5 and p < 1.4:
		var rng := RandomNumberGenerator.new()
		rng.seed = 7
		for i in 14:
			var d := Vector2(rng.randf_range(10, 120), rng.randf_range(-70, 70)) * _ease((p - 0.5) / 0.9)
			draw_rect(Rect2(_gap.position.x + d.x, gy_center() + d.y, 6, 2), Color(0.55, 0.38, 0.2, 1.0 - (p - 0.5) / 0.9))


func gy_center() -> float:
	return _gap.position.y + 60


func _draw_intruder(pos: Vector2, p: float) -> void:
	var alive := p < 5.2
	var col := Color(0.8, 0.15, 0.12) if alive else Color(0.45, 0.1, 0.1)
	draw_circle(pos, 16, col)
	draw_circle(pos, 9, col.lightened(0.2))
	if not alive:
		draw_circle(pos + Vector2(8, 6), 22, Color(0.5, 0.05, 0.05, 0.5))


func _draw_operator(pos: Vector2, target: Vector2, p: float, i: int) -> void:
	var dir := (target - pos).normalized()
	var aim := dir if p > 1.2 else Vector2.RIGHT
	var muzzle := pos + aim * 46
	if p > 1.4:
		var cone := PackedVector2Array([muzzle, muzzle + aim.rotated(-0.22) * 380, muzzle + aim.rotated(0.22) * 380])
		draw_colored_polygon(cone, Color(1, 1, 0.8, 0.07))
	draw_circle(pos + Vector2(3, 4), 17, Color(0, 0, 0, 0.4))
	draw_circle(pos, 16, NAVY)
	draw_line(pos + aim.rotated(1.5) * 10, pos + aim * 26, NAVY.lightened(0.15), 6)
	draw_line(pos + aim * 14, muzzle, Color(0.05, 0.05, 0.06), 5)
	draw_circle(pos, 10, HELMET)
	draw_circle(pos + aim * 3, 4, Color(0.3, 0.8, 1.0, 0.8))
	if p > 2.2 and p < 5.6:
		var cycle := fmod(p * 8.0 + i * 0.37, 1.0)
		if cycle < 0.5:
			var fl := 12.0 + 8.0 * fmod(float(i) * 3.1 + p * 17.0, 1.0)
			draw_circle(muzzle, fl, Color(1.0, 0.85, 0.3, 0.9))
			draw_circle(muzzle, fl * 0.5, Color(1, 1, 0.9))
			draw_line(muzzle, muzzle + aim * 260, Color(1.0, 0.9, 0.4, 0.5), 2)


func _draw_smoke(p: float, gy: float) -> void:
	for i in 6:
		var a := clampf((p - 0.5) / 2.0, 0.0, 1.0) * (1.0 - clampf((p - 5.5) / 1.5, 0.0, 1.0))
		var c := Vector2(_room.position.x + 40 + i * 70 + sin(_t * 0.6 + i) * 20, gy - 30 + cos(_t * 0.5 + i * 2.0) * 50)
		draw_circle(c, 70 + i * 6, Color(0.7, 0.7, 0.7, 0.07 * a))
