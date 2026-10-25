class_name Bullet
extends Area2D

## Szansa zatrzymania pocisku na meblu oraz mnożnik energii po przebiciu mebla.
const FURNITURE_STOP_CHANCE := 0.35
const FURNITURE_ENERGY_LOSS := 0.5
const MIN_ENERGY := 0.3

var velocity := Vector2.ZERO
var lifetime := 2.0
## Energia pocisku (1.0 = pełna); docelowo skaluje obrażenia.
var energy := 1.0
var _hit_shapes := {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)
	body_shape_entered.connect(_on_body_shape_entered)


func _on_body_shape_entered(_rid: RID, body: Node, _body_shape: int, local_shape: int) -> void:
	var layer: int = body.get("collision_layer")
	if layer & 1:
		queue_free()
		return
	# Każdy mebel (kształt) liczymy raz.
	var key := "%d_%d" % [body.get_instance_id(), _body_shape]
	if _hit_shapes.has(key):
		return
	_hit_shapes[key] = true
	energy *= FURNITURE_ENERGY_LOSS
	if randf() < FURNITURE_STOP_CHANCE or energy < MIN_ENERGY:
		queue_free()


func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, Color.RED)
