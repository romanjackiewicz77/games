"""Podgląd mapy Slidefire: ściany z pliku .txt nałożone na rzut, z siatką i numerami.

Użycie (z folderu slidefire):
    python tools/map_preview.py maps/map_01.txt
Zapisuje maps/map_01_preview.png. Co 10. wiersz/kolumna jest opisany liczbą,
dzięki czemu łatwo wskazać kafelki do poprawy w pliku mapy.
"""
import sys
from pathlib import Path

import cv2
import numpy as np

LABEL_EVERY = 10


def read_map(path: Path) -> tuple[dict[str, str], list[str]]:
    meta: dict[str, str] = {}
    rows: list[str] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.startswith(";"):
            key, _, value = line[1:].strip().partition("=")
            meta[key.strip()] = value.strip()
        elif line:
            rows.append(line)
    return meta, rows


def main() -> None:
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    path = Path(sys.argv[1])
    meta, rows = read_map(path)
    roi = [int(v) for v in meta["roi"].split(",")]
    tile_px = float(meta["tile_cm"]) * float(meta["px_per_cm"])

    plan = cv2.imread(str(path.parent / meta["image"]))
    x0, y0, w, h = roi
    view = plan[y0 : y0 + h, x0 : x0 + w].copy()
    overlay = view.copy()

    for r, line in enumerate(rows):
        for c, ch in enumerate(line):
            p1 = (int(c * tile_px), int(r * tile_px))
            p2 = (int((c + 1) * tile_px), int((r + 1) * tile_px))
            if ch == "#":
                cv2.rectangle(overlay, p1, p2, (0, 0, 255), -1)
            elif ch == "F":
                cv2.rectangle(overlay, p1, p2, (0, 165, 255), -1)
            elif ch == "P":
                cv2.rectangle(overlay, p1, p2, (0, 200, 0), -1)
    view = cv2.addWeighted(overlay, 0.45, view, 0.55, 0)

    for i in range(0, len(rows[0]), LABEL_EVERY):
        x = int(i * tile_px)
        cv2.line(view, (x, 0), (x, view.shape[0]), (255, 120, 0), 1)
        cv2.putText(view, str(i), (x + 2, 14), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 1, cv2.LINE_AA)
    for j in range(0, len(rows), LABEL_EVERY):
        y = int(j * tile_px)
        cv2.line(view, (0, y), (view.shape[1], y), (255, 120, 0), 1)
        cv2.putText(view, str(j), (2, y - 3), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 0, 0), 1, cv2.LINE_AA)

    out = path.with_name(path.stem + "_preview.png")
    cv2.imwrite(str(out), view)
    print(f"zapisano {out}")


if __name__ == "__main__":
    main()
