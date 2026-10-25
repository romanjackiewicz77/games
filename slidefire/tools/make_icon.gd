extends SceneTree
## Generates icon.png and icon.ico (enemy character on a dark background).

func _make(n: int) -> Image:
	var ss := 3
	var big := n * ss
	var img := Image.create(big, big, false, Image.FORMAT_RGBA8)
	var c := Vector2(big, big) / 2.0
	var u := float(big) / 256.0
	for y in big:
		for x in big:
			var p := Vector2(x + 0.5, y + 0.5)
			var col := Color(0, 0, 0, 0)
			var q := (p - c).abs() - Vector2(c.x - 14 * u, c.y - 14 * u) + Vector2(36 * u, 36 * u)
			var rd := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - 36 * u
			if rd < 0.0:
				col = Color(0.08, 0.1, 0.16).lerp(Color(0.18, 0.2, 0.3), p.y / big)
				var d := p - c + Vector2(34, 0) * u
				if d.length() < 78 * u:
					col = Color(0.6, 0.1, 0.1)
				if d.length() < 70 * u:
					col = Color(0.88, 0.25, 0.22)
				if d.length() < 40 * u and d.x < 22 * u:
					col = Color(0.55, 0.12, 0.12)
				if p.x > c.x + 0 * u and p.x < c.x + 88 * u and absf(p.y - c.y - 6 * u) < 12 * u:
					col = Color(0.05, 0.05, 0.06)
				var m := p - (c + Vector2(96, 6) * u)
				if m.length() < 22 * u:
					col = Color(1.0, 0.85, 0.3)
				if m.length() < 11 * u:
					col = Color(1, 1, 0.9)
			img.set_pixel(x, y, col)
	img.resize(n, n, Image.INTERPOLATE_LANCZOS)
	return img


func _initialize() -> void:
	var sizes := [256, 128, 64, 48, 32, 16]
	var pngs := []
	for s in sizes:
		pngs.append(_make(s).save_png_to_buffer())
	_make(256).save_png("res://icon.png")
	var ico := PackedByteArray()
	ico.append_array([0, 0, 1, 0, sizes.size(), 0])
	var offset := 6 + 16 * sizes.size()
	for i in sizes.size():
		var s: int = sizes[i]
		var d := PackedByteArray()
		d.resize(16)
		d[0] = 0 if s >= 256 else s
		d[1] = 0 if s >= 256 else s
		d.encode_u16(4, 1)
		d.encode_u16(6, 32)
		d.encode_u32(8, pngs[i].size())
		d.encode_u32(12, offset)
		ico.append_array(d)
		offset += pngs[i].size()
	for p in pngs:
		ico.append_array(p)
	var f := FileAccess.open("res://icon.ico", FileAccess.WRITE)
	f.store_buffer(ico)
	f.close()
	quit()
