class_name Grenade
extends Node2D

const SPEED := 650.0
const MAX_RANGE := 480.0
const RADIUS := 170.0
const MAX_DAMAGE := 90.0
const MIN_DAMAGE := 40.0
const KNOCKBACK := 750.0

const ENEMY_SPEED := 280.0
const ENEMY_RADIUS := 130.0
const ENEMY_MAX_DAMAGE := 50.0
const ENEMY_MIN_DAMAGE := 25.0

var target := Vector2.ZERO
## Granat rzucony przez przeciwnika rani tylko gracza i leci wolniej.
var hostile := false
var _exploded := false
var _spin := 0.0
var _age := 0.0
var _ring := 0.0


static func throw_at(parent: Node, from: Vector2, aim: Vector2) -> void:
	var g := Grenade.new()
	g.position = from
	g.target = from + (aim - from).limit_length(MAX_RANGE)
	g.z_index = 80
	parent.add_child(g)


static func throw_hostile(parent: Node, from: Vector2, to: Vector2) -> void:
	var g := Grenade.new()
	g.hostile = true
	g.position = from
	g.target = from + (to - from).limit_length(MAX_RANGE)
	g.z_index = 80
	parent.add_child(g)


func _physics_process(delta: float) -> void:
	if _exploded:
		_age += delta
		_ring = _age / 0.45
		queue_redraw()
		if _age >= 0.45:
			queue_free()
		return
	_spin += delta * 14.0
	var step := minf((ENEMY_SPEED if hostile else SPEED) * delta, position.distance_to(target))
	var next := position.move_toward(target, step)
	var query := PhysicsRayQueryParameters2D.create(position, next, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		position = hit["position"] + hit["normal"] * 4.0
		_explode()
		return
	position = next
	if position.distance_to(target) < 1.0:
		_explode()
	queue_redraw()


func _explode() -> void:
	_exploded = true
	Sfx.play(get_parent(), "boom", global_position, 2.0)
	if hostile:
		_explode_hostile()
		return
	var shape_query := PhysicsRayQueryParameters2D.new()
	for node in get_tree().get_nodes_in_group("enemies"):
		var e := node as Enemy
		if e == null or not is_instance_valid(e):
			continue
		var d := e.global_position.distance_to(global_position)
		if d > RADIUS:
			continue
		shape_query = PhysicsRayQueryParameters2D.create(global_position, e.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(shape_query).is_empty():
			continue
		var dir := (e.global_position - global_position).normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.RIGHT
		e.apply_shockwave(dir, KNOCKBACK * (1.0 - 0.5 * d / RADIUS))
		e.take_damage(lerpf(MAX_DAMAGE, MIN_DAMAGE, d / RADIUS))
	# Fala uderzeniowa niszczy też pociski przeciwników w zasięgu.
	for node in get_parent().get_children():
		var b := node as Bullet
		if b != null and b.target_layer == 2 and b.global_position.distance_to(global_position) <= RADIUS:
			b.queue_free()
	queue_redraw()


func _explode_hostile() -> void:
	for node in get_tree().get_nodes_in_group("player"):
		var p := node as Player
		if p == null or not is_instance_valid(p):
			continue
		var d := p.global_position.distance_to(global_position)
		if d > ENEMY_RADIUS:
			continue
		var q := PhysicsRayQueryParameters2D.create(global_position, p.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(q).is_empty():
			continue
		p.take_damage(lerpf(ENEMY_MAX_DAMAGE, ENEMY_MIN_DAMAGE, d / ENEMY_RADIUS))
	queue_redraw()


func _draw() -> void:
	if not _exploded:
		draw_circle(Vector2.ZERO, 6.0, Color(0.5, 0.1, 0.6) if hostile else Color(0.2, 0.4, 0.2))
		draw_arc(Vector2.ZERO, 6.0, _spin, _spin + PI, 8, Color(0.9, 0.9, 0.3), 2.0)
		return
	var radius := ENEMY_RADIUS if hostile else RADIUS
	var r := radius * clampf(_ring, 0.0, 1.0)
	var fade := 1.0 - clampf(_ring, 0.0, 1.0)
	draw_circle(Vector2.ZERO, r * 0.8, Color(1.0, 0.6, 0.15, 0.5 * fade))
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(1.0, 1.0, 0.85, fade), 6.0 * fade + 1.0)
	draw_arc(Vector2.ZERO, r * 0.7, 0.0, TAU, 48, Color(1.0, 0.7, 0.3, fade * 0.7), 3.0)
