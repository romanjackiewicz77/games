class_name Scores
extends RefCounted

const PATH := "user://scores.json"


static func load_all() -> Array:
	if not FileAccess.file_exists(PATH):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return data if data is Array else []


## Zapisuje wynik gry: czas przeżycia (s) i osiągniętą falę.
static func add(seconds: float, wave: int) -> void:
	var all := load_all()
	all.append({"time": seconds, "wave": wave, "date": Time.get_datetime_string_from_system(false, true)})
	all.sort_custom(func(a, b) -> bool: return a["time"] > b["time"])
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(all.slice(0, 50)))


static func top(count: int) -> Array:
	return load_all().slice(0, count)


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
