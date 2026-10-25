class_name GameOver
extends CanvasLayer
## End-of-game screen shown after the player dies.

signal play_again
signal to_menu


func setup(time_text: String, wave: int) -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.0, 0.02, 0.88)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 26)
	add_child(box)

	var title := Label.new()
	title.text = "KONIEC GRY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 80)
	title.add_theme_color_override("font_color", Color(0.9, 0.12, 0.12))
	title.add_theme_color_override("font_outline_color", Color(0.15, 0.0, 0.0))
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)

	var story := Label.new()
	story.text = "SWAT wpadło do mieszkania i Cię zabiło,\nzabierając pyszny salceson z lodówki."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 34)
	box.add_child(story)

	var stats := Label.new()
	stats.text = "Czas przeżycia: %s  (fala %d)" % [time_text, wave]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 26)
	stats.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(stats)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	box.add_child(row)

	var again := _button("ZAGRAJ JESZCZE RAZ")
	again.pressed.connect(func() -> void: play_again.emit())
	row.add_child(again)
	var menu := _button("WYJDŹ DO MENU")
	menu.pressed.connect(func() -> void: to_menu.emit())
	row.add_child(menu)
	again.grab_focus()


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(340, 70)
	b.add_theme_font_size_override("font_size", 28)
	return b
