class_name InputSetup


# Rejestruje akcje (WSAD + LPM), jeśli nie ma ich jeszcze w Input Map.
static func ensure() -> void:
	_add_key("move_up", KEY_W)
	_add_key("move_down", KEY_S)
	_add_key("move_left", KEY_A)
	_add_key("move_right", KEY_D)
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", click)


static func _add_key(action: String, key: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
