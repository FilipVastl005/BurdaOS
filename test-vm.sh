#!/usr/bin/env bash
# ==============================================================================
# BurdaOS — QEMU/KVM Hardware-Locked VM Test Script
# Target Profile: Strictly 4 CPU Cores (-smp 4) and 8GB RAM (-m 8192)
# Usage: ./test-vm.sh [--gl] [--bios] [path/to/image.iso]
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
DEFAULT_ISO="${OUT_DIR}/burdaos-debian12-amd64.iso"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    printf '[BurdaOS VM ERROR] qemu-system-x86_64 not found. Install qemu-desktop.\n' >&2
    exit 1
fi

USE_GL=0
USE_BIOS=0
ISO_FILE=""
for arg in "$@"; do
    case "$arg" in
        --gl) USE_GL=1 ;;
        --bios) USE_BIOS=1 ;;
        *) ISO_FILE="$arg" ;;
    esac
done

if [[ -z "$ISO_FILE" ]]; then
    if [[ -f "$DEFAULT_ISO" ]]; then
        ISO_FILE="$DEFAULT_ISO"
    else
        ISO_FILE="$(ls -1t "${OUT_DIR}"/*debian*.iso 2>/dev/null | head -n1 || true)"
    fi
fi

if [[ -z "$ISO_FILE" || ! -f "$ISO_FILE" ]]; then
    printf '[BurdaOS VM ERROR] Debian ISO (%s) has not been built yet.\n' "$DEFAULT_ISO" >&2
    if ls -1 "${OUT_DIR}"/*.iso >/dev/null 2>&1; then
        printf '[BurdaOS VM ERROR] Found only legacy ISO(s) in %s (not booting old ISO):\n' "$OUT_DIR" >&2
        ls -1 "${OUT_DIR}"/*.iso >&2
    fi
    printf '[BurdaOS VM ERROR] Build the BurdaOS ISO first: ./build.sh\n' >&2
    exit 1
fi

KVM_ARGS=()
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    KVM_ARGS=(-enable-kvm -cpu host)
else
    printf '[BurdaOS VM WARN] /dev/kvm unavailable; falling back to software TCG emulation.\n' >&2
    KVM_ARGS=(-cpu qemu64)
fi

OVMF_ARGS=()
TMP_VARS=""
cleanup() {
    [[ -n "$TMP_VARS" && -f "$TMP_VARS" ]] && rm -f "$TMP_VARS"
}
trap cleanup EXIT

if [[ "$USE_BIOS" -eq 0 ]]; then
    if [[ -r /usr/share/edk2/x64/OVMF_CODE.4m.fd && -r /usr/share/edk2/x64/OVMF_VARS.4m.fd ]]; then
        TMP_VARS="$(mktemp --suffix=.ovmf-vars.fd)"
        cp -f /usr/share/edk2/x64/OVMF_VARS.4m.fd "$TMP_VARS"
        OVMF_ARGS=(
            -drive "if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd"
            -drive "if=pflash,format=raw,file=${TMP_VARS}"
        )
    elif [[ -r /usr/share/edk2/x64/OVMF.4m.fd ]]; then
        TMP_VARS="$(mktemp --suffix=.ovmf.fd)"
        cp -f /usr/share/edk2/x64/OVMF.4m.fd "$TMP_VARS"
        OVMF_ARGS=(-drive "if=pflash,format=raw,file=${TMP_VARS}")
    else
        printf '[BurdaOS VM WARN] OVMF firmware not found; booting with legacy SeaBIOS.\n' >&2
    fi
fi

DISPLAY_ARGS=(-device virtio-vga -display gtk,gl=off)
if [[ "$USE_GL" -eq 1 ]]; then
    DISPLAY_ARGS=(-device virtio-vga-gl -display gtk,gl=on)
fi

printf '[BurdaOS VM] Booting %s with 4 CPU cores and 8192MB RAM...\n' "$ISO_FILE"

qemu-system-x86_64 \
    -machine q35 \
    "${KVM_ARGS[@]}" \
    "${OVMF_ARGS[@]}" \
    -smp 4 \
    -m 8192 \
    -boot d \
    -cdrom "$ISO_FILE" \
    "${DISPLAY_ARGS[@]}" \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0 \
    -device intel-hda \
    -device hda-duplex \
    -usb \
    -device usb-tablet \
    -name "BurdaOS (Debian 12 // 4C / 8GB)"
