# Slidefire

Slidefire – strzelanka 2D z widokiem z góry, zrobiona w [Godot](https://godotengine.org/) 4 (GDScript – język o składni zbliżonej do Pythona).

## Wymagania

- Godot 4.3+

## Uruchomienie

1. Otwórz Godot → Import → wskaż `project.godot`.
2. Naciśnij F5 (główna scena: `scenes/Level.tscn`).

## Sterowanie

- **WSAD** – ruch (z poślizgiem)
- **Mysz** – celowanie
- **LPM** – strzał w kierunku kursora

## Struktura

- `scripts/player.gd` – ruch z przyspieszeniem/tarciem, celowanie, strzelanie
- `scripts/bullet.gd` – pocisk, znika po trafieniu w ścianę lub po czasie
- `scripts/level.gd` – korytarze budowane z układu ASCII (`LAYOUT`), kolizje ścian
- `scripts/input_setup.gd` – rejestracja akcji wejścia
