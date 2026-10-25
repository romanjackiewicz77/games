"""Nanosi ręczne poprawki z pomalowanego podglądu na plik mapy.

Użycie (z folderu slidefire):
    python tools/apply_edits.py maps/map_01.txt maps/map_01_edit.png

Maluj na kopii maps/map_01_preview.png (nie zmieniaj rozmiaru), czystymi kolorami
bez wygładzania (ołówek):
    zielony  #00FF00 -> ściana '#'
    fioletowy #FF00FF -> mebel 'F'
    żółty    #FFFF00 -> podłoga '.'
Kafelek jest zmieniany, gdy zamalowano co najmniej MIN_COVER jego powierzchni.
Pole startu 'P' nigdy nie jest nadpisywane.
"""
import sys
from pathlib import Path

import cv2
import numpy as np

from map_preview import read_map

MIN_COVER = 0.15
TOLERANCE = 30
# kolory w BGR (OpenCV)
PAINTS = {
    "#": (0, 255, 0),
    "F": (255, 0, 255),
    ".": (0, 255, 255),
}


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    path = Path(sys.argv[1])
    meta, rows = read_map(path)
    tile_px = float(meta["tile_cm"]) * float(meta["px_per_cm"])

    img = cv2.imread(sys.argv[2])
    if img is None:
        raise SystemExit(f"nie można wczytać {sys.argv[2]}")
    ref_h = int(meta["roi"].split(",")[3])
    if img.shape[0] != ref_h:
        raise SystemExit("rozmiar obrazu różni się od podglądu - nie zmieniaj rozmiaru")

    masks = {
        ch: np.all(np.abs(img.astype(int) - np.array(bgr)) <= TOLERANCE, axis=2)
        for ch, bgr in PAINTS.items()
    }

    grid = [list(r) for r in rows]
    changed = 0
    for r, line in enumerate(grid):
        for c, old in enumerate(line):
            if old == "P":
                continue
            y0, y1 = int(r * tile_px), max(int((r + 1) * tile_px), int(r * tile_px) + 1)
            x0, x1 = int(c * tile_px), max(int((c + 1) * tile_px), int(c * tile_px) + 1)
            area = (y1 - y0) * (x1 - x0)
            best, best_n = None, 0
            for ch, mask in masks.items():
                n = int(mask[y0:y1, x0:x1].sum())
                if n > best_n:
                    best, best_n = ch, n
            if best and best_n / area >= MIN_COVER and best != old:
                grid[r][c] = best
                changed += 1

    header = [l for l in path.read_text(encoding="utf-8").splitlines() if l.startswith(";")]
    path.write_text("\n".join(header + ["".join(r) for r in grid]) + "\n", encoding="utf-8")
    print(f"zmieniono kafelków: {changed}")


if __name__ == "__main__":
    main()
