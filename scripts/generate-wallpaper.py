#!/usr/bin/env python3
"""Generate BurdaOS dark grid wallpaper (1920x1080)."""
import os
import shutil
import subprocess
import sys
from pathlib import Path

WIDTH = 1920
HEIGHT = 1080
WATERMARK = "BURDAOS \u2014 FOR EDUCATIONAL USE (APPARENTLY)"


def generate_svg(svg_path: Path) -> None:
    lines = []
    # Subtle 40px minor grid, 160px major grid
    for x in range(0, WIDTH + 1, 40):
        stroke = "#25303f" if x % 160 == 0 else "#1f2835"
        width = "1.2" if x % 160 == 0 else "0.7"
        lines.append(f'<line x1="{x}" y1="0" x2="{x}" y2="{HEIGHT}" stroke="{stroke}" stroke-width="{width}" />')
    for y in range(0, HEIGHT + 1, 40):
        stroke = "#25303f" if y % 160 == 0 else "#1f2835"
        width = "1.2" if y % 160 == 0 else "0.7"
        lines.append(f'<line x1="0" y1="{y}" x2="{WIDTH}" y2="{y}" stroke="{stroke}" stroke-width="{width}" />')

    # Subtle registration crosshairs at major intersections
    crosshairs = []
    for x in range(160, WIDTH, 320):
        for y in range(160, HEIGHT, 320):
            crosshairs.append(
                f'<path d="M {x-6} {y} L {x+6} {y} M {x} {y-6} L {x} {y+6}" '
                f'stroke="#334357" stroke-width="1" />'
            )

    svg = f'''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">
  <defs>
    <radialGradient id="slateGlow" cx="50%" cy="45%" r="65%">
      <stop offset="0%" stop-color="#1e2733" />
      <stop offset="100%" stop-color="#131921" />
    </radialGradient>
  </defs>
  <rect width="{WIDTH}" height="{HEIGHT}" fill="url(#slateGlow)" />
  <g>{''.join(lines)}</g>
  <g>{''.join(crosshairs)}</g>
  <!-- Top-left dry micro-header -->
  <text x="36" y="42" fill="#46576c" font-family="DejaVu Sans Mono, monospace" font-size="12" letter-spacing="2">BURDAOS // DO TRY NOT TO BREAK THIS ONE</text>
  <!-- Bottom-right watermark -->
  <text x="{WIDTH - 36}" y="{HEIGHT - 32}" text-anchor="end" fill="#6b7b8f" fill-opacity="0.72" font-family="DejaVu Sans, sans-serif" font-size="15" font-weight="bold" letter-spacing="1.8">{WATERMARK}</text>
</svg>
'''
    svg_path.write_text(svg, encoding="utf-8")


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else (
        repo_root / "config/includes.chroot/usr/share/backgrounds/burdaos"
    )
    out_dir.mkdir(parents=True, exist_ok=True)
    svg_path = out_dir / "burdaos-grid.svg"
    png_path = out_dir / "burdaos-grid.png"

    generate_svg(svg_path)

    # Prefer ImageMagick if available to rasterize cleanly to PNG for GNOME/GDM
    magick = shutil.which("magick") or shutil.which("convert")
    if magick:
        cmd = [magick, "-background", "none", str(svg_path), str(png_path)]
        subprocess.run(cmd, check=True)
        print(f"Generated wallpaper PNG via {os.path.basename(magick)}: {png_path}")
        return 0

    # Fallback to Python Pillow if ImageMagick is absent
    try:
        from PIL import Image, ImageDraw, ImageFont
        img = Image.new("RGB", (WIDTH, HEIGHT), "#171e28")
        draw = ImageDraw.Draw(img)
        for x in range(0, WIDTH + 1, 40):
            color = "#25303f" if x % 160 == 0 else "#1e2734"
            draw.line([(x, 0), (x, HEIGHT)], fill=color, width=1)
        for y in range(0, HEIGHT + 1, 40):
            color = "#25303f" if y % 160 == 0 else "#1e2734"
            draw.line([(0, y), (WIDTH, y)], fill=color, width=1)
        font = ImageFont.load_default()
        draw.text((WIDTH - 460, HEIGHT - 42), WATERMARK, fill="#6b7b8f", font=font)
        img.save(png_path, "PNG")
        print(f"Generated wallpaper PNG via Pillow: {png_path}")
        return 0
    except ImportError:
        print(f"Generated SVG wallpaper only (no magick/Pillow found): {svg_path}")
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
