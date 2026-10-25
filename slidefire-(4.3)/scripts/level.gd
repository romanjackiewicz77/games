extends Node2D

const TILE := 64

# '#' = ściana, '.' = podłoga, 'P' = start gracza
const LAYOUT := [
	"########################",
	"#P.....#...............#",
	"#......#...............#",
	"#......#.......#.......#",
	"###.####.......#.......#",
	"#..............#...#####",
	"#..............#.......#",
	"#.####.#########.......#",
	"#.#..#.#...............#",
	"#.#..#.#.......####.####",
	"#.#..#.........#.......#",
	"#....#.........#.......#",
	"########################",
]


func _ready() -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)

	var spawn := Vector2(TILE * 1.5, TILE * 1.5)
	for y in LAYOUT.size():
		var row: String = LAYOUT[y]
		for x in row.length():
			var center := Vector2(x + 0.5, y + 0.5) * TILE
			match row[x]:
				"#":
					var shape := CollisionShape2D.new()
					var rect := RectangleShape2D.new()
					rect.size = Vector2(TILE, TILE)
					shape.shape = rect
					shape.position = center
					walls.add_child(shape)
				"P":
					spawn = center

	var player := Player.new()
	player.position = spawn
	add_child(player)


func _draw() -> void:
	for y in LAYOUT.size():
		var row: String = LAYOUT[y]
		for x in row.length():
			var color := Color(0.25, 0.25, 0.3) if row[x] == "#" else Color(0.1, 0.1, 0.12)
			draw_rect(Rect2(x * TILE, y * TILE, TILE, TILE), color)
