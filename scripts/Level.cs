using Godot;

namespace Games;

public partial class Level : Node2D
{
	private const int Tile = 64;

	// '#' = ściana, '.' = podłoga, 'P' = start gracza
	private static readonly string[] Layout =
	{
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
	};

	public override void _Ready()
	{
		var walls = new StaticBody2D { CollisionLayer = 1, CollisionMask = 0 };
		AddChild(walls);

		var spawn = new Vector2(Tile * 1.5f, Tile * 1.5f);
		for (int y = 0; y < Layout.Length; y++)
		{
			for (int x = 0; x < Layout[y].Length; x++)
			{
				var center = new Vector2(x + 0.5f, y + 0.5f) * Tile;
				switch (Layout[y][x])
				{
					case '#':
						walls.AddChild(new CollisionShape2D
						{
							Position = center,
							Shape = new RectangleShape2D { Size = new Vector2(Tile, Tile) },
						});
						break;
					case 'P':
						spawn = center;
						break;
				}
			}
		}

		AddChild(new Player { Position = spawn });
	}

	public override void _Draw()
	{
		for (int y = 0; y < Layout.Length; y++)
		{
			for (int x = 0; x < Layout[y].Length; x++)
			{
				var color = Layout[y][x] == '#' ? new Color(0.25f, 0.25f, 0.3f) : new Color(0.1f, 0.1f, 0.12f);
				DrawRect(new Rect2(x * Tile, y * Tile, Tile, Tile), color);
			}
		}
	}
}
