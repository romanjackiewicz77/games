class_name Sfx
extends RefCounted

## Dźwięki generowane w kodzie (bez plików audio).
const RATE := 22050

static var _cache := {}


static func play(parent: Node, sound: String, pos: Vector2, volume_db := 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := AudioStreamPlayer2D.new()
	p.stream = _stream_for(sound)
	p.volume_db = volume_db
	p.max_distance = 1400.0
	p.global_position = pos
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.play()


static func _stream_for(sound: String) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = _build(sound)
	return _cache[sound]


static func _build(sound: String) -> AudioStreamWAV:
	var length := 0.25
	match sound:
		"shot_player": length = 0.18
		"shot_enemy": length = 0.22
		"death": length = 0.6
	var n := int(RATE * length)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sound)
	var low := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var s := 0.0
		match sound:
			"shot_player":
				low += (rng.randf_range(-1.0, 1.0) - low) * 0.5
				s = (low * 0.9 + sin(TAU * lerpf(900.0, 200.0, minf(k * 4.0, 1.0)) * t) * 0.5) * exp(-k * 7.0)
			"shot_enemy":
				low += (rng.randf_range(-1.0, 1.0) - low) * 0.3
				s = (low * 0.8 + sin(TAU * lerpf(500.0, 120.0, minf(k * 4.0, 1.0)) * t) * 0.6) * exp(-k * 6.0)
			"death":
				low += (rng.randf_range(-1.0, 1.0) - low) * 0.15
				var f := lerpf(380.0, 70.0, k)
				s = (sign(sin(TAU * f * t)) * 0.35 + low * 0.5) * exp(-k * 3.5)
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 26000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
