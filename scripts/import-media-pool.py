#!/usr/bin/env python3
"""
Import memes & photos from assets/media-pool/ into BurdaOS wallpapers & user
faces, generate GNOME Settings wallpaper XML, and bind GaSOSLogo.* as default.
"""
from __future__ import annotations

import re
import shutil
import xml.etree.ElementTree as ET
from pathlib import Path

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    media_pool = repo_root / "assets" / "media-pool"
    chroot = repo_root / "config" / "includes.chroot"

    bg_dir = chroot / "usr" / "share" / "backgrounds" / "burdaos"
    faces_dir = chroot / "usr" / "share" / "pixmaps" / "faces"
    xml_dir = chroot / "usr" / "share" / "gnome-background-properties"

    bg_dir.mkdir(parents=True, exist_ok=True)
    faces_dir.mkdir(parents=True, exist_ok=True)
    xml_dir.mkdir(parents=True, exist_ok=True)

    imported = 0
    if media_pool.is_dir():
        for src in sorted(media_pool.iterdir()):
            if src.is_file() and src.suffix.lower() in IMAGE_EXTS:
                shutil.copy2(src, bg_dir / src.name)
                shutil.copy2(src, faces_dir / src.name)
                imported += 1

    # Generate /usr/share/gnome-background-properties/burdaos-wallpapers.xml
    root = ET.Element("wallpapers")
    bg_files = sorted(
        p for p in bg_dir.iterdir()
        if p.is_file() and p.suffix.lower() in IMAGE_EXTS
    )
    for img in bg_files:
        wp = ET.SubElement(root, "wallpaper", deleted="false")
        ET.SubElement(wp, "name").text = img.stem.replace("_", " ").replace("-", " ")
        ET.SubElement(wp, "filename").text = f"/usr/share/backgrounds/burdaos/{img.name}"
        ET.SubElement(wp, "options").text = "zoom"
        ET.SubElement(wp, "pcolor").text = "#141416"
        ET.SubElement(wp, "scolor").text = "#0E0E10"
        ET.SubElement(wp, "shade_type").text = "solid"

    tree = ET.ElementTree(root)
    ET.indent(tree, space="  ")
    xml_path = xml_dir / "burdaos-wallpapers.xml"
    with xml_path.open("wb") as fh:
        fh.write(b'<?xml version="1.0" encoding="UTF-8"?>\n')
        fh.write(b'<!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">\n')
        tree.write(fh, encoding="utf-8", xml_declaration=False)
        fh.write(b"\n")

    # Resolve GaSOSLogo.* (case-insensitive) as default desktop wallpaper
    gasos_logo = next(
        (p for p in bg_files if p.stem.lower() == "gasoslogo"),
        None,
    )
    if gasos_logo is not None:
        uri = f"file:///usr/share/backgrounds/burdaos/{gasos_logo.name}"
        dconf_file = chroot / "etc" / "dconf" / "db" / "local.d" / "00-burdaos-desktop"
        schema_file = chroot / "usr" / "share" / "glib-2.0" / "schemas" / "01_bgnome.gschema.override"

        for cfg_path in (dconf_file, schema_file):
            if cfg_path.is_file():
                txt = cfg_path.read_text(encoding="utf-8")
                txt = re.sub(
                    r"(picture-uri(?:-dark)?\s*=\s*)'[^']*'",
                    rf"\1'{uri}'",
                    txt,
                )
                cfg_path.write_text(txt, encoding="utf-8")
        print(f"Default wallpaper set to {uri}")
    else:
        print("Note: GaSOSLogo.* not found in assets/media-pool/ yet; keeping GaSOSLogo.png path in dconf.")

    print(f"Imported {imported} media-pool image(s); registered {len(bg_files)} wallpaper(s) in {xml_path}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
