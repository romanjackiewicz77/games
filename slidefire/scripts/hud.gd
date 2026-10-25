class_name Hud
extends CanvasLayer

const BAR_SIZE := Vector2(260, 22)

var _current := 1.0
var _maximum := 1.0
var _bar: Control
var _label: Label
var _message: Label
var _stats: Label
var _countdown: Label
var _grenade: Label
var _remaining: Label
var _player: Player


func _process(_delta: float) -> void:
	if _player == null:
		return
	if _player.grenade_charges > 0:
		_grenade.text = "Granaty (PPM): %d / %d" % [_player.grenade_charges, Player.GRENADE_CHARGES]
	else:
		_grenade.text = "Granaty (PPM): odnowienie %.1f s" % _player.grenade_left


func set_stats(wins: int, wave: int, damage: float) -> void:
	_stats.text = "Wygrane walki: %d   Fala: %d   Obrażenia: %.1f" % [wins, wave, damage]


func set_remaining(count: int) -> void:
	_remaining.text = "Pozostali przeciwnicy: %d" % count


func show_countdown(text: String) -> void:
	_countdown.text = text
	_countdown.visible = text != ""


func _ready() -> void:
	_bar = Control.new()
	_bar.position = Vector2(20, 20)
	_bar.size = BAR_SIZE
	_bar.draw.connect(_draw_bar)
	add_child(_bar)

	_label = Label.new()
	_label.position = Vector2(28, 19)
	add_child(_label)

	_stats = Label.new()
	_stats.position = Vector2(20, 48)
	add_child(_stats)

	_grenade = Label.new()
	_grenade.position = Vector2(20, 72)
	add_child(_grenade)

	_remaining = Label.new()
	_remaining.position = Vector2(20, 96)
	add_child(_remaining)

	_countdown = Label.new()
	_countdown.visible = false
	_countdown.add_theme_font_size_override("font_size", 40)
	_countdown.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_countdown.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_countdown.position.y = 60
	add_child(_countdown)

	_message = Label.new()
	_message.visible = false
	_message.text = "Zginąłeś! Restart za chwilę..."
	_message.add_theme_font_size_override("font_size", 32)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_message)


func bind(player: Player) -> void:
	_player = player
	player.health_changed.connect(set_health)
	player.died.connect(_on_died)
	set_health(player.health, player.max_health)


func set_health(current: float, maximum: float) -> void:
	_current = current
	_maximum = maximum
	_label.text = "%d / %d" % [ceili(current), int(maximum)]
	_bar.queue_redraw()


func _draw_bar() -> void:
	_bar.draw_rect(Rect2(Vector2.ZERO, BAR_SIZE), Color(0, 0, 0, 0.6))
	var ratio := clampf(_current / _maximum, 0.0, 1.0)
	var color := Color(0.2, 0.8, 0.3).lerp(Color(0.9, 0.15, 0.15), 1.0 - ratio)
	_bar.draw_rect(Rect2(Vector2(2, 2), Vector2((BAR_SIZE.x - 4) * ratio, BAR_SIZE.y - 4)), color)


func set_death_text(text: String) -> void:
	_message.text = text


func _on_died() -> void:
	_message.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().reload_current_scene()
