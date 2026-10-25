class_name Music
extends Node
## Action background music generated in code (no audio files). Built in a thread, then looped quietly.

const RATE := 22050
const BPM := 138.0
const VOLUME_DB := -15.8
const ROOTS := [55.0, 43.65, 65.41, 49.0]
const THIRDS := [3, 4, 4, 4]
const ARP := [0, 1, 2, 1, 0, 2, 1, 2]

static var _stream: AudioStreamWAV
static var _menu_stream: AudioStreamWAV

## Menu variant: slower, no snare, softer; plays even while the game tree is paused.
var menu := false

var _thread: Thread
var _player: AudioStreamPlayer


func _ready() -> void:
	if menu:
		process_mode = Node.PROCESS_MODE_ALWAYS
	var cached := _menu_stream if menu else _stream
	if cached != null:
		_start(cached)
		return
	_thread = Thread.new()
	_thread.start(_build_track.bind(menu))


func _process(_delta: float) -> void:
	if _thread != null and not _thread.is_alive():
		_finish()


func _exit_tree() -> void:
	if _thread != null:
		_thread.wait_to_finish()
		_thread = null


func _finish() -> void:
	var built: AudioStreamWAV = _thread.wait_to_finish()
	_thread = null
	if menu:
		_menu_stream = built
	else:
		_stream = built
	_start(built)


func _start(stream: AudioStreamWAV) -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = stream
	_player.volume_db = VOLUME_DB - (3.0 if menu else 0.0)
	add_child(_player)
	_player.play()


static func _build_track(menu_variant := false) -> AudioStreamWAV:
	var bpm := 96.0 if menu_variant else BPM
	var step := int(RATE * 60.0 / bpm / 4.0)
	var steps := 128
	var n := step * steps
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for s in steps:
		var bar := s / 16
		var chord := (bar / 2) % 4
		var root: float = ROOTS[chord]
		var third: int = THIRDS[chord]
		var pos := s % 16
		var at := s * step
		if pos % 4 == 0 and (not menu_variant or pos % 8 == 0):
			_kick(buf, at, n)
		if not menu_variant and (pos == 4 or pos == 12):
			_snare(buf, at, n, rng)
		if not menu_variant and pos % 2 == 0:
			_hat(buf, at, n, rng, 0.05 if pos % 4 == 0 else 0.09)
		if pos % 2 == 0 or pos == 7 or pos == 15:
			_bass(buf, at, n, root)
		var semis := [0, third, 7]
		var tone: int = semis[ARP[s % ARP.size()]]
		if not menu_variant or pos % 2 == 0:
			_pluck(buf, at, n, root * 4.0 * pow(2.0, tone / 12.0), 0.06)
	var peak := 0.001
	for v in buf:
		peak = maxf(peak, absf(v))
	for i in n:
		buf[i] = buf[i] / peak * 0.85
	var wav := Sfx._to_wav(buf)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav


static func _kick(buf: PackedFloat32Array, at: int, n: int) -> void:
	var phase := 0.0
	for i in int(RATE * 0.2):
		var t := float(i) / RATE
		phase += TAU * (45.0 + 90.0 * exp(-t * 28.0)) / RATE
		buf[(at + i) % n] += sin(phase) * exp(-t * 14.0) * 0.9


static func _snare(buf: PackedFloat32Array, at: int, n: int, rng: RandomNumberGenerator) -> void:
	for i in int(RATE * 0.16):
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		buf[(at + i) % n] += (noise * 0.5 + sin(TAU * 190.0 * t) * 0.35) * exp(-t * 22.0)


static func _hat(buf: PackedFloat32Array, at: int, n: int, rng: RandomNumberGenerator, vol: float) -> void:
	var prev := 0.0
	for i in int(RATE * 0.05):
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		buf[(at + i) % n] += (noise - prev) * vol * exp(-t * 70.0)
		prev = noise


static func _bass(buf: PackedFloat32Array, at: int, n: int, freq: float) -> void:
	var phase := 0.0
	var low := 0.0
	for i in int(RATE * 0.2):
		var t := float(i) / RATE
		phase += freq / RATE
		var saw := fmod(phase, 1.0) * 2.0 - 1.0
		low += (saw - low) * 0.12
		buf[(at + i) % n] += low * exp(-t * 7.0) * 0.55


static func _pluck(buf: PackedFloat32Array, at: int, n: int, freq: float, vol: float) -> void:
	var phase := 0.0
	for i in int(RATE * 0.14):
		var t := float(i) / RATE
		phase += freq / RATE
		var pulse := 1.0 if fmod(phase, 1.0) < 0.25 else -1.0
		buf[(at + i) % n] += pulse * vol * exp(-t * 16.0)
