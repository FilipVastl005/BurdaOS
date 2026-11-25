#!/usr/bin/env bash
# ==============================================================================
# BGNOME Desktop — User Installer & Activator
# Installs BGNOME Shell theme, GTK4/libadwaita CSS, GTK3 theme and 4K wallpaper
# ==============================================================================
set -euo pipefail

if [ -z "${HOME:-}" ] || [ ! -d "${HOME}" ]; then
    echo "Error: HOME environment variable is not set to a valid directory." >&2
    exit 1
fi

PRESET="${1:-amber-glass}"
case "${PRESET}" in
    amber-glass)
        THEME_NAME="BGNOME-Amber-Glass"
        WALLPAPER_FILE="bgnome-amber.svg"
        ;;
    burnished-copper)
        THEME_NAME="BGNOME-Burnished-Copper"
        WALLPAPER_FILE="bgnome-copper.svg"
        ;;
    midnight-gold)
        THEME_NAME="BGNOME-Midnight-Gold"
        WALLPAPER_FILE="bgnome-gold.svg"
        ;;
    *)
        echo "Usage: $0 [amber-glass|burnished-copper|midnight-gold]" >&2
        exit 1
        ;;
esac

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

THEMES_DEST="${HOME}/.local/share/themes/${THEME_NAME}"
LEGACY_THEMES_DEST="${HOME}/.themes/${THEME_NAME}"
GTK4_CONFIG_DEST="${HOME}/.config/gtk-4.0"
WALLPAPER_DEST="${HOME}/.local/share/backgrounds/${WALLPAPER_FILE}"

echo "=========================================================="
echo "  BGNOME Desktop Installer (${THEME_NAME})"
echo "=========================================================="

# 1. Regenerate latest assets & stylesheets from scratch
echo "[1/5] Generating fresh stylesheets and 4K wallpapers..."
python3 -- "${REPO_ROOT}/scripts/generate_wallpaper.py"
python3 -- "${REPO_ROOT}/scripts/generate_theme.py"

# 2. Install to user themes directory
echo "[2/5] Installing theme to ${THEMES_DEST}..."
mkdir -p -- "${HOME}/.local/share/themes" "${HOME}/.themes"
rm -rf -- "${THEMES_DEST}" "${LEGACY_THEMES_DEST}"
cp -a -- "${REPO_ROOT}/theme/${THEME_NAME}" "${THEMES_DEST}"
ln -sfn -- "${THEMES_DEST}" "${LEGACY_THEMES_DEST}"

# 3. Install GTK4 / libadwaita styling to user config
echo "[3/5] Setting up GTK 4.0 / libadwaita styling..."
mkdir -p -- "${GTK4_CONFIG_DEST}"
if [ -f "${GTK4_CONFIG_DEST}/gtk.css" ] && [ ! -L "${GTK4_CONFIG_DEST}/gtk.css" ]; then
    cp -p -- "${GTK4_CONFIG_DEST}/gtk.css" "${GTK4_CONFIG_DEST}/gtk.css.backup.$(date +%s)"
    echo "      (Backed up existing gtk.css)"
fi
install -m 644 -- "${REPO_ROOT}/theme/${THEME_NAME}/gtk-4.0/gtk.css" "${GTK4_CONFIG_DEST}/gtk.css"

# 4. Install 4K Wallpaper
echo "[4/5] Installing 4K BGNOME wallpaper..."
mkdir -p -- "${HOME}/.local/share/backgrounds"
install -m 644 -- "${REPO_ROOT}/assets/wallpapers/${WALLPAPER_FILE}" "${WALLPAPER_DEST}"

# 5. Apply GSettings if running in a GNOME session
echo "[5/5] Applying GSettings (if gsettings is available)..."
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "${THEME_NAME}" || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true

    if gsettings list-schemas | grep -q "^org\.gnome\.shell\.extensions\.user-theme$"; then
        gsettings set org.gnome.shell.extensions.user-theme name "${THEME_NAME}" || true
        echo "      GNOME Shell user-theme set to ${THEME_NAME}"
    else
        echo "      [Note] Install 'gnome-shell-extensions' and enable 'user-theme' for custom Shell theme."
    fi

    WALLPAPER_URI="file://${WALLPAPER_DEST}"
    gsettings set org.gnome.desktop.background picture-uri "${WALLPAPER_URI}" || true
    gsettings set org.gnome.desktop.background picture-uri-dark "${WALLPAPER_URI}" || true
    gsettings set org.gnome.desktop.background picture-options 'zoom' || true
fi

if command -v dconf >/dev/null 2>&1 && command -v gsettings >/dev/null 2>&1; then
    if gsettings list-schemas | grep -q "^org\.gnome\.shell\.extensions\.blur-my-shell$"; then
        dconf load /org/gnome/shell/extensions/blur-my-shell/ < "${REPO_ROOT}/arch/bgnome-blur-my-shell.dconf" || true
        echo "      Applied BGNOME Blur My Shell preset."
    fi
fi

echo ""
echo " BGNOME (${THEME_NAME}) installed successfully!"
echo "• Theme Directory: ${THEMES_DEST}"
echo "• GTK4 Config:     ${GTK4_CONFIG_DEST}/gtk.css"
echo "• Wallpaper:       ${WALLPAPER_DEST}"
echo "=========================================================="
