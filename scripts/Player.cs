using Godot;

namespace Games;

public partial class Player : CharacterBody2D
{
	[Export] public float MaxSpeed = 320f;
	[Export] public float Acceleration = 1200f;
	[Export] public float Friction = 700f;
	[Export] public float FireRate = 8f;
	[Export] public float BulletSpeed = 900f;

	private const float Radius = 16f;
	private double _cooldown;

	public override void _Ready()
	{
		InputSetup.Ensure();
		CollisionLayer = 2;
		CollisionMask = 1;
		AddChild(new CollisionShape2D { Shape = new CircleShape2D { Radius = Radius } });
		AddChild(new Camera2D { PositionSmoothingEnabled = true });
	}

	public override void _PhysicsProcess(double delta)
	{
		var dir = Input.GetVector("move_left", "move_right", "move_up", "move_down");
		float d = (float)delta;

		// Poślizg: przyspieszenie przy wciśniętym ruchu, tarcie przy puszczeniu klawiszy.
		Velocity = dir != Vector2.Zero
			? Velocity.MoveToward(dir * MaxSpeed, Acceleration * d)
			: Velocity.MoveToward(Vector2.Zero, Friction * d);
		MoveAndSlide();

		var aim = GetGlobalMousePosition() - GlobalPosition;
		if (aim != Vector2.Zero)
			Rotation = aim.Angle();

		_cooldown -= delta;
		if (Input.IsActionPressed("shoot") && _cooldown <= 0)
		{
			Shoot(aim.Normalized());
			_cooldown = 1.0 / FireRate;
		}
	}

	private void Shoot(Vector2 direction)
	{
		if (direction == Vector2.Zero)
			return;
		var bullet = new Bullet
		{
			Position = Position + direction * (Radius + 14f),
			Velocity = direction * BulletSpeed,
		};
		GetParent().AddChild(bullet);
	}

	public override void _Draw()
	{
		DrawCircle(Vector2.Zero, Radius, new Color(0.3f, 0.7f, 1f));
		DrawLine(Vector2.Zero, new Vector2(Radius + 12f, 0), Colors.White, 5f);
	}
}
