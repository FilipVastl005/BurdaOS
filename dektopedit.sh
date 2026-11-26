#!/usr/bin/env bash
# ==============================================================================
# BurdaOS — Fast ISO Desktop & Config Patcher (dektopedit.sh)
# Copies all working-tree files from config/includes.chroot/ (themes, CSS,
# wallpapers, dconf, skel, scripts) into an existing BurdaOS ISO without
# rebuilding Debian packages from scratch.
#
# Usage: sudo ./dektopedit.sh [path/to/burdaos.iso]
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ISO="${SCRIPT_DIR}/out/burdaos-debian12-amd64.iso"
ISO_FILE="${1:-$DEFAULT_ISO}"

log() {
    printf '[BurdaOS Patch] %s\n' "$*"
}

die() {
    printf '[BurdaOS Patch ERROR] %s\n' "$*" >&2
    exit 1
}

if [[ "${EUID}" -ne 0 ]]; then
    die "Root privileges are required to unpack/repack root-owned squashfs files. Run: sudo ./dektopedit.sh"
fi

for cmd in xorriso unsquashfs mksquashfs dconf glib-compile-schemas; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required tool '$cmd' not found."
done

[[ -f "$ISO_FILE" ]] || die "ISO not found: $ISO_FILE (run ./build.sh first)."

WORK_DIR="$(mktemp -d --tmpdir burdaos-patch.XXXXXX)"
cleanup() {
    rm -rf "$WORK_DIR"
}
trap cleanup EXIT

ORIG_SQUASH="${WORK_DIR}/filesystem.squashfs"
NEW_SQUASH="${WORK_DIR}/filesystem.squashfs.new"
SQUASH_ROOT="${WORK_DIR}/squashfs-root"
TMP_ISO="${WORK_DIR}/patched.iso"

log "Extracting /live/filesystem.squashfs from ${ISO_FILE}..."
xorriso -osirrox on -indev "$ISO_FILE" \
    -extract /live/filesystem.squashfs "$ORIG_SQUASH" >/dev/null 2>&1

# Detect original squashfs compression (fallback to xz)
COMP="$(unsquashfs -s "$ORIG_SQUASH" 2>/dev/null | awk '/^Compression / {print $2; exit}' || true)"
[[ -n "$COMP" ]] || COMP="xz"

log "Unpacking squashfs (compression: ${COMP})..."
unsquashfs -d "$SQUASH_ROOT" "$ORIG_SQUASH" >/dev/null

log "Importing media-pool wallpapers & user avatars..."
python3 "${SCRIPT_DIR}/scripts/import-media-pool.py"

log "Copying config/includes.chroot/ into unpacked filesystem..."
cp -a "${SCRIPT_DIR}/config/includes.chroot/." "${SQUASH_ROOT}/"

# Ensure root ownership on system files
chown -R 0:0 "${SQUASH_ROOT}/etc" "${SQUASH_ROOT}/usr" 2>/dev/null || true
if [[ -f "${SQUASH_ROOT}/etc/sudoers.d/99-burdaos" ]]; then
    chmod 0750 "${SQUASH_ROOT}/etc/sudoers.d"
    chmod 0440 "${SQUASH_ROOT}/etc/sudoers.d/99-burdaos"
fi
if [[ -f "${SQUASH_ROOT}/etc/sudoers.lecture" ]]; then
    chmod 0444 "${SQUASH_ROOT}/etc/sudoers.lecture"
fi
chmod 0755 "${SQUASH_ROOT}/etc/skel/.config/burdaos/roasts.sh" 2>/dev/null || true
chmod 0755 "${SQUASH_ROOT}/usr/local/bin/burdaos-"* 2>/dev/null || true

# Sync updated /etc/skel/ into /home/Burdik/ if the live user home exists
if [[ -d "${SQUASH_ROOT}/home/Burdik" ]]; then
    log "Syncing updated /etc/skel/ into /home/Burdik/..."
    BURDIK_UID=$(awk -F: '$1 == "Burdik" {print $3; exit}' "${SQUASH_ROOT}/etc/passwd" || echo 1000)
    BURDIK_GID=$(awk -F: '$1 == "Burdik" {print $4; exit}' "${SQUASH_ROOT}/etc/passwd" || echo 1000)
    cp -a "${SQUASH_ROOT}/etc/skel/." "${SQUASH_ROOT}/home/Burdik/"
    chmod +x "${SQUASH_ROOT}/home/Burdik/Desktop/"*.desktop 2>/dev/null || true
    chown -R "${BURDIK_UID:-1000}:${BURDIK_GID:-1000}" "${SQUASH_ROOT}/home/Burdik"
    chmod 0750 "${SQUASH_ROOT}/home/Burdik"
fi

log "Recompiling GSettings schemas and dconf databases..."
if [[ -d "${SQUASH_ROOT}/usr/share/glib-2.0/schemas" ]]; then
    glib-compile-schemas "${SQUASH_ROOT}/usr/share/glib-2.0/schemas" || true
fi
if [[ -d "${SQUASH_ROOT}/etc/dconf/db/local.d" ]]; then
    dconf compile "${SQUASH_ROOT}/etc/dconf/db/local" "${SQUASH_ROOT}/etc/dconf/db/local.d"
fi
if [[ -d "${SQUASH_ROOT}/etc/dconf/db/gdm.d" ]]; then
    dconf compile "${SQUASH_ROOT}/etc/dconf/db/gdm" "${SQUASH_ROOT}/etc/dconf/db/gdm.d"
fi

log "Repacking filesystem.squashfs (${COMP})..."
mksquashfs "$SQUASH_ROOT" "$NEW_SQUASH" -comp "$COMP" -noappend >/dev/null

log "Updating /live/filesystem.squashfs inside ISO (preserving bootloaders)..."
xorriso -indev "$ISO_FILE" -outdev "$TMP_ISO" \
    -boot_image any replay \
    -update "$NEW_SQUASH" /live/filesystem.squashfs >/dev/null 2>&1

mv -f "$TMP_ISO" "$ISO_FILE"
if [[ -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" ]]; then
    chown "${SUDO_UID}:${SUDO_GID}" "$ISO_FILE"
fi

log "Done! Patched ISO ready: ${ISO_FILE}"
log "Boot it with: ./test-vm.sh"
