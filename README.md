# Omen dwm — Your Own Fedora + NVIDIA + dwm ISO

Same end result as Titus's dwm ISO (Fedora base, dwm-titus desktop, NVIDIA drivers,
lightdm login) but built by you, with his bugs fixed:

- **lightdm crash fixed**: greeter package included, and `%post` can no longer
  kill the install (`exit 1` removed — it warns and falls back to `startx` instead).
- **Hybrid Intel + NVIDIA** baked in (PRIME offload, 3070 sleeps at idle).
- **Multimonitor tooling** included: `arandr` (GUI arranger) + `autorandr`
  (remembers layouts, auto-switches on plug/unplug).
- NVIDIA driver **auto-rebuilds on every kernel update** via akmods.

---

## What you need

- **A GitHub account** — the ISO builds in the cloud, no Linux needed on your Mac
- A Ventoy USB stick

## Step 1 — Customize the kickstart (2 min)

Open `omen-dwm.ks` and change:

```ks
user --name=omen --password=omen --groups=wheel --shell=/bin/bash
```

Set your own username/password. (Anaconda may still prompt during install
depending on image type; the kickstart values are the defaults.)

## Step 2 — Build the ISO in the cloud (works from macOS)

1. Create a new GitHub repo (private is fine) and upload this whole
   `omen-dwm-iso` folder — **including the hidden `.github/` folder**:

   ```bash
   cd omen-dwm-iso
   git init && git add -A && git commit -m "omen-dwm iso"
   gh repo create omen-dwm-iso --private --source=. --push   # or create+push via github.com
   ```

2. On github.com → your repo → **Actions** tab → enable workflows →
   **Build Omen dwm ISO** → **Run workflow** (Fedora version defaults to 44).

3. Wait 20–45 min. When the run goes green: open it → **Artifacts** →
   download `omen-dwm-iso` → unzip → you have `omen-dwm-fedora44.iso`.

> Local alternative: if you ever have a Fedora machine/VM, `./build-iso.sh`
> builds the same ISO locally in 15–40 min.

## Step 3 — Copy to Ventoy and install

Just drag `omen-dwm-fedora44.iso` onto the Ventoy USB like a normal file.
Boot the Omen from it via the Ventoy menu.

BIOS notes for the HP Omen:

- **Disable Secure Boot** (simplest), or enroll the MOK key on first boot when
  the blue screen appears (akmods signs the NVIDIA module locally).
- Keep hybrid/Optimus graphics enabled (not "discrete only") for battery life.

Boot the stick → install like normal Fedora → reboot.

## Step 4 — First boot

The NVIDIA module compiles itself on first boot (1–3 min, one time). Then run:

```bash
chmod +x first-boot-setup.sh
./first-boot-setup.sh
```

It verifies the driver, sets up monitor profiles, and optionally creates a
CUDA-ready `distrobox` for ML.

## Step 5 — Daily use

| Task | How |
|---|---|
| Log in | lightdm → pick "dwm" session (Titus's keybinds/config included) |
| Arrange monitors | `arandr`, then `autorandr --save docked` |
| Game on the 3070 | Steam launch option: `nvrun %command%` |
| ML | `ml` (drops you into the CUDA container) |
| Idle usage | Intel renders desktop, 3070 suspended, dwm ≈ 200–300 MB RAM |
| Updates | `sudo dnf upgrade` — NVIDIA rebuilds automatically |

## Troubleshooting

- **Black screen after install**: boot, wait 2 min (akmods compiling), then
  check `nvidia-smi`. If missing: `sudo akmods --force && sudo reboot`.
- **Monitors not detected on NVIDIA ports**: on many Omens the HDMI/DP ports
  are wired to the dGPU. They still work in hybrid mode; if a port is dead,
  run `nvrun startx`-style offload or check BIOS mux setting.
- **dwm keybindings**: `Mod` = Super/Windows key. `Mod+Shift+Enter` = terminal
  (kitty), `Mod+p` = rofi launcher. Config is in the dwm-titus source;
  edit `config.h` and `sudo make clean install` to change it.

## Rebuilding / updating the ISO

Re-run `./build-iso.sh` anytime — every build pulls the latest Fedora packages
and NVIDIA driver. Your installed system never needs the ISO again; it updates
with `dnf upgrade` forever.
