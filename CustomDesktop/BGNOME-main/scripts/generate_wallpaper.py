#!/usr/bin/env python3
"""
Generates clean Pascal's Triangle minimalist 4K (3840x2160) SVG wallpapers
featuring a white geometric Pascal's Triangle against a clean Apple-style gray background.
Generates:
1. bgnome-pascal-dark.svg (deep space gray background with crisp white / luminous triangle nodes)
2. bgnome-pascal-light.svg (clean Apple light gray background with white node plates and delicate gray numbers)
"""

from __future__ import annotations

import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
WALLPAPER_DIR = ROOT / "assets" / "wallpapers"


def compute_pascal_triangle(rows: int) -> list[list[int]]:
    triangle: list[list[int]] = []
    for r in range(rows):
        row = [1] * (r + 1)
        for c in range(1, r):
            row[c] = triangle[r - 1][c - 1] + triangle[r - 1][c]
        triangle.append(row)
    return triangle


def build_pascal_wallpaper(is_dark: bool) -> str:
    bg_color = "#18181B" if is_dark else "#E5E5EA"
    bg_gradient_start = "#222226" if is_dark else "#F2F2F6"
    bg_gradient_end = "#121214" if is_dark else "#D1D1D6"

    node_fill = "#FFFFFF" if is_dark else "#FFFFFF"
    node_stroke = "rgba(255, 255, 255, 0.40)" if is_dark else "rgba(0, 0, 0, 0.12)"
    text_color = "#0E0E10" if is_dark else "#1D1D1F"
    line_stroke = "rgba(255, 255, 255, 0.22)" if is_dark else "rgba(0, 0, 0, 0.15)"
    glow_color = "rgba(255, 255, 255, 0.18)" if is_dark else "rgba(0, 0, 0, 0.04)"

    rows_count = 8
    triangle = compute_pascal_triangle(rows_count)

    center_x = 1920
    start_y = 620
    row_spacing = 130
    node_spacing = 150
    node_radius = 42

    coords: list[list[tuple[float, float]]] = []
    for r in range(rows_count):
        row_coords = []
        count = r + 1
        width = (count - 1) * node_spacing
        row_start_x = center_x - (width / 2.0)
        y = start_y + (r * row_spacing)
        for c in range(count):
            x = row_start_x + (c * node_spacing)
            row_coords.append((x, y))
        coords.append(row_coords)

    # Render lattice connection lines between parent and child nodes
    lines_svg = []
    for r in range(rows_count - 1):
        for c in range(len(coords[r])):
            x1, y1 = coords[r][c]
            # Left child
            x2_l, y2_l = coords[r + 1][c]
            lines_svg.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2_l:.1f}" y2="{y2_l:.1f}" stroke="{line_stroke}" stroke-width="2"/>')
            # Right child
            x2_r, y2_r = coords[r + 1][c + 1]
            lines_svg.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2_r:.1f}" y2="{y2_r:.1f}" stroke="{line_stroke}" stroke-width="2"/>')

    # Render white circular nodes with Pascal values
    nodes_svg = []
    for r in range(rows_count):
        for c in range(len(coords[r])):
            x, y = coords[r][c]
            val = triangle[r][c]
            font_size = 24 if val < 10 else (21 if val < 100 else 18)

            nodes_svg.append(f'''
    <g transform="translate({x:.1f}, {y:.1f})">
      <circle cx="0" cy="0" r="{node_radius + 4}" fill="{glow_color}"/>
      <circle cx="0" cy="0" r="{node_radius}" fill="{node_fill}" stroke="{node_stroke}" stroke-width="1.8"/>
      <text x="0" y="{font_size * 0.35:.1f}" font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Inter', sans-serif"
            font-size="{font_size}" font-weight="700" text-anchor="middle" fill="{text_color}">{val}</text>
    </g>''')

    lines_str = "\n    ".join(lines_svg)
    nodes_str = "\n".join(nodes_svg)

    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3840 2160" width="3840" height="2160">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="{bg_gradient_start}"/>
      <stop offset="50%" stop-color="{bg_color}"/>
      <stop offset="100%" stop-color="{bg_gradient_end}"/>
    </linearGradient>

    <radialGradient id="subtleAura" cx="50%" cy="50%" r="55%">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity="{'0.06' if is_dark else '0.40'}"/>
      <stop offset="100%" stop-color="{bg_color}" stop-opacity="0"/>
    </radialGradient>
  </defs>

  <!-- Clean Gray Background -->
  <rect width="3840" height="2160" fill="url(#bgGrad)"/>
  <rect width="3840" height="2160" fill="url(#subtleAura)"/>

  <!-- Minimal Pascal's Triangle Lattice -->
  <g>
    {lines_str}
  </g>

  <!-- White Pascal Nodes -->
  {nodes_str}

  <!-- Minimal label footer -->
  <text x="1920" y="1740"
        font-family="-apple-system, BlinkMacSystemFont, 'SF Pro Display', 'SF Pro Text', sans-serif"
        font-size="16" font-weight="600" letter-spacing="6" text-anchor="middle"
        fill="{'rgba(255,255,255,0.30)' if is_dark else 'rgba(0,0,0,0.30)'}">PASCAL'S TRIANGLE · BGNOME</text>
</svg>
"""


def main() -> None:
    WALLPAPER_DIR.mkdir(parents=True, exist_ok=True)
    dark_svg = build_pascal_wallpaper(is_dark=True)
    light_svg = build_pascal_wallpaper(is_dark=False)

    (WALLPAPER_DIR / "bgnome-dark.svg").write_text(dark_svg, encoding="utf-8")
    (WALLPAPER_DIR / "bgnome-light.svg").write_text(light_svg, encoding="utf-8")
    (WALLPAPER_DIR / "bgnome-pascal-dark.svg").write_text(dark_svg, encoding="utf-8")
    (WALLPAPER_DIR / "bgnome-pascal-light.svg").write_text(light_svg, encoding="utf-8")
    print("Generated Pascal's Triangle 4K wallpapers: bgnome-dark.svg, bgnome-light.svg, bgnome-pascal-dark.svg, bgnome-pascal-light.svg")


if __name__ == "__main__":
    main()
