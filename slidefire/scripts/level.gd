extends Node2D

## Plik mapy (tekst: '#' ściana, '.' podłoga, 'P' start; linie od ';' to nagłówek).
@export_file("*.txt") var map_path := "res://maps/map_02.txt"
## Rozmiar kafelka w pikselach gry (kafelek mapy = 12 cm).
@export var tile := 16

var _rows: PackedStringArray = []
var _wall_rects: Array[Rect2i] = []
var _furniture_rects: Array[Rect2i] = []
var _meta := {}

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
	queue_redraw()


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
