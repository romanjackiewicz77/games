"""Zamiana rzutu technicznego (obraz) na szkic mapy Slidefire.

Użycie (z folderu slidefire):
    python tools/plan_to_map.py maps/map_01.jpg --out maps/map_01.txt

Wynik: plik tekstowy z nagłówkiem (linie zaczynające się od ';') i siatką:
    '#' ściana, '.' podłoga, 'P' start gracza.
Szkic należy poprawić ręcznie (np. usunąć meble wykryte jako ściany).
Podgląd z siatką: python tools/map_preview.py maps/map_01.txt
"""
import argparse
from pathlib import Path

import cv2
import numpy as np

MIN_RUN_PX = 80  # minimalna długość prostego odcinka uznawanego za ścianę
MIN_THICK_PX = 9  # cieńsze linie (wymiary, meble, tekst) są odrzucane
HATCH_FILL_PX = 9  # wypełnianie kreskowania ścian
FRAME_MARGIN_PX = 60  # pomijana ramka arkusza
INK_THRESHOLD = 238  # jasne kreskowanie ścian też liczy się jako tusz
WALL_FILL_RATIO = 0.4  # jaką część kafelka musi zajmować ściana


def wall_mask(gray: np.ndarray) -> np.ndarray:
    """Maska ścian: wypełnia kreskowanie, zostawia grube, proste odcinki."""
    ink = (gray < INK_THRESHOLD).astype(np.uint8) * 255
    ink[:FRAME_MARGIN_PX] = 0
    ink[-FRAME_MARGIN_PX:] = 0
    ink[:, :FRAME_MARGIN_PX] = 0
    ink[:, -FRAME_MARGIN_PX:] = 0
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (HATCH_FILL_PX, HATCH_FILL_PX))
    filled = cv2.morphologyEx(ink, cv2.MORPH_CLOSE, kernel)
    horizontal = cv2.morphologyEx(
        filled, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (MIN_RUN_PX, MIN_THICK_PX))
    )
    vertical = cv2.morphologyEx(
        filled, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (MIN_THICK_PX, MIN_RUN_PX))
    )
    return cv2.bitwise_or(horizontal, vertical)


def to_grid(mask: np.ndarray, roi: tuple[int, int, int, int], tile_px: float) -> np.ndarray:
    """Maska ścian -> siatka kafelków (True = ściana)."""
    x, y, w, h = roi
    crop = (mask[y : y + h, x : x + w] > 0).astype(np.float32)
    cols = int(round(w / tile_px))
    rows = int(round(h / tile_px))
    # INTER_AREA daje udział ściany w kafelku.
    ratio = cv2.resize(crop, (cols, rows), interpolation=cv2.INTER_AREA)
    grid = ratio >= WALL_FILL_RATIO
    grid[0, :] = grid[-1, :] = True
    grid[:, 0] = grid[:, -1] = True
    return grid


def parse_ints(text: str, count: int) -> tuple[int, ...]:
    values = tuple(int(v) for v in text.split(","))
    if len(values) != count:
        raise argparse.ArgumentTypeError(f"oczekiwano {count} liczb rozdzielonych przecinkami")
    return values


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image")
    ap.add_argument("--out", required=True)
    ap.add_argument("--roi", default="561,434,2008,1369", help="x,y,w,h obszaru mapy w pikselach obrazu")
    ap.add_argument("--px-per-cm", type=float, default=1.015, help="skala rzutu (piksele na cm)")
    ap.add_argument("--tile-cm", type=float, default=12.0)
    ap.add_argument("--start", default="1530,1055", help="x,y startu gracza w pikselach obrazu")
    args = ap.parse_args()

    gray = cv2.imread(args.image, cv2.IMREAD_GRAYSCALE)
    if gray is None:
        raise SystemExit(f"Nie można wczytać obrazu: {args.image}")
    roi = parse_ints(args.roi, 4)
    tile_px = args.tile_cm * args.px_per_cm
    grid = to_grid(wall_mask(gray), roi, tile_px)

    sx, sy = parse_ints(args.start, 2)
    col = int(round((sx - roi[0]) / tile_px))
    row = int(round((sy - roi[1]) / tile_px))
    rows = [["#" if cell else "." for cell in line] for line in grid]
    rows[row][col] = "P"

    header = [
        f"; image={Path(args.image).name}",
        f"; roi={args.roi}",
        f"; px_per_cm={args.px_per_cm}",
        f"; tile_cm={args.tile_cm}",
    ]
    Path(args.out).write_text("\n".join(header + ["".join(r) for r in rows]) + "\n", encoding="utf-8")
    print(f"zapisano {args.out}: {grid.shape[1]}x{grid.shape[0]} kafelków")


if __name__ == "__main__":
    main()
