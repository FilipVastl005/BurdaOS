#!/usr/bin/env bash
# ==============================================================================
# BurdaOS — Debian 12 (Bookworm) live-build Script
# Supports native `lb` on Debian/Ubuntu OR Docker/Podman (`debian:bookworm`)
# from an Arch Linux host.
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
ISO_NAME="burdaos-debian12-amd64.iso"
CONTAINER_IMAGE="debian:bookworm"

log() {
    printf '[BurdaOS Build] %s\n' "$*"
}

die() {
    printf '[BurdaOS Build ERROR] %s\n' "$*" >&2
    exit 1
}

prepare_assets() {
    log "Generating dark grid wallpaper..."
    python3 "${SCRIPT_DIR}/scripts/generate-wallpaper.py" \
        "${SCRIPT_DIR}/config/includes.chroot/usr/share/backgrounds/burdaos"

    log "Enforcing script and sudoers permissions in config/..."
    chmod 0750 "${SCRIPT_DIR}/config/includes.chroot/etc/sudoers.d"
    chmod 0440 "${SCRIPT_DIR}/config/includes.chroot/etc/sudoers.d/99-burdaos"
    chmod 0444 "${SCRIPT_DIR}/config/includes.chroot/etc/sudoers.lecture"
    chmod 0755 "${SCRIPT_DIR}/config/includes.chroot/etc/skel/.config/burdaos/roasts.sh"
    chmod 0755 "${SCRIPT_DIR}/config/includes.chroot/usr/local/bin/burdaos-wine-manager"
    chmod 0755 "${SCRIPT_DIR}/config/includes.chroot/usr/local/bin/burdaos-onedrive-sync"
    chmod 0755 "${SCRIPT_DIR}/config/includes.chroot/usr/local/bin/burdaos-desktop-trust"
    chmod 0755 "${SCRIPT_DIR}/config/includes.chroot/etc/skel/Desktop/Windows-Compatibility-Manager.desktop"
    chmod 0755 "${SCRIPT_DIR}/config/includes.chroot/etc/skel/Desktop/Microsoft-OneDrive-Sync.desktop"
    chmod 0755 "${SCRIPT_DIR}/config/hooks/live/"*.hook.chroot
}

run_native_live_build() {
    local work_dir="${1:-${SCRIPT_DIR}/.lb-work}"
    if [[ "${EUID}" -ne 0 ]]; then
        die "live-build requires root privileges. Run: sudo ./build.sh"
    fi

    rm -rf "${work_dir}"
    mkdir -p "${work_dir}" "${OUT_DIR}"

    pushd "${work_dir}" >/dev/null
    log "Configuring Debian Bookworm live-build workspace..."
    lb config \
        --distribution bookworm \
        --architectures amd64 \
        --archive-areas "main contrib non-free non-free-firmware" \
        --binary-images iso-hybrid \
        --bootloaders "syslinux,grub-efi" \
        --debian-installer none \
        --iso-application "BurdaOS" \
        --iso-volume "BURDAOS" \
        --bootappend-live "boot=live components quiet splash locales=en_US.UTF-8"

    log "Copying BurdaOS config/ into staged live-build workspace..."
    cp -a "${SCRIPT_DIR}/config/." "${work_dir}/config/"

    # Populate supporting bootloader assets (stdmenu.cfg, vesamenu.c32, etc.)
    # without overwriting BurdaOS custom grub.cfg / live.cfg.in / menu.cfg
    for bl in isolinux grub-pc grub-efi; do
        if [[ -d "/usr/share/live/build/bootloaders/${bl}" ]]; then
            mkdir -p "${work_dir}/config/bootloaders/${bl}"
            cp -rn "/usr/share/live/build/bootloaders/${bl}/." \
                "${work_dir}/config/bootloaders/${bl}/" || true
        fi
    done

    # Re-apply BurdaOS ownership & permissions inside staged config
    chown -R 0:0 "${work_dir}/config/includes.chroot"
    chmod 0440 "${work_dir}/config/includes.chroot/etc/sudoers.d/99-burdaos"
    chmod 0755 "${work_dir}/config/hooks/live/"*.hook.chroot

    log "Building Debian Live ISO (this downloads packages and takes several minutes)..."
    lb build

    local built_iso
    built_iso="$(ls -1t "${work_dir}"/*.iso 2>/dev/null | head -n1 || true)"
    [[ -n "$built_iso" && -f "$built_iso" ]] || die "lb build completed but no .iso was found in ${work_dir}."

    cp -f "$built_iso" "${OUT_DIR}/${ISO_NAME}"
    popd >/dev/null
    log "Build complete: ${OUT_DIR}/${ISO_NAME}"
}

run_container_live_build() {
    local runtime="$1"
    local -a cmd_prefix=()

    if ! "${runtime}" info >/dev/null 2>&1; then
        if [[ "${EUID}" -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
            log "Current user lacks ${runtime} socket access; elevating with sudo..."
            cmd_prefix=(sudo)
        else
            die "Cannot connect to ${runtime} daemon. Run with sudo or add user '$USER' to the ${runtime} group."
        fi
    fi

    log "Using ${runtime} (${CONTAINER_IMAGE}) to build Debian ISO from Arch/non-Debian host..."

    mkdir -p "${OUT_DIR}"

    "${cmd_prefix[@]}" "${runtime}" run --rm --privileged \
        -v "${SCRIPT_DIR}:/workspace" \
        -e "ISO_NAME=${ISO_NAME}" \
        "${CONTAINER_IMAGE}" \
        bash -c '
            set -euo pipefail
            export DEBIAN_FRONTEND=noninteractive
            apt-get update
            apt-get install -y --no-install-recommends \
                live-build debootstrap squashfs-tools xorriso \
                grub-pc-bin grub-efi-amd64-bin mtools dosfstools \
                isolinux syslinux-common python3 ca-certificates

            WORK_DIR="/tmp/burdaos-lb-work"
            rm -rf "$WORK_DIR"
            mkdir -p "$WORK_DIR" /workspace/out
            cd "$WORK_DIR"

            lb config \
                --distribution bookworm \
                --architectures amd64 \
                --archive-areas "main contrib non-free non-free-firmware" \
                --binary-images iso-hybrid \
                --bootloaders "syslinux,grub-efi" \
                --debian-installer none \
                --iso-application "BurdaOS" \
                --iso-volume "BURDAOS" \
                --bootappend-live "boot=live components quiet splash locales=en_US.UTF-8"

            cp -a /workspace/config/. "${WORK_DIR}/config/"

            for bl in isolinux grub-pc grub-efi; do
                if [[ -d "/usr/share/live/build/bootloaders/${bl}" ]]; then
                    mkdir -p "${WORK_DIR}/config/bootloaders/${bl}"
                    cp -rn "/usr/share/live/build/bootloaders/${bl}/." \
                        "${WORK_DIR}/config/bootloaders/${bl}/" || true
                fi
            done

            chown -R 0:0 "${WORK_DIR}/config/includes.chroot"
            chmod 0440 "${WORK_DIR}/config/includes.chroot/etc/sudoers.d/99-burdaos"
            chmod 0755 "${WORK_DIR}/config/hooks/live/"*.hook.chroot

            lb build

            BUILT_ISO="$(ls -1t "${WORK_DIR}"/*.iso 2>/dev/null | head -n1 || true)"
            [[ -n "$BUILT_ISO" && -f "$BUILT_ISO" ]] || { echo "No ISO produced" >&2; exit 1; }
            cp -f "$BUILT_ISO" "/workspace/out/${ISO_NAME}"
        '

    log "Build complete: ${OUT_DIR}/${ISO_NAME}"
}

main() {
    local mode="${1:-auto}"
    prepare_assets

    if [[ "$mode" == "--internal-native" ]]; then
        run_native_live_build "${2:-/tmp/burdaos-lb-work}"
        return 0
    fi

    if [[ "$mode" != "--docker" ]] && command -v lb >/dev/null 2>&1; then
        run_native_live_build "${SCRIPT_DIR}/.lb-work"
    elif command -v docker >/dev/null 2>&1; then
        run_container_live_build docker
    elif command -v podman >/dev/null 2>&1; then
        run_container_live_build podman
    else
        die "Neither native 'lb' (live-build) nor 'docker'/'podman' was found.
On Arch Linux, install Docker (sudo pacman -S docker && sudo systemctl enable --now docker)
and re-run ./build.sh, or run inside a Debian Bookworm environment with live-build."
    fi
}

main "$@"
