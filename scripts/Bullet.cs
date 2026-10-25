using Godot;

namespace Games;

public partial class Bullet : Area2D
{
	public Vector2 Velocity;
	[Export] public double Lifetime = 2.0;

	public override void _Ready()
	{
		CollisionLayer = 0;
		CollisionMask = 1;
		AddChild(new CollisionShape2D { Shape = new CircleShape2D { Radius = 4f } });
		BodyEntered += _ => QueueFree();
	}

	public override void _PhysicsProcess(double delta)
	{
		Position += Velocity * (float)delta;
		Lifetime -= delta;
		if (Lifetime <= 0)
			QueueFree();
	}

	public override void _Draw() => DrawCircle(Vector2.Zero, 4f, Colors.Yellow);
}
