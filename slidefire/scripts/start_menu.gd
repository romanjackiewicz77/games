class_name StartMenu
extends CanvasLayer

signal started


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.09, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 28)
	add_child(box)

	var title := Label.new()
	title.text = "SLIDEFIRE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 110)
	title.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	title.add_theme_color_override("font_outline_color", Color(0.5, 0.1, 0.05))
	title.add_theme_constant_override("outline_size", 12)
	box.add_child(title)

	var button := Button.new()
	button.text = "START"
	button.custom_minimum_size = Vector2(260, 70)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(_on_pressed)
	box.add_child(button)
	button.grab_focus()

	var help := Label.new()
	help.text = "\n".join([
		"STEROWANIE",
		"WSAD / strzałki – ruch,  mysz – celowanie,  spacja – pauza",
		"LPM – strzał z karabinu (przytrzymaj dłużej niż 0,4 s: super strzelanie",
		"przez maks. 5 s, +50% szybkości, pociski 30% siły, odnowienie 15 s)",
		"PPM – granat z falą uderzeniową (2 rzuty, potem 4 s przerwy)",
	])
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 18)
	help.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	box.add_child(help)


func _on_pressed() -> void:
	started.emit()
	queue_free()
