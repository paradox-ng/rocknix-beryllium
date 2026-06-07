# Unofficial ROCKNIX port - Xiaomi Poco F1 (beryllium, EBBG)

**Personal, experimental, unofficial.** A ROCKNIX device port for the Xiaomi
Poco F1 (codename *beryllium*, **EBBG panel only**, Snapdragon 845 / Adreno 630),
built as a handheld emulation + Steam device.

> **Disclaimer:** This port was built with the help of an agentic AI coding agent
> (**Claude Opus 4.8**). My background is fullstack web development. I'm comfortable
> with Linux distributions and the kernel but I'm not a systems or kernel developer,
> so for this personal, non-commercial project I leaned on AI to bridge that gap and
> get ROCKNIX running on my own device.

## What works
- Boots to EmulationStation; landscape display, GPU (Adreno 630 via freedreno +
  turnip), storage, WiFi, Bluetooth, battery, suspend, USB host.
- **Emulators** - the standalone + libretro set mirrored from the SM8250/Retroid
  Pocket 5 (Dolphin, PPSSPP, RPCS3, AetherSX2, Flycast, melonDS, mupen64plus,
  DuckStation, …).
- **Steam** via FEX (x86→ARM emulation) + Proton, under gamescope (Steam Deck UI).
- **Audio** (speaker + headphones), **Bluetooth Xbox controller** (in ES and
  Steam), and the **Quick Access Menu** wirelessly (Guide + A).

## Known issues
- **WiFi MAC / IP wanders across reboots.** machine-id is now stable, but
  NetworkManager isn't honoring the intended stable MAC (and `/var` is tmpfs), so
  DHCP may hand out a different IP each boot. Find the device by scanning your LAN
  or checking your router. *(Fix in progress.)*
- No modem / telephony (this is a gaming build).

## Prebuilt images
Prebuilt **boot + system** images are attached to [Releases](../../releases) -
flash those directly (see *Flashing* below); the required firmware is already
baked in, so you do **not** need to extract firmware or build anything. To build
your own instead, read on.

## Building from source
Requires Docker (the build runs in the ROCKNIX builder container):
```
make docker-SDM845 DOCKER_WORK_DIR=/work
```
- **`DOCKER_WORK_DIR=/work` is required** - the toolchain bakes `/work` into
  binary RUNPATHs, so the repo must be mounted there. Omitting it mounts the host
  path and the build fails while sourcing config.
- 64-bit only (`ENABLE_32BIT=false`); a full build needs a large build tree
  (~100 GB+ of disk).
- Output lands in `target/`: `ROCKNIX-SDM845.aarch64-<date>.tar` (contains
  `KERNEL` = the boot image and `SYSTEM` = the root squashfs) and a full
  `….img.gz` disk image.

## Firmware (you must supply your own)
The proprietary per-device DSP/modem firmware (`adsp.mbn`, `cdsp.mbn`,
`modem.mbn`, `slpi.mbn`, `venus.mbn`, …) is **not redistributable** and is **not
included** (gitignored). Before building, extract it from *your own* device into:
```
projects/ROCKNIX/devices/SDM845/filesystem/usr/lib/kernel-overlays/base/lib/firmware/qcom/sdm845/Xiaomi/beryllium/
```
Get the blobs from your device's `/vendor/firmware*` or a postmarketOS beryllium
install - see `beryllium-FIRMWARE-README.md` beside that directory. The
redistributable Adreno 630 GPU microcode (`a630_*`) **is** included.

## Flashing
The Poco F1 boots a standard fastboot Android boot image (no signed ABL). From a
build, extract the boot image and the system filesystem:
```
tar xf target/ROCKNIX-SDM845.aarch64-<date>.tar
cp ROCKNIX-SDM845.aarch64-*/target/KERNEL boot.img        # the boot image
gunzip -kc target/ROCKNIX-SDM845.aarch64-*.img.gz > disk.img
dd if=disk.img of=system.img bs=1M skip=16 count=2048      # partition 1 = system FAT
```
Then, with the phone in fastboot:
```
fastboot flash boot   boot.img
fastboot flash system system.img
fastboot reboot
```
- **Updating** an existing install: flash only **boot** and **system** - leave
  `userdata` untouched so Steam, your config, and games persist.
- **First install** additionally needs a `STORAGE` (ext4, label `STORAGE`)
  filesystem on `userdata`; it auto-resizes on first boot.

## No OTA / online updates
The in-OS "System Update" is **disabled** on this build - the ROCKNIX update
server has no images for an unofficial device, and an OTA would flash a stock
image that won't boot here and wipes the device-specific fixes. **Update only by
fastboot-reflashing a new build** (boot + system; keep `userdata`).

## Steam
After flashing, run **Install Steam** from the menu - it downloads the Steam
client, the FEX x86 rootfs, and Proton to `/storage` (~6 GB, one-time, requires
your Steam login).

## Performance tips (Steam / FEX)
x86 games run under FEX emulation, feeding the Adreno GPU through a Vulkan thunk -
so the rendering path matters a lot:
- **OpenGL games are slow by default** (Mesa falls back to software under FEX).
  For a native-Linux GL game, set the launch option
  `MESA_LOADER_DRIVER_OVERRIDE=zink %command%` to route GL → Vulkan → GPU.
- **For an OpenGL game, the Windows build via Proton is often *faster*** than the
  native Linux build - D3D → DXVK → Vulkan avoids the emulated GL driver entirely.
- **The build pins Steam/FEX to the 4 big A75 cores** (the Tegra-X1/Switch model:
  use the strong cores, ignore the little ones) for steadier frametimes. Note the
  ceiling for emulated x86 *GL* games is FEX/thunk latency, not raw GPU power.
- **Charge with a direct charger, not a USB hub/dock.** A dock enumerates as a
  500 mA data port and can't keep up with gaming; a direct charger negotiates
  ~1.5 A. (Mainline has no Quick Charge, so heavy games may still slowly drain.)

## Kernel
Uses the **sdm845-mainline** community kernel (`sdm845-7.1-rc1-r0`, the newest
tag) - pure mainline does not boot beryllium reliably. If you hit kernel
instability, `sdm845-6.16.7-r0` is the more conservative kernel postmarketOS
ships.

## Credits
This port stands on the work of others:
- **[sdm845-mainline](https://gitlab.com/sdm845-mainline)** - the kernel
  (`linux`) and the beryllium ALSA UCM profile (`alsa-ucm-conf`).
- **[postmarketOS / pmaports](https://gitlab.postmarketos.org/postmarketOS/pmaports)**
  - device bring-up reference (kernel config, device tree, firmware packaging).
- **[ROCKNIX](https://github.com/ROCKNIX/distribution)** and its upstream
  **[JELOS](https://github.com/JustEnoughLinuxOS)** - the base distribution.
- xpadneo, FEX, Proton-CachyOS, gamescope, and the wider open-source community.

## Scope & support
- **Personal project, no support.** Issues and PRs may go unanswered; no
  guarantees it works for you.
- **EBBG panel only.** No plans to support the Tianma variant or other sdm845
  devices - but the `SDM845` target is structured as a generic sdm845 platform,
  so take whatever is useful.
- Not affiliated with or endorsed by the ROCKNIX project.

---

<img src="https://github.com/ROCKNIX/distribution/blob/next/distributions/ROCKNIX/logos/rocknix-logo.png?raw=yes" width=192>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[![Latest Version](https://img.shields.io/github/release/ROCKNIX/distribution.svg?color=FF5555&label=latest%20version&style=flat-square)](https://github.com/ROCKNIX/distribution/releases/latest) [![Activity](https://img.shields.io/github/commit-activity/m/ROCKNIX/distribution?color=FF5555&style=flat-square)](https://github.com/ROCKNIX/distribution/commits) [![Pull Requests](https://img.shields.io/github/issues-pr-closed/ROCKNIX/distribution?color=FF5555&style=flat-square)](https://github.com/ROCKNIX/distribution/pulls) [![Discord Server](https://img.shields.io/discord/948029830325235753?color=FF5555&label=chat&style=flat-square)](https://discord.gg/seTxckZjJy)

---

ROCKNIX is an immutable Linux distribution for handheld gaming devices developed by a small community of enthusiasts.  Our goal is to produce an operating system that has the features and capabilities that we need, and to have fun as we develop it.

## Features

* ROCKNIX has a very active community of developers and users.
* Integrated cross-device local and remote network play.
* In-game touch support on supported devices.
* Fine grain control for battery life or performance.
* Includes support for playing Music and Video.
* Bluetooth audio and controller support.
* Support for HDMI audio and video out, and USB audio.
* Device to device and device to cloud sync with Syncthing and rclone.
* VPN support with Wireguard, Tailscale, and ZeroTier.
* Includes built-in support for scraping and retroachievements.

## Screenshots

<table>
  <tr>
    <td><img src="https://rocknix.org/_inc/images/screenshots/system-view.png"/></td>
    <td><img src="https://rocknix.org/_inc/images/screenshots/menu.png"/></td>
  </tr>
  <tr>
    <td><img src="https://rocknix.org/_inc/images/screenshots/gamelist-view-metadata-immersive.png"/></td>
    <td><img src="https://rocknix.org/_inc/images/screenshots/gamelist-view-no-metadata-immersive.png"/></td>
  </tr>
</table>

## Community

The ROCKNIX community utilizes Discord for discussion, if you would like to join us please use this link: [https://discord.gg/seTxckZjJy](https://discord.gg/seTxckZjJy)

## Licenses

**ROCKNIX** is a fork of [JELOS](https://github.com/JustEnoughLinuxOS/distribution/), all licenses apply and credit to the JELOS team. 

You are free to:

- Share: copy and redistribute the material in any medium or format
- Adapt: remix, transform, and build upon the material

Under the following terms:

- Attribution: You must give appropriate credit, provide a link to the license, and indicate if changes were made. You may do so in any reasonable manner, but not in any way that suggests the licensor endorses you or your use.
- NonCommercial: You may not use the material for commercial purposes.
- ShareAlike: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.

### ROCKNIX Software

Copyright (C) 2024-present [ROCKNIX](https://github.com/ROCKNIX)

Original software and scripts developed by the ROCKNIX are licensed under the terms of the [GNU GPL Version 2](https://choosealicense.com/licenses/gpl-2.0/).  The full license can be found in this project's licenses folder.

### Bundled Works
All other software is provided under each component's respective license.  These licenses can be found in the software sources or in this project's licenses folder.  Modifications to bundled software and scripts by the JELOS team are licensed under the terms of the software being modified.

## Credits

Like any Linux distribution, this project is not the work of one person.  It is the work of many persons all over the world who have developed the open source bits without which this project could not exist.  Special thanks to CoreELEC, LibreELEC, JELOS, and to developers and contributors across the open source community.
