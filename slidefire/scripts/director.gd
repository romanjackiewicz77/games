class_name Director
extends Node

## Koordynuje przeciwników: kolejność strzelania i rozmieszczenie wokół gracza.
enum Mode { ALTERNATE, ALL }

const TURN_SECONDS := 0.7
const VOLLEY_PERIOD := 1.6
const VOLLEY_WINDOW := 0.6

var mode := Mode.ALTERNATE
var enemies: Array[Enemy] = []
## Kryjówki już zajęte przez uciekających przeciwników.
var hide_spots: Array[Vector2] = []

var _clock := 0.0
var _phase := 0.0
var _mode_timer := 6.0


func register(enemy: Enemy) -> void:
	enemies.append(enemy)
	enemy.died.connect(func() -> void: enemies.erase(enemy))


func _physics_process(delta: float) -> void:
	_clock += delta
	_phase += 0.25 * delta
	_mode_timer -= delta
	if _mode_timer <= 0.0:
		mode = Mode.ALL if randf() < 0.5 else Mode.ALTERNATE
		_mode_timer = randf_range(5.0, 9.0)


## Czy przeciwnik może teraz strzelać: naprzemiennie (jeden po drugim) albo wszyscy naraz w salwach.
func can_fire(enemy: Enemy) -> bool:
	if enemies.size() <= 1:
		return true
	if mode == Mode.ALL:
		return fmod(_clock, VOLLEY_PERIOD) < VOLLEY_WINDOW
	var turn := int(_clock / TURN_SECONDS) % enemies.size()
	return enemies[turn] == enemy


## Kąt, pod którym przeciwnik ma zająć pozycję wokół gracza (okrążanie z kilku stron).
func slot_angle(enemy: Enemy) -> float:
	var idx := enemies.find(enemy)
	return _phase + maxi(idx, 0) * TAU / maxi(enemies.size(), 1)
