class_name InputSetup


# Rejestruje akcje (WSAD + LPM), jeśli nie ma ich jeszcze w Input Map.
static func ensure() -> void:
	_add_key("move_up", KEY_W, KEY_UP)
	_add_key("move_down", KEY_S, KEY_DOWN)
	_add_key("move_left", KEY_A, KEY_LEFT)
	_add_key("move_right", KEY_D, KEY_RIGHT)
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", click)
	if not InputMap.has_action("grenade"):
		InputMap.add_action("grenade")
		var rmb := InputEventMouseButton.new()
		rmb.button_index = MOUSE_BUTTON_RIGHT
		InputMap.action_add_event("grenade", rmb)


static func _add_key(action: String, key: Key, alt: Key = KEY_NONE) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
	if alt != KEY_NONE:
		var ev2 := InputEventKey.new()
		ev2.physical_keycode = alt
		InputMap.action_add_event(action, ev2)
