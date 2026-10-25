class_name Player
extends CharacterBody2D

@export var max_speed := 320.0
@export var acceleration := 1200.0
@export var friction := 700.0
@export var fire_rate := 8.0
@export var bullet_speed := 900.0
@export var bullet_damage := 10.0
@export var max_health := 100.0

signal health_changed(current: float, maximum: float)
signal died

const RADIUS := 11.0
var health := 100.0
var _cooldown := 0.0


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = clampf(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if health <= 0.0:
		return
	health = clampf(health + amount, 0.0, max_health)
	health_changed.emit(health, max_health)


# Klawisz testowy: H odejmuje 10 punktów życia (do czasu, aż pojawią się przeciwnicy).
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_H:
		take_damage(10.0)


func _ready() -> void:
	health = max_health
	InputSetup.ensure()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	wall_min_slide_angle = 0.0
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4 | 8
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
	bullet.damage = bullet_damage
	bullet.target_layer = 8
	bullet.add_to_group("player_bullets")
	get_parent().add_child(bullet)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.3, 0.7, 1.0))
	draw_line(Vector2.ZERO, Vector2(RADIUS + 12.0, 0.0), Color.BLACK, 5.0)
