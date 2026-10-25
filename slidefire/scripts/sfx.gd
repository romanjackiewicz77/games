class_name Sfx
extends RefCounted

## Dźwięki generowane w kodzie (bez plików audio).
const RATE := 22050
const DEATH_VARIANTS := 5
const SOUNDS := ["shot_player", "shot_enemy", "boom", "death_0", "death_1", "death_2", "death_3", "death_4"]

static var _cache := {}


## Buduje wszystkie dźwięki z góry, żeby pierwsze użycie nie powodowało przycięcia gry.
static func warmup() -> void:
	for s in SOUNDS:
		_stream_for(s)


static func play(parent: Node, sound: String, pos: Vector2, volume_db := 0.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	if sound == "death":
		sound = "death_%d" % (randi() % DEATH_VARIANTS)
	var p := AudioStreamPlayer2D.new()
	p.stream = _stream_for(sound)
	p.volume_db = volume_db
	p.max_distance = 1400.0
	p.pitch_scale = randf_range(0.92, 1.08)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.play()


static func _stream_for(sound: String) -> AudioStreamWAV:
	if not _cache.has(sound):
		_cache[sound] = _to_wav(_build(sound))
	return _cache[sound]


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


static func _build(sound: String) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(sound)
	match sound:
		"shot_player":
			return _rifle(rng, 0.45, 70.0, 0.3, 300.0)
		"shot_enemy":
			return _rifle(rng, 0.6, 55.0, 0.2, 380.0)
		"boom":
			return _explosion(rng)
	return _agony(rng, int(sound.get_slice("_", 1)))


# Strzał z karabinu: ostry trzask, niski huk i krótki pogłos.
static func _rifle(rng: RandomNumberGenerator, bright: float, thump_hz: float, tail_level: float, crack_decay: float) -> PackedFloat32Array:
	var n := int(RATE * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		var crack := (white - prev) * exp(-t * crack_decay) * bright * 1.6
		prev = white
		low += (white - low) * 0.12
		var tail := low * exp(-t * 11.0) * tail_level * 2.0
		var thump := sin(TAU * (thump_hz + 110.0 * exp(-t * 45.0)) * t) * exp(-t * 32.0) * 1.1
		out[i] = tanh((crack + tail + thump) * 1.6)
	return out


# Wybuch: trzask, głęboki basowy huk, dudnienie, które ciemnieje, i odgłosy odłamków.
static func _explosion(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(RATE * 1.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var low := 0.0
	var low2 := 0.0
	var debris := 0.0
	for i in n:
		var t := float(i) / RATE
		var white := rng.randf_range(-1.0, 1.0)
		var coef := lerpf(0.35, 0.03, minf(t / 1.2, 1.0))
		low += (white - low) * coef
		low2 += (low - low2) * 0.2
		var attack := minf(t / 0.004, 1.0)
		var blast := white * exp(-t * 55.0) * 0.9
		var rumble := low * 2.4 * exp(-t * 2.3)
		var sub := sin(TAU * (24.0 + 55.0 * exp(-t * 3.0)) * t) * exp(-t * 2.0) * 1.2
		if rng.randf() < 0.0035 * exp(-t * 2.5):
			debris = rng.randf_range(0.4, 0.9)
		debris *= 0.985
		var crackle := white * debris * 0.5 * exp(-t * 1.5)
		out[i] = tanh((blast + rumble + low2 * 1.5 * exp(-t * 3.0) + sub + crackle) * attack * 1.3)
	return out


# Różne odgłosy agonii: krzyk, jęk, "aaargh", charczenie i płacz.
static func _agony(rng: RandomNumberGenerator, variant: int) -> PackedFloat32Array:
	var length: float = [0.9, 1.1, 0.85, 1.0, 0.85][variant]
	var n := int(RATE * length)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var breath := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := float(i) / n
		var f0 := 200.0
		var f1 := 800.0
		var f2 := 1200.0
		var amp := 1.0
		var noise_mix := 0.0
		match variant:
			0: # krzyk: wysoki, opadający, z wibrato
				f0 = lerpf(650.0, 240.0, k) * (1.0 + 0.03 * sin(TAU * 9.0 * t))
				f1 = 850.0
				f2 = 1300.0
				amp = minf(k * 20.0, 1.0) * pow(1.0 - k, 0.7)
				noise_mix = 0.12
			1: # jęk: niski, z warczeniem
				f0 = lerpf(150.0, 70.0, k) * (1.0 + 0.04 * sin(TAU * 5.0 * t))
				f1 = 450.0
				f2 = 800.0
				amp = minf(k * 8.0, 1.0) * (1.0 - k) * (0.7 + 0.3 * sin(TAU * 28.0 * t))
				noise_mix = 0.2
			2: # "aaargh": głos przechodzący w "u" z drżeniem
				f0 = lerpf(320.0, 110.0, k) * (1.0 + rng.randf_range(-0.03, 0.03))
				f1 = lerpf(850.0, 350.0, k)
				f2 = lerpf(1300.0, 800.0, k)
				amp = minf(k * 15.0, 1.0) * (1.0 - k * 0.8) * (0.6 + 0.4 * sin(TAU * 17.0 * t))
				noise_mix = 0.25
			3: # charczenie: prawie sam oddech i rzężenie
				f0 = lerpf(110.0, 60.0, k)
				f1 = 500.0
				f2 = 1000.0
				amp = (1.0 - k) * (0.35 + 0.65 * maxf(0.0, sin(TAU * 8.0 * t)))
				noise_mix = 0.75
			4: # płacz: wznosi się, a potem opada
				var arc := sin(PI * k)
				f0 = lerpf(300.0, 700.0, arc) * (1.0 + 0.05 * sin(TAU * 7.0 * t))
				f1 = 420.0
				f2 = 2000.0
				amp = minf(k * 12.0, 1.0) * (1.0 - k * 0.7)
		phase += TAU * f0 / RATE
		# Głos: suma harmonicznych ważona dwoma pasmami formantów (jak samogłoska).
		var voice := 0.0
		var h := 1
		while h * f0 < 4000.0 and h < 24:
			var hf := h * f0
			var w := exp(-pow((hf - f1) / 280.0, 2.0)) + 0.6 * exp(-pow((hf - f2) / 400.0, 2.0)) + 0.08
			voice += sin(phase * h) * w / sqrt(float(h))
			h += 1
		breath += (rng.randf_range(-1.0, 1.0) - breath) * 0.25
		var s := (voice * 0.28 * (1.0 - noise_mix) + breath * noise_mix * 1.4) * amp
		out[i] = tanh(s * 1.4)
	return out
