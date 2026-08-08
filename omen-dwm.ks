# ============================================================
#  Omen dwm — Fedora Live/Install ISO kickstart
#  Base: Fedora + RPM Fusion + NVIDIA (akmods) + dwm-titus
#  Fixes: lightdm greeter missing, fragile %post exit 1
# ============================================================
#version=DEVEL

# --- Repos ---
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch"
repo --name=updates --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch"
repo --name=rpmfusion-free --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch"
repo --name=rpmfusion-nonfree --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch"

# --- Disk / system ---
# live image rootfs size (the live environment; the installer copies this)
part / --size=12288 --fstype=ext4
bootloader --location=mbr --append="quiet rhgb"
timezone UTC --utc
keyboard us
lang en_US.UTF-8
network --bootproto=dhcp --device=link --activate
selinux --enforcing
firewall --enabled

# CHANGE THESE:
rootpw --lock
user --name=abhishek --password=1998@Abhi --groups=wheel --shell=/bin/bash

services --enabled=NetworkManager,sshd,akmods

# --- Packages ---
%packages --ignoremissing
@core
kernel
kernel-devel
kernel-headers
dracut-live
dracut-config-generic
anaconda-live
livesys-scripts
grub2-efi-x64
shim-x64
efibootmgr

# Firmware
linux-firmware
iwlwifi-mvm-firmware
linux-firmware-whence

# --- X11 base ---
xorg-x11-server-Xorg
xorg-x11-xinit
xorg-x11-xauth
xorg-x11-utils
xsetroot
xrandr
polkit
lxpolkit

# --- NVIDIA (hybrid Intel+NVIDIA, PRIME offload, DKMS-style auto rebuild) ---
akmod-nvidia
xorg-x11-drv-nvidia
xorg-x11-drv-nvidia-cuda
xorg-x11-drv-nvidia-power
xorg-x11-drv-nvidia-libs.i686
akmods
mesa-dri-drivers
intel-media-driver

# --- dwm build deps + dwm-titus stack ---
gcc
make
libX11-devel
libXft-devel
libXinerama-devel
fontconfig-devel
freetype-devel
git

# dwm desktop bits (Titus's stack)
picom
rofi
kitty
feh
dunst
lxappearance
papirus-icon-theme
NetworkManager-applet
pavucontrol
pipewire
pipewire-pulseaudio
wireplumber
playerctl
flameshot
thunar
gvfs
udiskie

# --- Multimonitor ---
arandr
autorandr

# --- LightDM (WITH greeter — the fix for Titus's bug) ---
lightdm
lightdm-gtk-greeter
lightdm-gtk-greeter-settings

# --- Dev / ML / gaming ---
neovim
htop
btop
curl
wget
unzip
podman
distrobox
steam
steam-devices
mangohud
goverlay
gamemode
gamescope
gamescope-session
lutris

# --- Fonts ---
jetbrains-mono-fonts-all
fontawesome-6-free-fonts
google-noto-fonts-common
google-noto-emoji-color-fonts

# --- Power ---
tlp
tlp-rdw

firefox
%end

# ============================================================
#  Post-install configuration
#  NOTE: never `exit 1` here — warn and continue instead.
# ============================================================
%post --log=/root/ks-post.log

# --- Build dwm + st + slstatus from Titus's repo into the image ---
cd /tmp
git clone --depth 1 https://github.com/ChrisTitusTech/dwm-titus.git || echo "WARN: dwm-titus clone failed (offline?)" >> /root/ks-post.log
if [ -d dwm-titus ]; then
    cd dwm-titus
    # the repo carries dwm/st/slstatus sources; build whatever exists
    for d in dwm st slstatus .; do
        if [ -f "$d/Makefile" ] || [ -f "$d/config.mk" ]; then
            make -C "$d" clean install >> /root/ks-post.log 2>&1 || \
                echo "WARN: build of $d failed" >> /root/ks-post.log
        fi
    done
    # install Titus's desktop entry so lightdm shows "dwm"
    [ -f dwm.desktop ] && cp dwm.desktop /usr/share/xsessions/ || true
    cd /tmp && rm -rf dwm-titus
fi

# --- Fallback desktop entry if the repo layout changes ---
mkdir -p /usr/share/xsessions
if [ ! -f /usr/share/xsessions/dwm.desktop ]; then
cat > /usr/share/xsessions/dwm.desktop <<'EOF'
[Desktop Entry]
Name=dwm
Comment=Dynamic window manager
Exec=dwm
Type=Application
EOF
fi

# --- LightDM: enable with greeter, graphical target ---
if systemctl list-unit-files lightdm.service >/dev/null 2>&1; then
    systemctl enable lightdm.service
    systemctl set-default graphical.target
else
    # graceful fallback: console + startx (NOT a fatal error)
    systemctl set-default multi-user.target
    echo "exec dwm" > /etc/skel/.xinitrc
    echo "WARN: lightdm missing, fell back to startx" >> /root/ks-post.log
fi

# --- NVIDIA PRIME offload wrapper with gamemode (Intel drives desktop, 3070 on demand) ---
cat > /usr/local/bin/nvrun <<'EOF'
#!/bin/bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
# gamemode boosts CPU governor while the game runs; harmless if not installed
exec gamemoderun "$@"
EOF
chmod +x /usr/local/bin/nvrun

# --- NVIDIA kernel modesetting (needed for tear-free + external ports) ---
mkdir -p /etc/modprobe.d
cat > /etc/modprobe.d/nvidia-omen.conf <<'EOF'
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

# --- Power services ---
systemctl enable tlp.service

# --- Sane defaults for every new user (skel) ---
mkdir -p /etc/skel/.config/autorandr /etc/skel/.config/picom

# picom: gentle, tear-free on hybrid graphics
cat > /etc/skel/.config/picom/picom.conf <<'EOF'
backend = "glx";
vsync = true;
fading = false;
inactive-opacity = 1.0;
shadow = false;
EOF

# bashrc helpers
cat >> /etc/skel/.bashrc <<'EOF'
alias ll='ls -alh'
alias game='nvrun'
alias ml='distrobox enter ml'
EOF

# --- Steam needs 32-bit driver libs; nothing to do here, package installed above ---
echo "omen-dwm ks %post finished" >> /root/ks-post.log
%end
