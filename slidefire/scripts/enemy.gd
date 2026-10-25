class_name Enemy
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal died

enum Kind { AMATEUR, AVERAGE, PRO }

@export var max_health := 100.0
@export var speed := 190.0
@export var fire_interval := 0.45
@export var bullet_speed := 650.0
@export var bullet_damage := 8.0
@export var aim_spread_deg := 7.0
@export var preferred_distance := 320.0
## Poniżej tego ułamka życia przeciwnik ucieka w kryjówkę i broni się stamtąd.
@export var low_health_ratio := 0.25
@export var max_shoot_distance := 700.0

const BAR_SIZE := Vector2(40, 6)

## Parametry typów: prędkość, promień, kolor, szansa zapomnienia strzału, szansa strzału
## w zwolnionym tempie, szansa uniku przed pociskiem, szansa dobrej kryjówki, odstęp strzałów.
const KINDS := {
	Kind.AMATEUR: {
		"name": "amator", "speed": 150.0, "radius": 14.0, "color": Color(0.95, 0.8, 0.2),
		"forget": 0.3, "slow": 0.3, "dodge": 0.0, "hide": 0.15, "interval": 0.8,
	},
	Kind.AVERAGE: {
		"name": "średniak", "speed": 290.0, "radius": 12.0, "color": Color(0.95, 0.5, 0.15),
		"forget": 0.15, "slow": 0.0, "dodge": 0.4, "hide": 0.85, "interval": 0.55,
	},
	Kind.PRO: {
		"name": "zawodowiec", "speed": 320.0, "radius": 10.0, "color": Color(0.65, 0.15, 0.8),
		"forget": 0.0, "slow": 0.0, "dodge": 0.75, "hide": 1.0, "interval": 0.4,
	},
}

var kind := Kind.AMATEUR
var radius := 11.0
var body_color := Color(0.85, 0.25, 0.25)
var forget_chance := 0.0
var slow_chance := 0.0
var dodge_chance := 0.5
var hide_skill := 1.0
var health := 100.0
var level: Level
var player: Player
var director: Director

var _dodge_seen := {}
var _dodge_wanted := false
var _knock := Vector2.ZERO
var _knock_time := 0.0

const KNOCK_DURATION := 0.35

var _cooldown := 0.5
var _path := PackedVector2Array()
var _repath_timer := 0.0
var _strafe_dir := 1.0
var _strafe_timer := 2.0
var _dodge_dir := Vector2.ZERO
var _dodge_time := 0.0
var _hide_spot := Vector2.ZERO
var _has_hide_spot := false
var _bar: Node2D


func setup(k: Kind) -> void:
	kind = k
	var p: Dictionary = KINDS[k]
	speed = p["speed"]
	radius = p["radius"]
	body_color = p["color"]
	forget_chance = p["forget"]
	slow_chance = p["slow"]
	dodge_chance = p["dodge"]
	hide_skill = p["hide"]
	fire_interval = p["interval"]


func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 8
	collision_mask = 1 | 2 | 4 | 8
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	add_child(shape)
	# Pasek życia nie obraca się razem z przeciwnikiem.
	_bar = Node2D.new()
	_bar.top_level = true
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	_bubble = SpeechBubble.new()
	_bubble.attach(self)
	add_child(_bubble)
	_strafe_dir = 1.0 if randf() < 0.5 else -1.0


const LINES_TAUNT := [
	"Poddaj się!",
	"Zaraz Cię wykończę!",
	"Nie uciekniesz!",
	"To twój koniec!",
	"Jesteś na przegranej pozycji!",
	"Nie masz szans!",
]
const LINES_BEG := [
	"Błagam, litości!",
	"Nie strzelaj, proszę!",
	"Już dość, poddaję się!",
	"Daruj mi życie!",
]
const LINES_PRAISE := [
	"Niezły strzał!",
	"Celnie, muszę przyznać!",
	"Dobrze mierzysz!",
	"Ała! Ale celnie!",
]
const LINES_RALLY := [
	"Atakujcie go!",
	"Wszyscy naraz!",
	"Dalej, dopadnijmy go!",
	"Strzelajcie, nie czekajcie!",
	"Osaczcie go!",
]

var _talk_timer := randf_range(1.5, 4.0)
var _bubble: SpeechBubble


func say(text: String) -> void:
	if _bubble != null:
		_bubble.say(text)


func _talk(delta: float) -> void:
	_talk_timer -= delta
	if _talk_timer > 0.0:
		return
	_talk_timer = randf_range(4.0, 8.0)
	if _is_low():
		say(LINES_BEG.pick_random())
	elif director != null and director.enemies.size() > 1 and randf() < 0.4:
		say(LINES_RALLY.pick_random())
	else:
		say(LINES_TAUNT.pick_random())


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = clampf(health - amount, 0.0, max_health)
	health_changed.emit(health, max_health)
	_bar.queue_redraw()
	DamageNumber.spawn(get_parent(), global_position, amount, Color(1.0, 0.85, 0.2))
	self_modulate = Color(3, 3, 3)
	create_tween().tween_property(self, "self_modulate", Color.WHITE, 0.15)
	if health > 0.0 and randf() < 0.3:
		say(LINES_BEG.pick_random() if _is_low() else LINES_PRAISE.pick_random())
	if health <= 0.0:
		Sfx.play(get_parent(), "death", global_position, -2.0)
		died.emit()
		queue_free()


func _is_low() -> bool:
	return health <= max_health * low_health_ratio


func apply_shockwave(dir: Vector2, strength: float) -> void:
	_knock = dir * strength
	_knock_time = KNOCK_DURATION


func _physics_process(delta: float) -> void:
	_bar.global_position = global_position
	_talk(delta)
	if _knock_time > 0.0:
		_knock_time -= delta
		velocity = _knock * clampf(_knock_time / KNOCK_DURATION, 0.0, 1.0)
		move_and_slide()
		return
	if player == null or not is_instance_valid(player) or player.health <= 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, 1500.0 * delta)
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var los := level.line_clear(global_position, player.global_position)
	rotation = lerp_angle(rotation, to_player.angle(), minf(1.0, 12.0 * delta))

	var desired := _retreat_move(delta) if _is_low() else _combat_move(to_player, dist, los, delta)
	desired = (desired + _separation()).limit_length(1.0)

	var dodge := _dodge_vector()
	if dodge != Vector2.ZERO:
		_dodge_dir = dodge
		_dodge_time = 0.35
	if _dodge_time > 0.0:
		_dodge_time -= delta
		desired = _dodge_dir

	velocity = velocity.move_toward(desired * speed, 1600.0 * delta)
	move_and_slide()

	_cooldown -= delta
	if los and _cooldown <= 0.0 and dist <= max_shoot_distance and (kind == Kind.PRO or director.can_fire(self)):
		if randf() >= forget_chance:
			_shoot(to_player)
		var slow := 2.5 if randf() < slow_chance else 1.0
		_cooldown = fire_interval * slow * randf_range(0.9, 1.3)


func _combat_move(to_player: Vector2, dist: float, los: bool, delta: float) -> Vector2:
	if not los or dist > preferred_distance + 80.0:
		return _follow_path_to(player.global_position, delta)
	if dist < preferred_distance - 100.0:
		return -to_player.normalized()
	# Zajmuje własną pozycję wokół gracza (inną niż koledzy), jeśli widać stamtąd gracza.
	var slot := player.global_position + Vector2.from_angle(director.slot_angle(self)) * preferred_distance
	if level.is_free(slot) and level.line_clear(player.global_position, slot):
		if global_position.distance_to(slot) > 25.0:
			return _follow_path_to(slot, delta)
		return Vector2.ZERO
	# Inaczej krąży, żeby trudniej było go trafić.
	_strafe_timer -= delta
	if _strafe_timer <= 0.0 or get_slide_collision_count() > 0:
		_strafe_dir = -_strafe_dir
		_strafe_timer = randf_range(1.2, 2.8)
	return to_player.normalized().orthogonal() * _strafe_dir * 0.7


# Odpychanie od innych przeciwników, żeby się nie zlepiali.
func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in director.enemies:
		if other == self or not is_instance_valid(other):
			continue
		var d := global_position - other.global_position
		if d.length() < 45.0 and d != Vector2.ZERO:
			push += d.normalized() * (45.0 - d.length()) / 45.0
	return push


func _retreat_move(delta: float) -> Vector2:
	if not _has_hide_spot:
		_hide_spot = _pick_hide_spot()
		director.hide_spots.append(_hide_spot)
		_has_hide_spot = true
	if global_position.distance_to(_hide_spot) < 14.0:
		return Vector2.ZERO
	return _follow_path_to(_hide_spot, delta)


func _pick_hide_spot() -> Vector2:
	if randf() < hide_skill:
		return level.find_hiding_spot(global_position, player.global_position, director.hide_spots)
	# Nieumiejętne chowanie: byle gdzie w pobliżu, często na widoku gracza.
	return level._free_spot_near(global_position)


func _follow_path_to(target: Vector2, delta: float) -> Vector2:
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_path = level.find_path(global_position, target)
		_repath_timer = 0.4
	while _path.size() > 0 and global_position.distance_to(_path[0]) < 12.0:
		_path.remove_at(0)
	if _path.is_empty():
		var direct := target - global_position
		return direct.normalized() if direct.length() > 14.0 else Vector2.ZERO
	return (_path[0] - global_position).normalized()


# Wykrywa pocisk gracza lecący w naszą stronę i zwraca kierunek uniku (bokiem do toru pocisku).
func _dodge_vector() -> Vector2:
	for node in get_tree().get_nodes_in_group("player_bullets"):
		var b := node as Bullet
		if b == null or b.velocity == Vector2.ZERO:
			continue
		var rel := b.global_position - global_position
		var t := -rel.dot(b.velocity) / b.velocity.length_squared()
		if t < 0.0 or t > 0.6:
			continue
		var closest := rel + b.velocity * t
		if closest.length() < 30.0:
			var id := b.get_instance_id()
			if not _dodge_seen.has(id):
				_dodge_seen[id] = true
				if _dodge_seen.size() > 64:
					_dodge_seen.clear()
				_dodge_wanted = randf() < dodge_chance
			if not _dodge_wanted:
				return Vector2.ZERO
			var side := b.velocity.orthogonal().normalized()
			var sign := signf(closest.dot(side))
			if sign == 0.0:
				sign = 1.0 if randf() < 0.5 else -1.0
			return -side * sign
	return Vector2.ZERO


func _shoot(to_player: Vector2) -> void:
	# Celuje z wyprzedzeniem, ale z rozrzutem, żeby gracz mógł uniknąć trafienia.
	var lead := player.global_position + player.velocity * (to_player.length() / bullet_speed) * 0.7
	var dir := (lead - global_position).normalized().rotated(deg_to_rad(randf_range(-aim_spread_deg, aim_spread_deg)))
	var bullet := Bullet.new()
	bullet.position = position + dir * (radius + 12.0)
	bullet.velocity = dir * bullet_speed
	bullet.damage = bullet_damage
	bullet.target_layer = 2
	bullet.color = Color(1.0, 0.55, 0.1)
	get_parent().add_child(bullet)
	Sfx.play(get_parent(), "shot_enemy", global_position, -9.0)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_line(Vector2.ZERO, Vector2(radius + 12.0, 0.0), Color.BLACK, 5.0)


func _draw_bar() -> void:
	var origin := Vector2(-BAR_SIZE.x / 2.0, -radius - 18.0)
	_bar.draw_rect(Rect2(origin, BAR_SIZE), Color(0, 0, 0, 0.7))
	var ratio := clampf(health / max_health, 0.0, 1.0)
	var color := Color(0.2, 0.8, 0.3).lerp(Color(0.9, 0.15, 0.15), 1.0 - ratio)
	_bar.draw_rect(Rect2(origin + Vector2(1, 1), Vector2((BAR_SIZE.x - 2) * ratio, BAR_SIZE.y - 2)), color)
