#!/usr/bin/env python3
"""
Builds standard Debian .deb binary package containing clean Apple-style
BGNOME-Dark and BGNOME-Light themes.
"""

from __future__ import annotations

import io
import os
import subprocess
import sys
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DIST_DIR = ROOT / "dist"
THEME_DIR = ROOT / "theme"
ASSETS_DIR = ROOT / "assets"
DEBIAN_DIR = ROOT / "debian"

PACKAGE_NAME = "bgnome-desktop-theme"
VERSION = "1.1.0-1"
ARCH = "all"
DEB_FILENAME = f"{PACKAGE_NAME}_{VERSION}_{ARCH}.deb"


def make_tarinfo(name: str, size: int, mode: int, mtime: int = 1700000000) -> tarfile.TarInfo:
    ti = tarfile.TarInfo(name=name)
    ti.size = size
    ti.mode = mode
    ti.mtime = mtime
    ti.uid = 0
    ti.gid = 0
    ti.uname = "root"
    ti.gname = "root"
    return ti


def make_dir_tarinfo(name: str, mode: int = 0o755, mtime: int = 1700000000) -> tarfile.TarInfo:
    ti = tarfile.TarInfo(name=name.rstrip("/") + "/")
    ti.type = tarfile.DIRTYPE
    ti.mode = mode
    ti.mtime = mtime
    ti.uid = 0
    ti.gid = 0
    ti.uname = "root"
    ti.gname = "root"
    return ti


def build_control_tar(installed_size_kb: int) -> bytes:
    control_content = f"""Package: {PACKAGE_NAME}
Version: {VERSION}
Architecture: {ARCH}
Maintainer: BGNOME Desktop Team <team@bgnome.org>
Installed-Size: {installed_size_kb}
Depends: gnome-shell (>= 45), gnome-shell-extensions, gsettings-desktop-schemas, dconf-gsettings-backend | dconf-cli, fonts-cantarell
Recommends: gnome-shell-extension-blur-my-shell
Suggests: gnome-shell-extension-dash-to-dock, gdm3
Section: gnome
Priority: optional
Homepage: https://github.com/bgnome/bgnome-desktop
Description: BGNOME Desktop - Clean Apple-inspired Theme for Debian
 Minimalist GNOME Shell & GTK4 themes featuring system top bar,
 frosted glass dock, single close button, Light/Dark modes, and
 clean vector wallpapers for Debian-based distributions.
""".encode("utf-8")

    postinst_src = (DEBIAN_DIR / "postinst").read_bytes()
    postrm_src = (DEBIAN_DIR / "postrm").read_bytes()

    out = io.BytesIO()
    with tarfile.open(fileobj=out, mode="w:gz", format=tarfile.PAX_FORMAT) as tar:
        tar.addfile(make_dir_tarinfo("./"))
        tar.addfile(make_tarinfo("./control", len(control_content), 0o644), io.BytesIO(control_content))
        tar.addfile(make_tarinfo("./postinst", len(postinst_src), 0o755), io.BytesIO(postinst_src))
        tar.addfile(make_tarinfo("./postrm", len(postrm_src), 0o755), io.BytesIO(postrm_src))

    return out.getvalue()


def build_data_tar() -> tuple[bytes, int]:
    out = io.BytesIO()
    total_uncompressed_bytes = 0
    added_dirs: set[str] = set()

    def ensure_dir(tar: tarfile.TarFile, dpath: str):
        parts = dpath.strip("/").split("/")
        accum = "."
        for p in parts:
            accum += "/" + p
            if accum not in added_dirs:
                tar.addfile(make_dir_tarinfo(accum))
                added_dirs.add(accum)

    with tarfile.open(fileobj=out, mode="w:gz", format=tarfile.PAX_FORMAT) as tar:
        ensure_dir(tar, "./usr/share/themes")
        ensure_dir(tar, "./usr/share/backgrounds/bgnome")
        ensure_dir(tar, "./usr/share/glib-2.0/schemas")
        ensure_dir(tar, "./usr/share/bgnome")
        ensure_dir(tar, "./usr/share/wayland-sessions")
        ensure_dir(tar, "./etc/skel/.config/gtk-4.0")

        # 1. Themes (BGNOME-Dark & BGNOME-Light)
        for tname in ["BGNOME-Dark", "BGNOME-Light"]:
            src_t = THEME_DIR / tname
            for root, dirs, files in os.walk(src_t):
                rel_dir = os.path.relpath(root, THEME_DIR)
                dest_dir = f"./usr/share/themes/{rel_dir}"
                ensure_dir(tar, dest_dir)
                for f in sorted(files):
                    fpath = Path(root) / f
                    fbytes = fpath.read_bytes()
                    dest_file = f"{dest_dir}/{f}"
                    tar.addfile(make_tarinfo(dest_file, len(fbytes), 0o644), io.BytesIO(fbytes))
                    total_uncompressed_bytes += len(fbytes)

        # 2. Wallpapers (bgnome-dark.svg, bgnome-light.svg)
        for wp in sorted((ASSETS_DIR / "wallpapers").glob("*.svg")):
            wp_bytes = wp.read_bytes()
            dest_file = f"./usr/share/backgrounds/bgnome/{wp.name}"
            tar.addfile(make_tarinfo(dest_file, len(wp_bytes), 0o644), io.BytesIO(wp_bytes))
            total_uncompressed_bytes += len(wp_bytes)

        # 3. GSettings schema override
        g_bytes = (DEBIAN_DIR / "01_bgnome.gschema.override").read_bytes()
        dest_file = "./usr/share/glib-2.0/schemas/01_bgnome.gschema.override"
        tar.addfile(make_tarinfo(dest_file, len(g_bytes), 0o644), io.BytesIO(g_bytes))
        total_uncompressed_bytes += len(g_bytes)

        # 4. /etc/skel/.config/gtk-4.0/gtk.css (default to dark)
        gtk_bytes = (THEME_DIR / "BGNOME-Dark" / "gtk-4.0" / "gtk.css").read_bytes()
        dest_file = "./etc/skel/.config/gtk-4.0/gtk.css"
        tar.addfile(make_tarinfo(dest_file, len(gtk_bytes), 0o644), io.BytesIO(gtk_bytes))
        total_uncompressed_bytes += len(gtk_bytes)

        # 5. Blur My Shell preset
        blur_bytes = (DEBIAN_DIR / "bgnome-blur-my-shell.dconf").read_bytes()
        dest_file = "./usr/share/bgnome/bgnome-blur-my-shell.dconf"
        tar.addfile(make_tarinfo(dest_file, len(blur_bytes), 0o644), io.BytesIO(blur_bytes))
        total_uncompressed_bytes += len(blur_bytes)

        # 6. Wayland session
        way_bytes = (DEBIAN_DIR / "bgnome-wayland.desktop").read_bytes()
        dest_file = "./usr/share/wayland-sessions/bgnome-wayland.desktop"
        tar.addfile(make_tarinfo(dest_file, len(way_bytes), 0o644), io.BytesIO(way_bytes))
        total_uncompressed_bytes += len(way_bytes)

    return out.getvalue(), total_uncompressed_bytes // 1024


def write_ar_entry(f, filename: str, content: bytes, mtime: int = 1700000000, mode: int = 0o100644) -> None:
    header = (
        f"{filename:<16}"
        f"{mtime:<12}"
        f"{'0':<6}"
        f"{'0':<6}"
        f"{oct(mode)[2:]:>8}"
        f"{len(content):<10}"
        "`\n"
    ).encode("ascii")
    f.write(header)
    f.write(content)
    if len(content) % 2 != 0:
        f.write(b"\n")


def build_deb() -> Path:
    subprocess.run([sys.executable, str(ROOT / "scripts" / "generate_wallpaper.py")], check=True)
    subprocess.run([sys.executable, str(ROOT / "scripts" / "generate_theme.py")], check=True)

    DIST_DIR.mkdir(parents=True, exist_ok=True)
    out_deb = DIST_DIR / DEB_FILENAME

    data_bytes, installed_size_kb = build_data_tar()
    control_bytes = build_control_tar(installed_size_kb)

    with open(out_deb, "wb") as f:
        f.write(b"!<arch>\n")
        write_ar_entry(f, "debian-binary", b"2.0\n")
        write_ar_entry(f, "control.tar.gz", control_bytes)
        write_ar_entry(f, "data.tar.gz", data_bytes)

    print(f"Successfully generated Debian package: {out_deb} ({out_deb.stat().st_size} bytes)")
    return out_deb


if __name__ == "__main__":
    build_deb()
