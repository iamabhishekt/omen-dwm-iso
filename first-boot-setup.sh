#!/bin/bash
# ============================================================
#  Run ONCE after your first login on the installed system.
#  Fixes akmods timing, sets up monitors, ML container.
# ============================================================
set -euo pipefail

echo "==> 1. Waiting for/forcing NVIDIA module build"
# akmods builds the NVIDIA kmod on first boot; force it now and verify
sudo akmods --force
sudo dracut --force --regenerate-all 2>/dev/null || true
nvidia-smi && echo "    NVIDIA OK" || {
    echo "    NVIDIA not loaded yet — reboot once, it builds in the background."; }

echo "==> 2. Checking hybrid GPU power state"
echo "    Intel iGPU drives the desktop. dGPU status:"
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status 2>/dev/null || \
    echo "    (check your NVIDIA PCI address with: lspci | grep -i nvidia)"
echo "    Run games/ML on the 3070 with:  nvrun <command>"

echo "==> 3. Multi-monitor profiles"
echo "    Arrange your monitors with:  arandr"
echo "    Then save the layout as a profile, e.g.:"
echo "        autorandr --save docked      # externals plugged in"
echo "        autorandr --save mobile      # laptop screen only"
echo "    autorandr's udev hook will switch automatically on plug/unplug."

echo "==> 4. Optional: ML container with CUDA (keeps host clean)"
read -rp "    Create 'ml' distrobox with PyTorch? [y/N] " ans
if [[ "${ans,,}" == "y" ]]; then
    distrobox create --nvidia --name ml --image fedora:latest
    distrobox enter ml -- sudo dnf install -y python3-pip git
    distrobox enter ml -- pip install torch --index-url https://download.pytorch.org/whl/cu124
    echo "    Use it with:  ml   (alias for 'distrobox enter ml')"
fi

echo "==> 5. Steam"
echo "    Launch Steam, enable Proton for all titles."
echo "    Per-game launch option to use the 3070:  nvrun %command%"

echo ""
echo "All done. Reboot recommended:  sudo reboot"
