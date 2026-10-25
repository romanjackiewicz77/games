# Slidefire

Slidefire – strzelanka 2D z widokiem z góry, zrobiona w [Godot](https://godotengine.org/) 4 (GDScript – język o składni zbliżonej do Pythona).

## Wymagania

- Godot 4.3+

## Uruchomienie

1. Otwórz Godot → Import → wskaż `project.godot`.
2. Naciśnij F5 (główna scena: `scenes/Level.tscn`).

## Sterowanie

- **WSAD** – ruch względem świata (z poślizgiem): góra/dół/lewo/prawo na ekranie, niezależnie od celowania
- **Mysz** – celowanie
- **LPM** – strzał w kierunku kursora

## Struktura

- `scripts/player.gd` – ruch z przyspieszeniem/tarciem, celowanie, strzelanie
- `scripts/bullet.gd` – pocisk, znika po trafieniu w ścianę lub po czasie
- `scripts/level.gd` – wczytuje mapę z pliku tekstowego (`maps/*.txt`) i buduje kolizje ścian
- `scripts/input_setup.gd` – rejestracja akcji wejścia
- `maps/` – rzuty (obrazy), mapy tekstowe i podglądy
- `tools/` – narzędzia w Pythonie do tworzenia map

## Mapa z rzutu technicznego

Kafelek mapy = 12 cm w rzeczywistości. Wymagania: Python 3 i `pip install -r tools/requirements.txt`.

1. Wygeneruj szkic (z folderu `slidefire`):
   `python tools/plan_to_map.py maps/map_01.jpg --out maps/map_01.txt`
   (parametry: `--roi x,y,w,h` obszar mapy w px, `--px-per-cm` skala rzutu, `--start x,y` start gracza)
2. Zrób podgląd z siatką: `python tools/map_preview.py maps/map_01.txt` → `maps/map_01_preview.png`
   (numery wierszy i kolumn co 10).
3. Popraw `maps/map_01.txt` ręcznie: `#` ściana, `.` podłoga, `P` start. Usuń fałszywe ściany
   (np. meble) i dodaj brakujące, potem powtórz krok 2.
4. Plik mapy wczytuje `scripts/level.gd` (zmienna `map_path`).
