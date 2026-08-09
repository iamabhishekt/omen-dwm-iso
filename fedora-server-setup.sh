#!/bin/bash
# ============================================================
#  Omen dwm — post-install setup for a FRESH Fedora Server 44
#  Run as your normal user (with sudo):  bash fedora-server-setup.sh
#  Replicates the entire custom ISO: NVIDIA hybrid, dwm-titus,
#  lightdm, multimonitor, gaming, lid behavior, dotfiles.
# ============================================================
set -euo pipefail

echo "==> 1/8  System update + RPM Fusion"
sudo dnf upgrade -y --refresh
sudo dnf install -y \
  "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

echo "==> 2/8  X11 + NVIDIA hybrid stack"
sudo dnf install -y \
  xorg-x11-server-Xorg xorg-x11-xinit xsetroot xrandr \
  akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda \
  xorg-x11-drv-nvidia-power xorg-x11-drv-nvidia-libs.i686 \
  akmods kernel-devel mesa-dri-drivers intel-media-driver

echo "==> 3/8  dwm desktop stack (Titus's setup)"
sudo dnf install -y \
  gcc make libX11-devel libXft-devel libXinerama-devel fontconfig-devel freetype-devel \
  git picom rofi kitty feh dunst lxappearance papirus-icon-theme \
  NetworkManager-applet pavucontrol pipewire wireplumber playerctl \
  flameshot thunar gvfs udiskie polkit lxpolkit \
  lightdm lightdm-gtk-greeter arandr autorandr \
  jetbrains-mono-fonts-all fontawesome-6-free-fonts

echo "==> 4/8  Gaming + dev"
sudo dnf install -y \
  steam steam-devices mangohud goverlay gamemode gamescope lutris \
  neovim htop btop podman distrobox tlp firefox

echo "==> 5/8  Build dwm from Titus's repo"
cd /tmp
rm -rf dwm-titus
git clone --depth 1 https://github.com/ChrisTitusTech/dwm-titus.git
cd dwm-titus
for d in dwm st slstatus .; do
  if [ -f "$d/Makefile" ] || [ -f "$d/config.mk" ]; then
    sudo make -C "$d" clean install || echo "WARN: build of $d failed — check output"
  fi
done
[ -f dwm.desktop ] && sudo cp dwm.desktop /usr/share/xsessions/ || true
if [ ! -f /usr/share/xsessions/dwm.desktop ]; then
  printf '[Desktop Entry]\nName=dwm\nComment=Dynamic window manager\nExec=dwm\nType=Application\n' \
    | sudo tee /usr/share/xsessions/dwm.desktop > /dev/null
fi

echo "==> 6/8  Titus's dotfiles (rofi/kitty/dunst/picom)"
cd /tmp
rm -rf titus-dotfiles
git clone --depth 1 https://github.com/ChrisTitusTech/dotfiles.git titus-dotfiles
mkdir -p "$HOME/.config"
for cfg in rofi kitty dunst picom nvim fastfetch; do
  [ -d "titus-dotfiles/.config/$cfg" ] && cp -r "titus-dotfiles/.config/$cfg" "$HOME/.config/"
done

echo "==> 7/8  NVIDIA + power + lid config"
printf '#!/bin/bash\nexport __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only\nexec gamemoderun "$@"\n' \
  | sudo tee /usr/local/bin/nvrun > /dev/null
sudo chmod +x /usr/local/bin/nvrun

printf 'options nvidia-drm modeset=1 fbdev=1\noptions nvidia NVreg_PreserveVideoMemoryAllocations=1\n' \
  | sudo tee /etc/modprobe.d/nvidia-omen.conf > /dev/null

sudo mkdir -p /etc/systemd/logind.conf.d
printf '[Login]\nHandleLidSwitch=suspend\nHandleLidSwitchExternalPower=ignore\nHandleLidSwitchDocked=ignore\n' \
  | sudo tee /etc/systemd/logind.conf.d/99-omen-lid.conf > /dev/null

sudo systemctl enable tlp lightdm
sudo systemctl set-default graphical.target

echo "==> 8/8  Build NVIDIA kernel module (takes a few minutes)"
sudo akmods --force || echo "NOTE: akmods will finish on next boot"

echo ""
echo "============================================"
echo " Done. Reboot now:   sudo reboot"
echo " Login: lightdm -> session 'dwm'"
echo " Terminal: Super+Shift+Enter | Launcher: Super+p"
echo " Monitors: arandr, then 'autorandr --save docked'"
echo " Games: Steam launch option: nvrun %command%"
echo " ML: distrobox create --nvidia ml --image fedora:latest"
echo "============================================"
