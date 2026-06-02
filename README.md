# Unofficial ROCKNIX port for the Poco F1 (beryllium-ebbg)

**Built for personal use.** This is an unofficial ROCKNIX device port for the
Xiaomi Poco F1 (codename *beryllium*, EBBG panel variant / Snapdragon 845).

### How it was built
This port was developed almost entirely using **agentic AI (Claude Opus 4.8)** —
the device target, kernel configuration, build fixes, and bring-up were driven
through an AI coding agent. It's an experiment as much as a device port.

### Scope & support
- **Personal project, no support.** Built for my own device and use case; issues
  and PRs may go unanswered, and there are no guarantees it works for you.
- **EBBG panel only.** I have **no intention of supporting the Tianma panel
  variant or any other sdm845 device** (OnePlus 6/6T, Mi 8, etc.).
- **…but feel free to reuse anything.** The `SDM845` target is structured as a
  generic sdm845 platform — if you want to add the Tianma panel or another
  sdm845 device, take whatever is useful from this fork.

### Firmware
Proprietary per-device firmware (DSP/GPU blobs) is **not included** and is
gitignored — extract it from your own device (see the firmware README under
`projects/ROCKNIX/devices/SDM845/`).

*Not affiliated with or endorsed by the ROCKNIX project. A more detailed
technical write-up will be added once the port boots.*

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
