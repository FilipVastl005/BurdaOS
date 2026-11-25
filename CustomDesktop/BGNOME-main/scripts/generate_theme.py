#!/usr/bin/env python3
"""
Generates clean Apple-inspired BGNOME themes (BGNOME-Dark & BGNOME-Light).
Features:
- Clean system top bar (full width, native GNOME system feel)
- Frosted glass dock at the bottom
- Single close button on windows (apple-like close: layout)
- Distinct light and dark mode colorings
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PALETTE_PATH = ROOT / "tokens" / "palette.json"
THEME_OUT_ROOT = ROOT / "theme"


def render_index_theme(theme_name: str, display_name: str, description: str) -> str:
    return f"""[Desktop Entry]
Type=X-GNOME-Metatheme
Name={display_name}
Comment={description}
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme={theme_name}
MetacityTheme={theme_name}
IconTheme=Adwaita
CursorTheme=Adwaita
ButtonLayout=close:
"""


def render_svg_assets(is_dark: bool, p: dict[str, str]) -> dict[str, str]:
    # Apple-like close button: clean coral-red dot with subtle inner shadow
    close_window = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
  <circle cx="7" cy="7" r="6" fill="#FF5F56" stroke="rgba(0, 0, 0, 0.15)" stroke-width="0.8"/>
</svg>
"""

    close_window_hover = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
  <circle cx="7" cy="7" r="6" fill="#FF5F56" stroke="rgba(0, 0, 0, 0.20)" stroke-width="0.8"/>
  <path d="M4.5 4.5 L9.5 9.5 M9.5 4.5 L4.5 9.5" stroke="#4C0002" stroke-width="1.2" stroke-linecap="round"/>
</svg>
"""

    accent = p["accentPrimary"]
    toggle_on = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="46" height="26" viewBox="0 0 46 26">
  <rect x="1" y="1" width="44" height="24" rx="12" fill="{accent}"/>
  <circle cx="33" cy="13" r="10" fill="#FFFFFF" filter="drop-shadow(0 2px 4px rgba(0,0,0,0.2))"/>
</svg>
"""

    toggle_off_color = "#39393D" if is_dark else "#E9E9EB"
    toggle_off_knob = "#FFFFFF"
    toggle_off = f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="46" height="26" viewBox="0 0 46 26">
  <rect x="1" y="1" width="44" height="24" rx="12" fill="{toggle_off_color}"/>
  <circle cx="13" cy="13" r="10" fill="{toggle_off_knob}" filter="drop-shadow(0 2px 4px rgba(0,0,0,0.15))"/>
</svg>
"""

    return {
        "close-window.svg": close_window,
        "close-window-hover.svg": close_window_hover,
        "toggle-on.svg": toggle_on,
        "toggle-off.svg": toggle_off,
    }


def render_gnome_shell_css(p: dict[str, str], g: dict[str, int], typo: dict[str, str], is_dark: bool) -> str:
    dock_shadow = "0 16px 38px rgba(0, 0, 0, 0.40)" if is_dark else "0 12px 30px rgba(0, 0, 0, 0.12)"
    popover_shadow = "0 20px 48px rgba(0, 0, 0, 0.45)" if is_dark else "0 16px 36px rgba(0, 0, 0, 0.12)"

    return f"""/* ==========================================================================
 * BGNOME — Clean Apple-inspired GNOME Shell Theme
 * System Top Bar + Frosted Glass Dock + Clean Light/Dark styling
 * ========================================================================== */

stage {{
  font-family: {typo['sans']};
  font-size: 10pt;
  color: {p['textPrimary']};
}}

/* --- Native System Top Bar (#panel) -------------------------------------- */
#panel {{
  background-color: {p['glassPanel']};
  border-bottom: 1px solid {p['borderSubtle']};
  margin: 0;
  padding: 0 10px;
  height: 36px;
  color: {p['textPrimary']};
  font-weight: 500;
  font-size: 9.5pt;
  box-shadow: none;
}}

#panel.unlock-screen,
#panel.login-screen,
#panel:overview {{
  background-color: {p['glassPanel']};
  border-bottom: 1px solid {p['borderSubtle']};
}}

#panel .panel-button {{
  -natural-hpadding: 10px;
  -minimum-hpadding: 6px;
  margin: 3px 1px;
  padding: 0 8px;
  border-radius: 8px;
  color: {p['textPrimary']};
  transition-duration: 120ms;
}}

#panel .panel-button:hover {{
  background-color: {p['glassHover']};
  color: {p['textPrimary']};
}}

#panel .panel-button:active,
#panel .panel-button:checked,
#panel .panel-button:focus {{
  background-color: {p['glassActive']};
  color: {p['accentPrimary']};
}}

#panel .panel-button StIcon {{
  icon-size: 15px;
}}

#panel .panel-button.clock-display {{
  font-weight: 600;
  letter-spacing: -0.1px;
}}

#panel #panelActivities .workspace-dot {{
  background-color: {p['textSecondary']};
  opacity: 0.4;
  border-radius: 999px;
  width: 6px;
  height: 6px;
  margin: 0 3px;
}}

#panel #panelActivities .workspace-dot.active {{
  opacity: 1;
  background-color: {p['accentPrimary']};
  width: 16px;
}}

/* --- Clean Frosted Glass Dock / Dash (#dash) ----------------------------- */
#dash {{
  margin: 8px 16px 14px 16px;
  padding: 0;
}}

#dash .dash-background {{
  background-color: {p['glassDock']};
  border: 1px solid {p['borderGlass']};
  border-top-color: {p['borderRim']};
  border-radius: {g['dockRadius']}px;
  padding: 6px 10px;
  box-shadow: {dock_shadow};
}}

#dash .dash-item-container .app-well-app,
#dash .dash-item-container .show-apps {{
  margin: 0 2px;
}}

#dash .app-well-app .overview-icon,
#dash .show-apps .overview-icon {{
  border-radius: 14px;
  padding: 6px;
  transition-duration: 140ms;
}}

#dash .app-well-app:hover .overview-icon,
#dash .show-apps:hover .overview-icon {{
  background-color: {p['glassHover']};
  transform: translateY(-2px);
}}

#dash .app-well-app:active .overview-icon {{
  background-color: {p['glassActive']};
}}

#dash .app-well-app-running-dot {{
  background-color: {p['textPrimary']};
  opacity: 0.85;
  width: 5px;
  height: 5px;
  border-radius: 999px;
  margin-bottom: 2px;
}}

.dash-label {{
  background-color: {p['glassPopover']};
  border: 1px solid {p['borderGlass']};
  border-radius: 8px;
  padding: 4px 10px;
  color: {p['textPrimary']};
  font-weight: 500;
  font-size: 9pt;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}}

/* --- Clean Popovers & Quick Settings ------------------------------------- */
.popup-menu-boxpointer {{
  -arrow-border-radius: {g['quickSettingsRadius']}px;
  -arrow-background-color: transparent;
  -arrow-border-width: 0px;
  -arrow-base: 0px;
  -arrow-rise: 0px;
  margin: 6px 8px;
}}

.popup-menu-content {{
  padding: 12px;
  background-color: {p['glassPopover']};
  border: 1px solid {p['borderGlass']};
  border-top-color: {p['borderRim']};
  border-radius: {g['quickSettingsRadius']}px;
  box-shadow: {popover_shadow};
}}

.popup-menu-item {{
  padding: 7px 12px;
  border-radius: 8px;
  margin: 1px 0;
  color: {p['textPrimary']};
}}

.popup-menu-item:hover,
.popup-menu-item:focus {{
  background-color: {p['accentPrimary']};
  color: #FFFFFF;
}}

.quick-settings {{
  padding: 14px;
  border-radius: {g['quickSettingsRadius']}px;
  background-color: {p['glassPopover']};
  border: 1px solid {p['borderGlass']};
  border-top-color: {p['borderRim']};
  box-shadow: {popover_shadow};
}}

.quick-toggle,
.quick-menu-toggle {{
  border-radius: {g['quickToggleRadius']}px;
  min-height: 44px;
  background-color: {p['glassCard']};
  border: 1px solid {p['borderSubtle']};
  color: {p['textPrimary']};
}}

.quick-toggle:hover {{
  background-color: {p['glassHover']};
}}

.quick-toggle:checked,
.quick-menu-toggle .quick-toggle:checked {{
  background-color: {p['accentPrimary']};
  color: #FFFFFF;
  border-color: transparent;
}}

.quick-toggle:checked .quick-toggle-subtitle {{
  color: rgba(255, 255, 255, 0.75);
}}

.slider {{
  height: 18px;
  -barlevel-height: 6px;
  -barlevel-background-color: rgba(128, 128, 128, 0.25);
  -barlevel-active-background-color: {p['accentPrimary']};
  -slider-handle-radius: 8px;
  color: #FFFFFF;
}}

/* --- Window Controls (Clean Apple-like Close Only) ----------------------- */
.window-close {{
  background-image: url("assets/close-window.svg");
  background-size: 14px;
  width: 14px;
  height: 14px;
}}

.window-close:hover {{
  background-image: url("assets/close-window-hover.svg");
}}

.toggle-switch {{
  width: 46px;
  height: 26px;
  background-size: contain;
  background-image: url("assets/toggle-off.svg");
}}

.toggle-switch:checked {{
  background-image: url("assets/toggle-on.svg");
}}
"""


def render_gtk4_css(p: dict[str, str], g: dict[str, int], is_dark: bool) -> str:
    window_shadow = "0 18px 46px rgba(0, 0, 0, 0.42), 0 0 0 1px " + p["borderGlass"] if is_dark else "0 14px 34px rgba(0, 0, 0, 0.12), 0 0 0 1px " + p["borderGlass"]

    return f"""/* ==========================================================================
 * BGNOME — Clean GTK4 / libadwaita Theme
 * Single close button on left, Apple-like minimalism
 * ========================================================================== */

@define-color window_bg_color {p['bgBase']};
@define-color window_fg_color {p['textPrimary']};

@define-color view_bg_color {p['bgSurface']};
@define-color view_fg_color {p['textPrimary']};

@define-color headerbar_bg_color {p['glassPanel']};
@define-color headerbar_fg_color {p['textPrimary']};
@define-color headerbar_border_color {p['borderSubtle']};
@define-color headerbar_backdrop_color {p['bgBase']};

@define-color sidebar_bg_color {p['bgBase']};
@define-color sidebar_fg_color {p['textPrimary']};

@define-color card_bg_color {p['bgCard']};
@define-color card_fg_color {p['textPrimary']};

@define-color popover_bg_color {p['glassPopover']};
@define-color popover_fg_color {p['textPrimary']};

@define-color accent_bg_color {p['accentPrimary']};
@define-color accent_fg_color #FFFFFF;
@define-color accent_color {p['accentPrimary']};

@define-color destructive_bg_color {p['destructive']};
@define-color destructive_fg_color #FFFFFF;

@define-color success_bg_color {p['success']};
@define-color success_fg_color #FFFFFF;

@define-color warning_bg_color {p['warning']};
@define-color warning_fg_color #FFFFFF;

/* --- Window & Clean Headerbar -------------------------------------------- */
window.background {{
  background-color: {p['bgBase']};
  color: {p['textPrimary']};
}}

window.csd {{
  border-radius: {g['windowRadius']}px;
  box-shadow: {window_shadow};
}}

headerbar {{
  background-color: {p['glassPanel']};
  border-bottom: 1px solid {p['borderSubtle']};
  min-height: 40px;
  padding: 0 12px;
}}

/* Hide maximize & minimize buttons completely */
headerbar windowcontrols > button.maximize,
headerbar windowcontrols > button.minimize {{
  opacity: 0;
  min-width: 0;
  min-height: 0;
  padding: 0;
  margin: 0;
  border: none;
}}

/* Clean Apple-style close button */
headerbar windowcontrols > button.close {{
  min-width: 13px;
  min-height: 13px;
  border-radius: 999px;
  background-color: #FF5F56;
  border: 1px solid rgba(0, 0, 0, 0.15);
  color: transparent;
  padding: 0;
  margin: 0 4px;
  transition: all 120ms ease;
}}

headerbar windowcontrols > button.close:hover {{
  background-color: #FF5F56;
  filter: brightness(1.1);
  color: #4C0002;
}}

/* --- Clean Cards, Sidebars & Buttons ------------------------------------- */
.navigation-sidebar {{
  background-color: {p['bgBase']};
  border-right: 1px solid {p['borderSubtle']};
}}

.navigation-sidebar row {{
  border-radius: 8px;
  margin: 1px 6px;
  padding: 6px 10px;
}}

.navigation-sidebar row:selected {{
  background-color: {p['accentPrimary']};
  color: #FFFFFF;
}}

.card,
list.boxed-list {{
  background-color: {p['bgCard']};
  border: 1px solid {p['borderSubtle']};
  border-radius: {g['cardRadius']}px;
}}

button {{
  border-radius: {g['buttonRadius']}px;
  background-color: {p['glassCard']};
  border: 1px solid {p['borderSubtle']};
  color: {p['textPrimary']};
  padding: 5px 12px;
  font-weight: 500;
  transition: all 120ms ease;
}}

button:hover {{
  background-color: {p['glassHover']};
}}

button.suggested-action {{
  background-color: {p['accentPrimary']};
  color: #FFFFFF;
  border: none;
}}

button.suggested-action:hover {{
  filter: brightness(1.08);
}}

switch {{
  background-color: rgba(128, 128, 128, 0.28);
  border-radius: 999px;
  min-width: 44px;
  min-height: 24px;
  border: none;
}}

switch:checked {{
  background-color: {p['accentPrimary']};
}}

switch > slider {{
  background-color: #FFFFFF;
  border-radius: 999px;
  min-width: 20px;
  min-height: 20px;
  margin: 2px;
}}
"""


def render_gtk3_css(p: dict[str, str], g: dict[str, int]) -> str:
    return f"""/* ==========================================================================
 * BGNOME — GTK3 Theme
 * ========================================================================== */

@define-color theme_bg_color {p['bgBase']};
@define-color theme_fg_color {p['textPrimary']};
@define-color theme_base_color {p['bgSurface']};
@define-color theme_text_color {p['textPrimary']};
@define-color theme_selected_bg_color {p['accentPrimary']};
@define-color theme_selected_fg_color #FFFFFF;
@define-color borders {p['borderSubtle']};

window,
.background {{
  background-color: {p['bgBase']};
  color: {p['textPrimary']};
}}

headerbar {{
  background-color: {p['glassPanel']};
  border-bottom: 1px solid {p['borderSubtle']};
  min-height: 38px;
}}

headerbar button.titlebutton.maximize,
headerbar button.titlebutton.minimize {{
  display: none;
}}

headerbar button.titlebutton.close {{
  min-width: 13px;
  min-height: 13px;
  border-radius: 999px;
  background-color: #FF5F56;
  border: 1px solid rgba(0, 0, 0, 0.15);
  color: transparent;
  padding: 0;
}}

button {{
  border-radius: {g['buttonRadius']}px;
  background-color: {p['glassCard']};
  border: 1px solid {p['borderSubtle']};
  color: {p['textPrimary']};
}}

button.suggested-action {{
  background-color: {p['accentPrimary']};
  color: #FFFFFF;
}}
"""


def build_mode_theme(mode_id: str, mode_data: dict, geometry: dict, typography: dict) -> Path:
    theme_name = mode_data["themeName"]
    theme_dir = THEME_OUT_ROOT / theme_name
    shell_dir = theme_dir / "gnome-shell"
    assets_dir = shell_dir / "assets"
    gtk4_dir = theme_dir / "gtk-4.0"
    gtk3_dir = theme_dir / "gtk-3.0"

    for d in (assets_dir, gtk4_dir, gtk3_dir):
        d.mkdir(parents=True, exist_ok=True)

    is_dark = (mode_id == "dark")

    (theme_dir / "index.theme").write_text(
        render_index_theme(theme_name, mode_data["label"], f"BGNOME {mode_data['label']} clean desktop theme"),
        encoding="utf-8",
    )
    (shell_dir / "gnome-shell.css").write_text(
        render_gnome_shell_css(mode_data, geometry, typography, is_dark),
        encoding="utf-8",
    )
    for filename, svg in render_svg_assets(is_dark, mode_data).items():
        (assets_dir / filename).write_text(svg, encoding="utf-8")

    (gtk4_dir / "gtk.css").write_text(render_gtk4_css(mode_data, geometry, is_dark), encoding="utf-8")
    (gtk3_dir / "gtk.css").write_text(render_gtk3_css(mode_data, geometry), encoding="utf-8")
    return theme_dir


def main() -> None:
    data = json.loads(PALETTE_PATH.read_text(encoding="utf-8"))
    geometry = data["geometry"]
    typography = data["typography"]

    for mode_id, mode_data in data["modes"].items():
        out_path = build_mode_theme(mode_id, mode_data, geometry, typography)
        print(f"Built BGNOME theme ({mode_id}): {out_path}")


if __name__ == "__main__":
    main()
