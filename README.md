# games

Strzelanka 2D z widokiem z góry, zrobiona w [Godot](https://godotengine.org/) 4 (.NET / C#).

## Wymagania

- Godot 4.3+ w wersji **.NET** (Mono)
- .NET SDK 8

## Uruchomienie

1. Otwórz Godot → Import → wskaż `project.godot`.
2. Naciśnij F5 (główna scena: `scenes/Level.tscn`).

## Sterowanie

- **WSAD** – ruch (z poślizgiem)
- **Mysz** – celowanie
- **LPM** – strzał w kierunku kursora

## Struktura

- `scripts/Player.cs` – ruch z przyspieszeniem/tarciem, celowanie, strzelanie
- `scripts/Bullet.cs` – pocisk, znika po trafieniu w ścianę lub po czasie
- `scripts/Level.cs` – korytarze budowane z układu ASCII (`Layout`), kolizje ścian
- `scripts/InputSetup.cs` – rejestracja akcji wejścia
