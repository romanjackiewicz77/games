extends Node2D
class_name Level

## Plik mapy (tekst: '#' ściana, 'F' mebel, '.' podłoga, 'P' start gracza, 'E' start przeciwnika; linie od ';' to nagłówek).
@export_file("*.txt") var map_path := "res://maps/map_02.txt"
## Rozmiar kafelka w pikselach gry (kafelek mapy = 12 cm).
@export var tile := 16

var _rows: PackedStringArray = []
var _wall_rects: Array[Rect2i] = []
var _furniture_rects: Array[Rect2i] = []
var _meta := {}
var _astar := AStarGrid2D.new()
var _player: Player
var _hud: Hud
var _director: Director
var _spawn_points: Array[Vector2] = []
var _wave := 0
var _wins := 0
var _alive := 0

## Pokazuje kolizje (ściany/meble) do debugowania; domyślnie niewidoczne.
@export var show_collisions := false


# Warstwa 1 = ściany (blokują gracza i pociski), 4 = meble (blokują tylko gracza, pociski je przebijają).
func _add_body(rects: Array[Rect2i], layer: int) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	add_child(body)
	for r in rects:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(r.size * tile)
		shape.shape = rect
		shape.position = Vector2(r.position * tile) + rect.size / 2.0
		body.add_child(shape)


func _ready() -> void:
	_rows = _load_rows(map_path)
	if _rows.is_empty():
		push_error("Nie można wczytać mapy: %s" % map_path)
		return

	_wall_rects = _merge_walls(_rows, "#")
	_furniture_rects = _merge_walls(_rows, "F")
	_add_body(_wall_rects, 1)
	_add_body(_furniture_rects, 4)

	_add_plan_sprite()

	var player := Player.new()
	player.position = _find_start()
	add_child(player)
	_player = player
	_hud = Hud.new()
	add_child(_hud)
	_hud.bind(player)
	_build_navigation()
	_director = Director.new()
	add_child(_director)
	_spawn_points = _find_all("E")
	queue_redraw()
	_start_wave()


func _start_wave() -> void:
	if _spawn_points.is_empty():
		push_warning("Mapa nie ma punktów pojawiania się przeciwników (E).")
		return
	_wave += 1
	_director.hide_spots.clear()
	_hud.set_stats(_wins, _wave, _player.bullet_damage)
	for i in _wave:
		var spot := _spawn_points[i % _spawn_points.size()]
		if i >= _spawn_points.size():
			spot = _free_spot_near(spot)
		var enemy := Enemy.new()
		enemy.position = spot
		enemy.level = self
		enemy.player = _player
		enemy.director = _director
		add_child(enemy)
		_director.register(enemy)
		_alive += 1
		enemy.died.connect(_on_enemy_died)


func _free_spot_near(spot: Vector2) -> Vector2:
	for attempt in 40:
		var p := spot + Vector2.from_angle(randf() * TAU) * randf_range(24.0, 6.0 * tile)
		if is_free(p) and not _enemy_near(p, 32.0):
			return p
	return spot


func _enemy_near(p: Vector2, radius: float) -> bool:
	for e in _director.enemies:
		if is_instance_valid(e) and e.position.distance_to(p) < radius:
			return true
	return false


func _on_enemy_died() -> void:
	_alive -= 1
	if _alive > 0:
		return
	_wins += 1
	_player.on_victory()
	_hud.set_stats(_wins, _wave, _player.bullet_damage)
	for sec in range(5, 0, -1):
		_hud.show_countdown("Następna fala za %d" % sec)
		await get_tree().create_timer(1.0).timeout
		if not is_inside_tree() or _player.health <= 0.0:
			return
	_hud.show_countdown("")
	_start_wave()


func is_free(p: Vector2) -> bool:
	var t := Vector2i((p / tile).floor())
	return _astar.is_in_boundsv(t) and not _astar.is_point_solid(t)


func _find_all(ch: String) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for y in _rows.size():
		for x in _rows[y].length():
			if _rows[y][x] == ch:
				result.append((Vector2(x, y) + Vector2(0.5, 0.5)) * tile)
	return result


func _is_solid_char(x: int, y: int) -> bool:
	if y < 0 or y >= _rows.size() or x < 0 or x >= _rows[y].length():
		return true
	return _rows[y][x] == "#" or _rows[y][x] == "F"


# Siatka A* dla przeciwników; kafelki przy ścianach i meblach są zablokowane (margines na promień postaci).
func _build_navigation() -> void:
	_astar.region = Rect2i(0, 0, _rows[0].length(), _rows.size())
	_astar.cell_size = Vector2(tile, tile)
	_astar.offset = Vector2(tile, tile) / 2.0
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.update()
	for y in _rows.size():
		for x in _rows[y].length():
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					if _is_solid_char(x + dx, y + dy):
						_astar.set_point_solid(Vector2i(x, y))


func _nearest_free(t: Vector2i) -> Vector2i:
	for r in range(0, 7):
		for dy in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) != r:
					continue
				var c := t + Vector2i(dx, dy)
				if _astar.is_in_boundsv(c) and not _astar.is_point_solid(c):
					return c
	return Vector2i(-1, -1)


func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _nearest_free(Vector2i((from / tile).floor()))
	var b := _nearest_free(Vector2i((to / tile).floor()))
	if a.x < 0 or b.x < 0:
		return PackedVector2Array()
	return _astar.get_point_path(a, b)


## Czy między punktami nie ma ściany (meble nie zasłaniają widoku).
func line_clear(a: Vector2, b: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(a, b, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


## Kryjówka dla przeciwnika: daleko od zagrożenia, w kącie, najlepiej poza jego linią widzenia.
func find_hiding_spot(from: Vector2, threat: Vector2, taken: Array[Vector2] = []) -> Vector2:
	var scored: Array = []
	for y in range(2, _rows.size() - 2, 2):
		for x in range(2, _rows[y].length() - 2, 2):
			if _astar.is_point_solid(Vector2i(x, y)):
				continue
			var p := (Vector2(x, y) + Vector2(0.5, 0.5)) * tile
			var cover := 0
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					if _is_solid_char(x + dx, y + dy):
						cover += 1
			scored.append([threat.distance_to(p) * 0.5 + cover * 12.0 - from.distance_to(p) * 0.3, p])
	scored.sort_custom(func(m, n): return m[0] > n[0])
	var best := from
	var best_score := -INF
	for i in mini(30, scored.size()):
		var p: Vector2 = scored[i][1]
		if find_path(from, p).is_empty():
			continue
		var score: float = scored[i][0] + (0.0 if line_clear(threat, p) else 400.0)
		for t in taken:
			if t.distance_to(p) < 100.0:
				score -= 250.0
		if score > best_score:
			best_score = score
			best = p
	return best


# Rzut z pliku jako widoczna grafika poziomu, dopasowana do siatki kafelków.
func _add_plan_sprite() -> void:
	if not (_meta.has("image") and _meta.has("roi") and _meta.has("px_per_cm") and _meta.has("tile_cm")):
		return
	var tex := load(map_path.get_base_dir() + "/" + _meta["image"]) as Texture2D
	if tex == null:
		push_warning("Nie można wczytać rzutu: %s" % _meta["image"])
		return
	var roi := (_meta["roi"] as String).split(",")
	var tile_px := float(_meta["tile_cm"]) * float(_meta["px_per_cm"])
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.centered = false
	sprite.region_enabled = true
	sprite.region_rect = Rect2(int(roi[0]), int(roi[1]), int(roi[2]), int(roi[3]))
	sprite.scale = Vector2.ONE * (tile / tile_px)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)


func _load_rows(path: String) -> PackedStringArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedStringArray()
	var rows := PackedStringArray()
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with(";"):
			var kv := line.substr(1).split("=", true, 1)
			if kv.size() == 2:
				_meta[kv[0].strip_edges()] = kv[1].strip_edges()
		elif line != "":
			rows.append(line)
	return rows


func _find_start() -> Vector2:
	for y in _rows.size():
		var x := _rows[y].find("P")
		if x >= 0:
			return (Vector2(x, y) + Vector2(0.5, 0.5)) * tile
	return Vector2(tile * 2, tile * 2)


# Scala sąsiednie kafelki ścian w większe prostokąty (mniej kształtów kolizji).
func _merge_walls(rows: PackedStringArray, kind: String) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	var open_runs := {} # "x0,x1" -> indeks prostokąta w result, który można przedłużyć w dół
	for y in rows.size():
		var current := {}
		var line := rows[y]
		var x := 0
		while x < line.length():
			if line[x] != kind:
				x += 1
				continue
			var x0 := x
			while x < line.length() and line[x] == kind:
				x += 1
			var key := "%d,%d" % [x0, x]
			if open_runs.has(key):
				var i: int = open_runs[key]
				result[i].size.y += 1
				current[key] = i
			else:
				result.append(Rect2i(x0, y, x - x0, 1))
				current[key] = result.size() - 1
		open_runs = current
	return result


func _draw() -> void:
	if _rows.is_empty() or not show_collisions:
		return
	var cols: int = _rows[0].length()
	draw_rect(Rect2(0, 0, cols * tile, _rows.size() * tile), Color(0.1, 0.1, 0.12))
	for r in _wall_rects:
		draw_rect(Rect2(Vector2(r.position * tile), Vector2(r.size * tile)), Color(0.35, 0.35, 0.42))
	for r in _furniture_rects:
		draw_rect(Rect2(Vector2(r.position * tile), Vector2(r.size * tile)), Color(0.5, 0.35, 0.2))
