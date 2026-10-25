extends Node2D

## Plik mapy (tekst: '#' ściana, '.' podłoga, 'P' start; linie od ';' to nagłówek).
@export_file("*.txt") var map_path := "res://maps/map_01.txt"
## Rozmiar kafelka w pikselach gry (kafelek mapy = 12 cm).
@export var tile := 16

var _rows: PackedStringArray = []
var _wall_rects: Array[Rect2i] = []


func _ready() -> void:
	_rows = _load_rows(map_path)
	if _rows.is_empty():
		push_error("Nie można wczytać mapy: %s" % map_path)
		return

	_wall_rects = _merge_walls(_rows)
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	for r in _wall_rects:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(r.size * tile)
		shape.shape = rect
		shape.position = Vector2(r.position * tile) + rect.size / 2.0
		walls.add_child(shape)

	var player := Player.new()
	player.position = _find_start()
	add_child(player)
	queue_redraw()


func _load_rows(path: String) -> PackedStringArray:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return PackedStringArray()
	var rows := PackedStringArray()
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line != "" and not line.begins_with(";"):
			rows.append(line)
	return rows


func _find_start() -> Vector2:
	for y in _rows.size():
		var x := _rows[y].find("P")
		if x >= 0:
			return (Vector2(x, y) + Vector2(0.5, 0.5)) * tile
	return Vector2(tile * 2, tile * 2)


# Scala sąsiednie kafelki ścian w większe prostokąty (mniej kształtów kolizji).
func _merge_walls(rows: PackedStringArray) -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	var open_runs := {} # "x0,x1" -> indeks prostokąta w result, który można przedłużyć w dół
	for y in rows.size():
		var current := {}
		var line := rows[y]
		var x := 0
		while x < line.length():
			if line[x] != "#":
				x += 1
				continue
			var x0 := x
			while x < line.length() and line[x] == "#":
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
	if _rows.is_empty():
		return
	var cols: int = _rows[0].length()
	draw_rect(Rect2(0, 0, cols * tile, _rows.size() * tile), Color(0.1, 0.1, 0.12))
	for r in _wall_rects:
		draw_rect(Rect2(Vector2(r.position * tile), Vector2(r.size * tile)), Color(0.35, 0.35, 0.42))
