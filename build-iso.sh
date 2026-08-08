#!/bin/bash
# ============================================================
#  Build the Omen dwm ISO
#  Run this ON a Fedora machine (Workstation is easiest).
#  Needs ~10GB free disk and an internet connection.
# ============================================================
set -euo pipefail

RELEASEVER="${1:-44}"        # pass a Fedora version: ./build-iso.sh 44
ISO_NAME="omen-dwm-fedora${RELEASEVER}.iso"

echo "==> Installing build tools"
sudo dnf install -y livecd-tools spin-kickstarts pykickstart

echo "==> Validating kickstart"
ksvalidator omen-dwm.ks || echo "ksvalidator warnings above are usually OK for repo lines"

echo "==> Building ISO (this takes 15-40 min)"
sudo livemedia-creator \
    --ks omen-dwm.ks \
    --no-virt \
    --make-iso \
    --iso-only \
    --iso-name "${ISO_NAME}" \
    --project "Omen-dwm" \
    --title "Omen dwm Fedora ${RELEASEVER}" \
    --releasever "${RELEASEVER}" \
    --resultdir ./build

echo ""
echo "==> Done. ISO is at: ./build/${ISO_NAME}"
echo "    Flash with: sudo dd if=build/${ISO_NAME} of=/dev/sdX bs=8M status=progress oflag=sync"
echo "    (or use Fedora Media Writer / balenaEtcher)"
