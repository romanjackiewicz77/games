"""Zamiana rzutu z pomalowanymi meblami (fiolet #FF00FF) na mapę Slidefire.

Użycie (z folderu slidefire):
    python tools/painted_to_map.py maps/map_02_edit.jpg --px-per-cm 2.4

Ściany to szare, kreskowane wypełnienie rzutu; fioletowe plamy to meble 'F'.
Zapisuje maps/map_02.txt. Tłem w grze jest maps/map_02.jpg (czysty rzut), jeśli istnieje i ma ten sam rozmiar;
w przeciwnym razie powstaje map_02.png z zamalowanymi meblami. Wokół domu dodawana jest ściana, żeby nie wyjść poza mapę.
"""
import argparse
from pathlib import Path

import cv2
import numpy as np

MARGIN_PX = 60
WALL_RATIO = 0.4
FURN_RATIO = 0.4


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--px-per-cm", type=float, required=True)
    ap.add_argument("--tile-cm", type=float, default=12.0)
    args = ap.parse_args()

    src = Path(args.image)
    img = cv2.imread(str(src))
    b, g, r = [img[:, :, i].astype(int) for i in range(3)]
    magenta = ((r > 200) & (b > 200) & (g < 90)).astype(np.uint8)
    magenta = cv2.morphologyEx(magenta, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))

    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    sat = img.max(axis=2).astype(int) - img.min(axis=2).astype(int)
    ink = ((gray < 235) & (sat < 40) & (magenta == 0)).astype(np.uint8)
    # szary fill ścian + kreskowanie; cienkie linie (drzwi, wymiary) odpada otwarcie
    fill = cv2.morphologyEx(ink, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9)))
    walls = cv2.morphologyEx(fill, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))

    ys, xs = np.nonzero(walls | magenta)
    x0, y0 = max(xs.min() - MARGIN_PX, 0), max(ys.min() - MARGIN_PX, 0)
    x1, y1 = min(xs.max() + MARGIN_PX, img.shape[1]), min(ys.max() + MARGIN_PX, img.shape[0])
    w, h = x1 - x0, y1 - y0
    walls, magenta = walls[y0:y1, x0:x1], magenta[y0:y1, x0:x1]

    tile_px = args.tile_cm * args.px_per_cm
    cols, rows = int(w / tile_px), int(h / tile_px)
    small = lambda m: cv2.resize(m.astype(np.float32), (cols, rows), interpolation=cv2.INTER_AREA)
    wall_t, furn_t = small(walls) >= WALL_RATIO, small(magenta) >= FURN_RATIO
    grid = np.full((rows, cols), ".", dtype="<U1")
    grid[furn_t] = "F"
    grid[wall_t] = "#"
    grid[0, :] = grid[-1, :] = grid[:, 0] = grid[:, -1] = "#"

    solid = np.isin(grid, ["#", "F"]).astype(np.uint8)
    dist = cv2.distanceTransform(1 - solid, cv2.DIST_L2, 5)
    sr, sc = np.unravel_index(dist.argmax(), dist.shape)
    grid[sr, sc] = "P"

    base = src.with_name(src.stem.replace("_edit", "") + ".jpg")
    if base.exists() and cv2.imread(str(base)).shape == img.shape:
        out_img = base
    else:
        out_img = base.with_suffix(".png")
        clean = img.copy()
        clean[magenta_full(img)] = 255
        cv2.imwrite(str(out_img), clean)

    out = src.with_name(src.stem.replace("_edit", "") + ".txt")
    header = [
        "; map_02: wygenerowano z rzutu z pomalowanymi meblami",
        f"; image={out_img.name}",
        f"; roi={x0},{y0},{w},{h}",
        f"; px_per_cm={args.px_per_cm}",
        f"; tile_cm={args.tile_cm}",
    ]
    out.write_text("\n".join(header + ["".join(row) for row in grid]) + "\n", encoding="utf-8")
    print(f"{out}: {cols}x{rows}, ściany={int(wall_t.sum())}, meble={int(furn_t.sum())}, start=({sr},{sc})")


def magenta_full(img: np.ndarray) -> np.ndarray:
    b, g, r = [img[:, :, i].astype(int) for i in range(3)]
    m = ((r > 200) & (b > 200) & (g < 120)).astype(np.uint8)
    return cv2.dilate(m, np.ones((5, 5), np.uint8)) > 0


if __name__ == "__main__":
    main()
