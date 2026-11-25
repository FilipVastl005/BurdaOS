# BGNOME Desktop — Debian Edition (Built From Scratch)

Kompletní desktopové prostředí **BGNOME** (Custom GNOME Shell 45+, GTK4/libadwaita a GTK3) přizpůsobené pro přímou integraci do **Debian-based Linux distribuce** (Debian 12/13, Ubuntu, Linux Mint, LMDE, Devuan, Pop!_OS atd.).

---

## 🚀 Jak BGNOME integrovat do Debian-based distribuce

Kamarád, který vyvíjí Debian distribuci, může BGNOME zavést čistě standardními nástroji ekosystému Debian (`dpkg`, `apt`, `live-build`, `debhelper`):

### 1. Hotový `.deb` balíček
Projekt obsahuje samostatný generátor Debian balíčku v [scripts/build_deb.py](file:///home/ghost/IdeaProjects/Desktop/scripts/build_deb.py), který vytvoří standardní binární balíček:
```bash
python3 scripts/build_deb.py
```
Výsledkem je balíček:
```text
dist/bgnome-desktop-theme_1.0.0-1_all.deb
```
Instalace na jakémkoliv Debian systému:
```bash
sudo apt install ./dist/bgnome-desktop-theme_1.0.0-1_all.deb
```
Nebo přes `dpkg`:
```bash
sudo dpkg -i dist/bgnome-desktop-theme_1.0.0-1_all.deb
sudo apt-get install -f
```

### 2. Standardní zdrojový Debian balíček (`debian/`)
Ve složce [`debian/`](file:///home/ghost/IdeaProjects/Desktop/debian) jsou připraveny standardní soubory pro oficiální sestavení přes `dpkg-buildpackage` nebo Debian buildd daemony:
- [debian/control](file:///home/ghost/IdeaProjects/Desktop/debian/control): Závislosti na `gnome-shell (>= 45)`, `gnome-shell-extensions`, `gsettings-desktop-schemas`, doporučených fontech a rozšířeních.
- [debian/rules](file:///home/ghost/IdeaProjects/Desktop/debian/rules): Build systém řízený `dh` (debhelper v13).
- [debian/changelog](file:///home/ghost/IdeaProjects/Desktop/debian/changelog) & [debian/copyright](file:///home/ghost/IdeaProjects/Desktop/debian/copyright): Standardní Debian specifikace.
- [debian/postinst](file:///home/ghost/IdeaProjects/Desktop/debian/postinst) a [debian/postrm](file:///home/ghost/IdeaProjects/Desktop/debian/postrm): Automatická kompilace GSettings schémat a aktualizace desktop databáze.

Sestavení klasickou Debian cestou:
```bash
dpkg-buildpackage -us -uc -b
```

### 3. Výchozí nastavení distribuce (GSettings Schema Override)
Debian nepoužívá agresivní skripty v `~/.bashrc`. Správný Debian způsob nastavení výchozího vzhledu distribuce je **GSettings vendor override**:
- Soubor [`debian/01_bgnome.gschema.override`](file:///home/ghost/IdeaProjects/Desktop/debian/01_bgnome.gschema.override) je nainstalován do `/usr/share/glib-2.0/schemas/`.
- Při instalaci balíčku spustí trigger `/usr/bin/glib-compile-schemas`, čímž se vygeneruje `gschemas.compiled`.
- Každý uživatel po instalaci ISO distribuce ihned získá:
  - Téma **BGNOME-Amber-Glass** (Shell i GTK)
  - Tmavý režim (`prefer-dark`)
  - 4K tapetu `bgnome-amber.svg`
  - Správné systémové fonty a rozložení tlačítek oken (`appmenu:minimize,maximize,close`).

### 4. Integrace do `live-build` (ISO distribuce)
Pokud kamarád staví instalační / živé ISO pomocí nástroje `live-build`:
1. Vložte vygenerovaný balíček `bgnome-desktop-theme_1.0.0-1_all.deb` do:
   ```text
   config/packages.chroot/
   ```
2. Nebo rozbalte soubory přímo do chrootu:
   ```text
   config/includes.chroot/
   ├── usr/share/themes/BGNOME-Amber-Glass/
   ├── usr/share/backgrounds/bgnome/bgnome-amber.svg
   ├── usr/share/glib-2.0/schemas/01_bgnome.gschema.override
   ├── etc/skel/.config/gtk-4.0/gtk.css
   └── usr/share/wayland-sessions/bgnome-wayland.desktop
   ```

---

## 🎨 Co BGNOME obsahuje (Design)

1. **Obsidian Amber Smoked Glass**:
   - Průsvitné panely s backdrop-filtrem (`blur(24px)`), subtilní 1px skleněné linky a jantarový luminiscenční bloom (`#F59E0B`).
2. **Specular Rim Light (Vrchní světelná hrana)**:
   - Jemný odlesk světla na horním okraji panelů a dialogů (`border-top: 1px solid rgba(255, 232, 200, 0.24)`).
3. **Hardwarově akcelerovaný Mutter Blur**:
   - Připravený profil pro rozšíření `blur-my-shell` ([debian/bgnome-blur-my-shell.dconf](file:///home/ghost/IdeaProjects/Desktop/debian/bgnome-blur-my-shell.dconf)).
4. **Activities Overview, App Grid & GDM Lock Screen**:
   - Kompletní stylizace vyhledávání, dialogů, složek aplikací a přihlašovací obrazovky GDM.
5. **Procedurální 4K SVG Tapety**:
   - 3 tapety pro varianty Amber, Copper a Gold v [assets/wallpapers/](file:///home/ghost/IdeaProjects/Desktop/assets/wallpapers).

---

## 🛡️ Bezpečnostní audit a kontrola (Security Report)

1. **Žádné externí binárky a cizí kód**:
   - Vše je generováno z auditovatelných Python skriptů ze souboru [tokens/palette.json](file:///home/ghost/IdeaProjects/Desktop/tokens/palette.json).
2. **Čisté Debian balíčkování**:
   - Všechny soubory v `.deb` balíčku mají striktně nastaveného vlastníka `root:root` s bezpečnými právy (`0755` pro adresáře, `0644` pro soubory).
   - Skripty `postinst` a `postrm` používají bezpečné volání `set -e` a testují existenci binárek před jejich spuštěním.
3. **Zero External Network Dependencies**:
   - Showcase [showcase/index.html](file:///home/ghost/IdeaProjects/Desktop/showcase/index.html) nepoužívá žádná externí CDN (Google Fonts, cizí skripty), funguje zcela offline v izolovaném sandboxu bez rizika data leaků.
4. **Validace GTK4 a SVG**:
   - Všechny tři varianty stylů (`BGNOME-Amber-Glass`, `BGNOME-Burnished-Copper`, `BGNOME-Midnight-Gold`) jsou 100% validní v GTK 4.20 CSS parseru.
   - Všechna SVG a tapety prošla kontrolou `xmllint`.

---

## 💻 Spuštění živého náhledu v prohlížeči:
```bash
python3 -m http.server 8080 --directory showcase
```
Otevřete `http://localhost:8080` pro otestování přepínání barevných presetů, vysouvacího Quick Settings menu a drag & drop oken.
