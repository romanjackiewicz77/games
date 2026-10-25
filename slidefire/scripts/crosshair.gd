class_name Crosshair
extends Node2D

var player: Player


func _init() -> void:
	top_level = true
	z_index = 100
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(_delta: float) -> void:
	var paused := get_tree().paused
	visible = not paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_HIDDEN
	if player == null or not is_instance_valid(player):
		return
	global_position = get_global_mouse_position()
	queue_redraw()


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _draw() -> void:
	if player == null or not is_instance_valid(player):
		return
	var from: Vector2 = player.global_position - global_position
	var base := Bullet.RAPID_COLOR if player.rapid_active else Bullet.PLAYER_COLOR
	draw_line(from, Vector2.ZERO, Color(base, 0.2), 1.0)
	var c := Color(base, 0.9)
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, c, 1.5)
	draw_line(Vector2(-15, 0), Vector2(-5, 0), c, 1.5)
	draw_line(Vector2(5, 0), Vector2(15, 0), c, 1.5)
	draw_line(Vector2(0, -15), Vector2(0, -5), c, 1.5)
	draw_line(Vector2(0, 5), Vector2(0, 15), c, 1.5)
	draw_circle(Vector2.ZERO, 1.5, c)
