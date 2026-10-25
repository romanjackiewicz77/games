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

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)

	var button := Button.new()
	button.text = "START"
	button.custom_minimum_size = Vector2(260, 70)
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(_on_pressed)
	row.add_child(button)
	button.grab_focus()

	var scores_button := Button.new()
	scores_button.text = "WYNIKI"
	scores_button.custom_minimum_size = Vector2(260, 70)
	scores_button.add_theme_font_size_override("font_size", 32)
	row.add_child(scores_button)

	var scores := Label.new()
	scores.visible = false
	scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scores.add_theme_font_size_override("font_size", 24)
	scores.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	box.add_child(scores)
	var help := Label.new()
	help.text = "\n".join([
		"STEROWANIE",
		"WSAD / strzałki – ruch,  mysz – celowanie,  spacja – pauza",
		"LPM – strzał z karabinu (przytrzymaj dłużej niż 0,4 s: super strzelanie",
		"przez maks. 5 s, +50% szybkości, pociski 30% siły, odnowienie 15 s)",
		"PPM – granat z falą uderzeniową (2 rzuty, potem 4 s przerwy)",
		"",
		"FALE",
		"Fala N to N przeciwników. Po każdej fali: pełne leczenie, +5% zdrowia, +10% obrażeń.",
		"Fale 1–4: amatorzy (żółci, wolni, często się wystawiają) i średniacy (pomarańczowi)",
		"Fale 5–9: amatorzy i średniacy + 1 zawodowiec (fioletowy, szybki jak Ty, zawsze strzela, rzuca 2 granaty na falę)",
		"Fale 10–15: głównie średniacy i zawodowcy",
		"Od fali 16: sami zawodowcy",
	])
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95))
	box.add_child(help)

	var footer := Label.new()
	footer.text = "Autorzy: Roman Jackiewicz oraz GitHub Copilot (Claude Sonnet 5.5)  •  25.10.2026"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -40
	footer.offset_bottom = -12
	footer.add_theme_font_size_override("font_size", 16)
	footer.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	add_child(footer)
	scores_button.pressed.connect(func() -> void:
		scores.text = _scores_text()
		scores.visible = not scores.visible
		help.visible = not scores.visible)


func _scores_text() -> String:
	var lines := ["NAJLEPSZE WYNIKI (czas przeżycia)", ""]
	var top := Scores.top(5)
	if top.is_empty():
		lines.append("Brak wyników – zagraj pierwszą grę!")
	for i in top.size():
		var s: Dictionary = top[i]
		lines.append("%d.  %s   (fala %d,  %s)" % [i + 1, Scores.format_time(s["time"]), s["wave"], str(s["date"]).left(10)])
	return "\n".join(lines)

func _on_pressed() -> void:
	started.emit()
	queue_free()
