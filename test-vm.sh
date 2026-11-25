#!/usr/bin/env bash
# ==============================================================================
# BurdaOS — QEMU/KVM Hardware-Locked VM Test Script
# Target Profile: Strictly 4 CPU Cores (-smp 4) and 8GB RAM (-m 8192)
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/out"
DEFAULT_ISO="${OUT_DIR}/burdaos-debian12-amd64.iso"

if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    printf '[BurdaOS VM ERROR] qemu-system-x86_64 not found. Install qemu-desktop.\n' >&2
    exit 1
fi

ISO_FILE="${1:-}"
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
for ovmf in \
    /usr/share/edk2/x64/OVMF_CODE.4m.fd \
    /usr/share/edk2/x64/OVMF_CODE.fd \
    /usr/share/OVMF/OVMF_CODE.fd; do
    if [[ -r "$ovmf" ]]; then
        OVMF_ARGS=(-drive "if=pflash,format=raw,readonly=on,file=${ovmf}")
        break
    fi
done

printf '[BurdaOS VM] Booting %s with 4 CPU cores and 8192MB RAM...\n' "$ISO_FILE"

exec qemu-system-x86_64 \
    "${KVM_ARGS[@]}" \
    "${OVMF_ARGS[@]}" \
    -smp 4 \
    -m 8192 \
    -boot d \
    -cdrom "$ISO_FILE" \
    -vga virtio \
    -display gtk,gl=on \
    -device virtio-net-pci,netdev=net0 \
    -netdev user,id=net0 \
    -device intel-hda \
    -device hda-duplex \
    -usb \
    -device usb-tablet \
    -name "BurdaOS (Debian 12 // 4C / 8GB)"
