class_name Player
extends CharacterBody2D

@export var max_speed := 320.0
@export var acceleration := 1200.0
@export var friction := 700.0
@export var fire_rate := 8.0
@export var bullet_speed := 900.0

const RADIUS := 16.0
var _cooldown := 0.0


func _ready() -> void:
	InputSetup.ensure()
	collision_layer = 2
	collision_mask = 1 | 4
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	add_child(cam)


func _physics_process(delta: float) -> void:
	var aim := get_global_mouse_position() - global_position
	if aim != Vector2.ZERO:
		rotation = aim.angle()

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Poślizg: przyspieszenie przy ruchu, tarcie po puszczeniu klawiszy.
	if dir != Vector2.ZERO:
		velocity = velocity.move_toward(dir * max_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	move_and_slide()

	_cooldown -= delta
	if Input.is_action_pressed("shoot") and _cooldown <= 0.0 and aim != Vector2.ZERO:
		_shoot(aim.normalized())
		_cooldown = 1.0 / fire_rate


func _shoot(direction: Vector2) -> void:
	var bullet := Bullet.new()
	bullet.position = position + direction * (RADIUS + 14.0)
	bullet.velocity = direction * bullet_speed
	get_parent().add_child(bullet)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.3, 0.7, 1.0))
	draw_line(Vector2.ZERO, Vector2(RADIUS + 12.0, 0.0), Color.WHITE, 5.0)
