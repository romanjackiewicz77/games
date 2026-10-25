class_name Hud
extends CanvasLayer

const BAR_SIZE := Vector2(260, 22)

var _current := 1.0
var _maximum := 1.0
var _bar: Control
var _label: Label
var _message: Label


func _ready() -> void:
	_bar = Control.new()
	_bar.position = Vector2(20, 20)
	_bar.size = BAR_SIZE
	_bar.draw.connect(_draw_bar)
	add_child(_bar)

	_label = Label.new()
	_label.position = Vector2(28, 19)
	add_child(_label)

	_message = Label.new()
	_message.visible = false
	_message.text = "Zginąłeś! Restart za chwilę..."
	_message.add_theme_font_size_override("font_size", 32)
	_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_message)


func bind(player: Player) -> void:
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


func _on_died() -> void:
	_message.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
