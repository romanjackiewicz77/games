using Godot;

namespace Games;

public static class InputSetup
{
	// Rejestruje akcje (WSAD + LPM), jeśli nie ma ich jeszcze w Input Map.
	public static void Ensure()
	{
		AddKey("move_up", Key.W);
		AddKey("move_down", Key.S);
		AddKey("move_left", Key.A);
		AddKey("move_right", Key.D);

		if (!InputMap.HasAction("shoot"))
		{
			InputMap.AddAction("shoot");
			InputMap.ActionAddEvent("shoot", new InputEventMouseButton { ButtonIndex = MouseButton.Left });
		}
	}

	private static void AddKey(string action, Key key)
	{
		if (InputMap.HasAction(action))
			return;
		InputMap.AddAction(action);
		InputMap.ActionAddEvent(action, new InputEventKey { PhysicalKeycode = key });
	}
}
