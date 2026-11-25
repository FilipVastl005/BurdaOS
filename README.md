# BurdaOS

A bootable, Debian 12 (**Bookworm**) Live Linux workstation built with `live-build` as a gift for our Linux and hardware teacher, **Jaroslav Burda**.

It pairs a genuinely usable hardware/networking teaching toolkit, custom **BGNOME** dark frosted-glass GNOME desktop, system-level **Wine**, **ONLYOFFICE + OneDrive sync**, and a passive-aggressive shell engine that judges every typo, broken pipe, and failed `sudo` attempt on `stderr` without ever breaking real `stdout` piping.

---

## Live Login Credentials

- **Display Name:** `Jaroslav Burda`
- **Username:** `Burdik`
- **Password:** `Docasne2025+`
- **Root Password:** `Docasne2025+`

---

## Key Features

### 1. Target Hardware & Base System
- **Base:** Debian 12 Stable (`bookworm`, `amd64`) built via `live-build` (`main contrib non-free non-free-firmware`).
- **Hardware Envelope:** Tuned for **4 CPU cores / 8GB RAM** using `zram-tools` (`zstd` compressed swap in `/etc/default/zramswap`) and VM sysctl tuning (`/etc/sysctl.d/99-burdaos-memory.conf`).
- **Bootloaders:** Custom `BurdaOS` GRUB2 (BIOS/UEFI) and ISOLINUX menus supporting Standard Boot, Copy to RAM (`toram`), and Safe Graphics (`nomodeset`).

### 2. Custom BGNOME Desktop & UX Upgrades
- **Theme:** Extracted **BGNOME-Dark** and **BGNOME-Light** GNOME Shell, GTK3, and GTK4 stylesheets with circular close buttons (`button-layout='close:'`), `prefer-dark`, `Cantarell 11`, `JetBrains Mono 10`, and `adwaita-qt`/`qt5ct`/`qt6ct` dark styling for Qt apps.
- **Dock & Extensions:** Floating bottom dock (`gnome-shell-extension-dashtodock`) styled by BGNOME's `#dash` CSS, `user-theme`, `appindicator`, and `desktop-icons-ng`.
- **Snappy Responsiveness & Window Snapping:** `gnome-shell-extension-impatience` (`0.55` animation speed scale) and `gnome-shell-extension-tiling-assistant` for Windows 11-style edge/quarter snapping (`Super+Arrows`).
- **Clipboard History & File Manager Polish:** `gnome-shell-extension-gpaste` (`Super+V` persistent clipboard history), `gnome-sushi` (`Space` instant preview in Files), `nautilus-extension-gnome-terminal`, and `nautilus-admin`.
- **Lecture Utilities & Zero-Nag Setup:** `gnome-shell-extension-caffeine` (one-click keep-awake toggle), `gnome-shell-extension-system-monitor` (live CPU/RAM/temp readouts), disabled GNOME Initial Setup nag, and telemetry/problem reporting turned off in `dconf`.
- **Wallpapers & Login Banner:** 4 BGNOME SVG wallpapers in `/usr/share/backgrounds/bgnome/` plus a GDM3 login banner (`"Oh, you're back. Go ahead and log in whenever you feel ready—it's not like the CPU has anything better to do."`).

### 3. Passive-Aggressive CLI & Telemetry
- **Shell Roast Engine (`config/includes.chroot/etc/skel/.config/burdaos/roasts.sh`):**
  - Hooks exit codes `1`, `2`, `126`, `127` (`command_not_found_handle`), `130`/`SIGINT`, `137`, `139`, `143`/`SIGTERM`, pipeline failures (`PIPESTATUS`), consecutive fail streaks (`>= 3`), dirty shell exits (`EXIT`), `set -u` unbound variables, `ulimit -u` fork exhaustion, and failed `sudo` invocations across **14 categories × 5 tiers (70 messages)**.
  - **Usability guarantee:** All roasts print strictly to `stderr` (`>&2`), preserving `stdout`, piping, and exact exit codes (`command sudo "$@"`).
  - Supports `BURDAOS_ESCALATION_MODE=random` (default) or `tiered`.
- **`sudo` Policy (`/etc/sudoers.d/99-burdaos` & `/etc/sudoers.lecture`):** Custom passive-aggressive password prompt (`[BurdaOS] Oh, you want root? Bold. Password for %p: `), `badpass_message`, and root lecture.
- **Startup Telemetry (`neofetch`):** Automatically runs in interactive terminals with custom fields (`Upper Thermal Clearance`, `Central Mass Storage`, `Attitude`, and `Resources: 4 Cores / 8GB RAM (Try not to waste all of them at once)`).

### 4. System-Level Windows App Support (Wine)
- Multiarch `i386` enabled via chroot hook (`0100-enable-i386-wine.hook.chroot`) with `wine`, `wine64`, `wine32:i386`, `winetricks`, `cabextract`, `p7zip-full`, `wine-binfmt`, and `binfmt-support`.
- `.exe` and `.msi` MIME associations registered in `/etc/skel/.config/mimeapps.list` for double-clicking in Files (Nautilus) or running directly from the terminal.
- **Windows Compatibility Manager (`burdaos-wine-manager`):** Desktop/menu `zenity` GUI to switch Wine modes (**Windows 7**, **Windows 10**, **Windows 11**), manage Wine prefixes, run `.exe` files, open `winecfg` / `winetricks`, and browse `drive_c`.

### 5. Microsoft-Compatible Office & OneDrive Sync
- **ONLYOFFICE Desktop Editors:** Installed via `0150-install-onlyoffice.hook.chroot` alongside metric-compatible fonts (`fonts-liberation`, `fonts-crosextra-carlito`, `fonts-crosextra-caladea`) and default `.docx`/`.xlsx`/`.pptx`/`.odt`/`.ods`/`.odp` MIME bindings.
- **Microsoft OneDrive Sync (`burdaos-onedrive-sync`):** Desktop/menu `zenity` GUI backed by `onedrive` (`~/OneDrive`) for Microsoft Personal / Microsoft 365 OAuth login, two-way sync, background auto-sync (`onedrive.service`), and quick launch of **ONLYOFFICE** and **Microsoft 365 Online** in Firefox ESR.

### 6. Pre-Installed Teaching Toolkit
- **GUI Admin & Diagnostics:** `gnome-control-center`, `gnome-tweaks`, `gnome-system-monitor`, `gnome-disk-utility`, `gparted`, `synaptic`, `gufw`, `hardinfo`, `cpu-x`, `baobab`, `file-roller`, `evince`, `firefox-esr`.
- **CLI Hardware, Sysadmin & Networking:** `lshw`, `dmidecode`, `inxi`, `pciutils`, `usbutils`, `smartmontools`, `lm-sensors`, `btop`, `htop`, `tmux`, `vim`, `nano`, `nmap`, `tcpdump`, `openssh-client`, `net-tools`, `dnsutils`, `curl`, `wget`.

---

## Project Structure

```text
BurdaOS/
├── build.sh                          # Native live-build or Docker/Podman (debian:bookworm) builder
├── test-vm.sh                        # QEMU/KVM launcher locked to 4 cores & 8GB RAM
├── scripts/
│   └── generate-wallpaper.py         # Optional dark grid wallpaper generator
└── config/
    ├── bootloaders/                  # Custom GRUB2 (BIOS/UEFI) & ISOLINUX menus
    ├── hooks/live/                   # Chroot hooks (Wine i386, ONLYOFFICE, user Burdik, dconf/systemd)
    ├── includes.chroot/              # Rootfs overlay (BGNOME themes, dconf, skel, roasts, Wine/OneDrive GUIs)
    └── package-lists/
        └── burdaos.list.chroot       # Debian 12 (Bookworm) package manifest
```

---

## Building & Testing

### Prerequisites (Arch Linux Host)
```bash
sudo pacman -S --needed docker qemu-desktop edk2-ovmf python imagemagick
sudo systemctl enable --now docker
```
*(Optional: `sudo usermod -aG docker "$USER"` and re-login to run Docker without `sudo`.)*

### Build the ISO
On Debian/Ubuntu with `live-build` installed (`sudo ./build.sh`), or on Arch Linux via the automatic `debian:bookworm` container wrapper:
```bash
./build.sh
```
The compiled hybrid ISO is written to:
```text
out/burdaos-debian12-amd64.iso
```

### Boot in QEMU/KVM (4 Cores / 8GB RAM)
```bash
./test-vm.sh
```
Or pass a specific ISO path:
```bash
./test-vm.sh out/burdaos-debian12-amd64.iso
```
# BurdaOS
