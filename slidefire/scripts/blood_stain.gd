class_name BloodStain
extends Node2D
## Red blood stain left where the player died.

var _blobs: Array = []
var _age := 0.0


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_blobs.append([Vector2.ZERO, 22.0])
	for i in 16:
		var a := rng.randf() * TAU
		var d := rng.randf_range(6.0, 30.0)
		_blobs.append([Vector2.from_angle(a) * d, rng.randf_range(5.0, 15.0)])
	for i in 8:
		var a := rng.randf() * TAU
		_blobs.append([Vector2.from_angle(a) * rng.randf_range(32.0, 48.0), rng.randf_range(2.0, 5.0)])


func _process(delta: float) -> void:
	if _age < 1.0:
		_age += delta
		queue_redraw()


func _draw() -> void:
	var k := clampf(_age, 0.0, 1.0)
	for b in _blobs:
		draw_circle(b[0] * k, b[1] * k, Color(0.45, 0.02, 0.03, 0.9))
	for b in _blobs:
		draw_circle(b[0] * k * 0.9, b[1] * k * 0.6, Color(0.7, 0.05, 0.06, 0.9))
