class_name PauseOverlay
extends CanvasLayer

## Spacja wstrzymuje i wznawia grę. Aktywne dopiero po starcie z menu.
var enabled := false
var _root: Control


func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.04, 0.07, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 24)
	_root.add_child(box)

	var title := Label.new()
	title.text = "ODPOCZYNEK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	box.add_child(title)

	var hint := Label.new()
	hint.text = "Wciśnij ponownie spację, aby wrócić do gry"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 28)
	box.add_child(hint)


func _unhandled_key_input(event: InputEvent) -> void:
	if not enabled or not (event is InputEventKey):
		return
	if event.pressed and not event.echo and event.physical_keycode == KEY_SPACE:
		get_tree().paused = not get_tree().paused
		_root.visible = get_tree().paused
		get_viewport().set_input_as_handled()
