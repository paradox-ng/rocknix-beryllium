# CLAUDE.md - ROCKNIX port to the Xiaomi Poco F1 (beryllium / sdm845)

Project context for AI agents and humans. This is a personal fork of
[ROCKNIX/distribution](https://github.com/ROCKNIX/distribution) that adds a device
target for the **Xiaomi Poco F1** (codename **beryllium**, Snapdragon 845 / Adreno
630). Branch: `sdm845-beryllium`. Origin: `github.com/paradox-ng/rocknix-beryllium`;
upstream remote = `ROCKNIX/distribution` (`next`).

The build tree (`build.*`, `sources/`, `target/`, ~145 GB) is disposable - everything
below regenerates it from a clean clone. The proprietary firmware is the only thing
not in git (see Firmware).

---

## Conventions (please follow)

- **Commits:** never add a `Co-Authored-By` trailer or mention Claude/AI in commit
  messages. Plain, factual messages.
- **Writing:** no em/en dashes anywhere (docs, comments, commits) - use plain hyphens.
- **Proprietary firmware stays out of git** (gitignored). It's hosted externally as a
  bundle and/or extracted from the device. Never commit the blobs; never conceal what
  they are.
- **OTA is disabled** for this device (no official images exist); update by reflashing.

---

## Build from a clean clone

Requires Docker + ~150 GB free disk. The build runs in `ghcr.io/rocknix/rocknix-build:latest`.

```bash
git clone -b sdm845-beryllium git@github.com:paradox-ng/rocknix-beryllium.git
cd rocknix-beryllium                       # this is the "distribution" dir

# 1. Supply the proprietary firmware (see Firmware section) into the tree, then:
make docker-SDM845 DOCKER_WORK_DIR=/work
```

- **`DOCKER_WORK_DIR=/work` is MANDATORY.** The toolchain bakes `/work` into binary
  RUNPATHs; omit it and the build fails sourcing config (libxml2.so.16 not found from
  the toolchain xmlstarlet).
- Docker daemon must be running (`sudo systemctl start docker`).
- Output lands in `target/`:
  - `ROCKNIX-SDM845.aarch64-<date>.tar` - contains `KERNEL` (the EBBG boot image) and
    `SYSTEM` (the root squashfs).
  - `ROCKNIX-SDM845.aarch64-<date>.img.gz` - full disk image (partition 1 = system FAT,
    partition 2 = storage ext4).

### Forcing a kernel rebuild

LibreELEC/ROCKNIX only stamps `package.mk`, **not** `config/*.conf` or new patches. After
editing `linux.aarch64.conf` or adding a `patches/linux/*.patch`, force the kernel to
re-unpack + re-patch + recompile:

```bash
rm -rf build.ROCKNIX-SDM845.aarch64/.stamps/linux \
       build.ROCKNIX-SDM845.aarch64/build/linux-sdm845-7.1-rc1-r0
```
Same idea for other packages: `./scripts/clean <pkg>` (inside the container) or delete
its stamp + build dir. (`DISTRO_CLEAN=...` is NOT a thing.)

---

## Firmware (proprietary, not in git)

The Qualcomm/Xiaomi/TI signed blobs (`adsp.mbn`, `cdsp.mbn`, `slpi.mbn`, `mba.mbn`,
`modem.mbn`, `venus.mbn`, `wlanmdsp.mbn`, `ipa_fws.mbn`, `a630_zap.mbn` + `*.jsn`, and the
TAS2559 speaker files) are gitignored. Two ways to get them into the tree:

- **Bundle:** `beryllium-firmware.tar.gz` (sha256 `8bfd3d06...`), 18 entries, extract from
  the repo root:
  ```bash
  tar xzf beryllium-firmware.tar.gz \
    -C projects/ROCKNIX/devices/SDM845/filesystem/usr/lib/kernel-overlays/base/lib/firmware/
  ```
  Hosted off-repo (link in `README.md` / the firmware README).
- **Extract from your own F1** (pmOS): `tar czf - -C /lib/firmware qcom/sdm845 ath10k/WCN3990 qca`
  then drop `qcom/sdm845/Xiaomi/beryllium/*` (uncompressed) into the dir above; TAS2559
  files (`tas2559_uCDSP.bin`, `tas2559_{l,r}.ftcfg`) at the firmware root.

The redistributable Adreno 630 GPU microcode (`a630_sqe.fw`, `a630_gmu.bin`) IS tracked,
and is embedded into the kernel via `CONFIG_EXTRA_FIRMWARE` (the GPU probes before the
initramfs populates `/lib/firmware`, so it must be built-in). `a630_zap.mbn` is embedded too.

See `projects/.../Xiaomi/beryllium-FIRMWARE-README.md`.

---

## Building the flashable images (post-build)

The release ships **per-panel boot images** + shared system/storage. The build only
compiles the EBBG dtb (config.xml declares it), so Tianma is assembled manually.

- **boot-ebbg.img** = the build's `target/KERNEL` as-is. It's `gzip(Image)` + the appended
  ebbg dtb, packed with the beryllium boot geometry + clean cmdline (see below).
- **boot-tianma.img** = recompile the tianma dtb, then repack with the SAME geometry:
  ```bash
  # in the build container, replay the kernel's recorded dtb command for tianma:
  #   host-gcc -E (cpp) sdm845-xiaomi-beryllium-tianma.dts -> .tmp ; ./scripts/dtc/dtc -> .dtb
  # then on host:
  gzip -c arch/arm64/boot/Image > k.gz ; cat <tianma.dtb> >> k.gz
  python3 <toolchain>/mkbootimg/mkbootimg.py --kernel k.gz --ramdisk <(printf dummy) \
    --base 0 --kernel_offset 0x8000 --ramdisk_offset 0x1000000 --tags_offset 0x100 \
    --pagesize 4096 --header_version 0 --os_version 12.0.0 --os_patch_level <YYYY-MM> \
    --cmdline "boot=LABEL=ROCKNIX disk=LABEL=STORAGE rootwait quiet video=efifb:off console=tty0 fbcon=rotate:3" \
    -o boot-tianma.img
  ```
- **system.img** = partition 1 of the disk image: `dd bs=512 skip=32768 count=4194304`.
- **storage.img** = partition 2: `dd bs=512 skip=4227072 count=65536` (empty ext4, auto-resizes).

**Boot geometry (beryllium ABL requires exactly this; verified vs pmOS's boot.img):**
base 0, kernel_offset 0x8000, ramdisk_offset 0x1000000, tags_offset 0x100, **pagesize 4096**,
header v0. mkbootimg defaults (base 0x10000000, 2048 pages) are rejected. This is baked into
`projects/ROCKNIX/packages/linux/package.mk` (SDM845 case in `makeinstall_target`), so
`target/KERNEL` is already correct.

`dr_mode` is `otg` (the shipped value; works for charging - USB host needs a powered hub).

### Flashing (fastboot)

```bash
# First install (all three; storage auto-resizes on first boot):
fastboot flash boot     boot-ebbg.img      # or boot-tianma.img for the Tianma panel
fastboot flash system   system.img
fastboot flash userdata storage.img
fastboot reboot
# Update (keep games/config): flash boot + system only.
```
Partitions: boot->`boot`, system(FAT label ROCKNIX, 4K sectors)->`system`, storage(ext4
label STORAGE)->`userdata`/sda21. If a first install loops, the userdata partition may have
a stale backup GPT at its end - zero both ends of the partition before writing.

---

## Device facts

- **SoC:** SDM845, 4x A55 (cpu0-3 @1.77GHz) + 4x A75 (cpu4-7 @2.65GHz). GPU Adreno 630 (max
  710 MHz). WCN3990 WiFi+BT. Storage UFS, **4K-native logical sectors** (hence the 4K FAT).
- **Panels:** two variants, EBBG (`ebbg,ft8719`) and Tianma (`tianma,fhd-video`/`nt36672a`).
  Differ only in panel + touch controller; everything else is in the shared
  `sdm845-xiaomi-beryllium-common.dtsi`, so device fixes carry to both. EBBG is tested;
  Tianma is built but unverified (no hardware).
- **Panel native res:** 1080x2246 portrait; held landscape = 2246x1080 (~2.4 MP).
- **Kernel:** fetched directly from `gitlab.com/sdm845-mainline/linux` tag
  `sdm845-7.1-rc1-r0` (the SDM845 case in `linux/package.mk`; NOT the ROCKNIX mainline).
  Conservative fallback if unstable: `sdm845-6.16.7-r0` (pmOS-blessed).
- No fused WiFi/BT MAC (random each boot; BT addr set via DT patch).

---

## What the port changes (by area)

### Kernel patches - `projects/ROCKNIX/devices/SDM845/patches/linux/`
- `9100-disable-slpi-cdsp-remoteproc.patch` - `&slpi_pas`/`&cdsp_pas` to `disabled`; they
  crash-loop (fastrpc storm) and stall boot. Also `CONFIG_QCOM_FASTRPC=n`.
- `9101-usb-dr-mode-otg.patch` - dwc3 `dr_mode = "otg"` (was peripheral-only).
- `9102-bluetooth-bd-address.patch` - `local-bd-address` on `&uart6/bluetooth` (WCN3990 has
  no stored BT MAC; without it hci0 is DOWN/RAW).
- `9103-ath-regd-world-roaming.patch` - in `__ath_regd_init`, force `reg->current_rd = 0x60`
  (WOR0_WORLD). The radio EEPROM is locked to country CN, which ath enforces as STRICT and
  disables 5 GHz ch 100-144. `0x60`'s world regdomain is `ATH_5GHZ_ALL` (includes the
  5470-5725 midband); `0x64` (the driver's default) is `ATH_5GHZ_NO_MIDBAND` - do not use it.

### Kernel config - `devices/SDM845/linux/linux.aarch64.conf` (ROCKNIX overrides)
- `CONFIG_REGULATOR_QCOM_REFGEN=y` - DSI `refgen` supply; without it the panel defers forever
  (black screen). This was THE display fix.
- `CONFIG_BATTERY_PMI8998_FG=y` - battery % (PMI8998 fuel gauge).
- `CONFIG_FRAMEBUFFER_CONSOLE_ROTATION=y` - lets `fbcon=rotate:3` rotate the boot console.
- OVERLAY_FS / SQUASHFS_ZSTD+XZ / ZRAM / ZSMALLOC built-in (initramfs needs them).

### linux/package.mk (SDM845 case)
- Kernel source = sdm845-mainline tag; `PKG_BUILD_PERF="no"`; config = pmOS
  `config-postmarketos-qcom-sdm845.aarch64` + the ROCKNIX overrides.
- `makeinstall_target` packs the qcom-abl boot image with the beryllium geometry, and embeds
  `a630_{sqe.fw,gmu.bin,zap.mbn}` via `external-firmware/` for `CONFIG_EXTRA_FIRMWARE`.

### Build-system fixes
- `scripts/get_git` - when a submodule's pinned commit can't be fetched via the shallow/
  direct-SHA fetch ("not our ref"), fall back to a full all-branches clone + checkout. Fixes
  gamescope's wlroots fork pin.
- `scripts/mkimage` - for `qcom-abl`, build the SYSTEM FAT with `mkfs.vfat -S 4096 -s 4` (UFS
  is 4K-native; 512B sectors give EIO on mount) and STORAGE ext4 with 4K blocks.
- gamescope `package.mk` pinned to a known-good commit (upstream's bump broke the wlroots pin).
- busybox `config/busybox-target.conf` (ROCKNIX override) `CONFIG_STRINGS=y` (Steam installer +
  profile.d need it). Override shadows base; `./scripts/clean busybox` to rebuild.

### Device filesystem - `devices/SDM845/filesystem/`
- `.../firmware/qcom/sdm845/Xiaomi/beryllium/*` + `tas2559_*` - proprietary (gitignored).
- `.../alsa/ucm2/Xiaomi/beryllium/*` + `conf.d/sdm845/"Xiaomi Poco F1.conf"` - audio UCM (the
  sdm845-mainline beryllium profile; stock alsa-ucm-conf lacks beryllium -> no sinks).
- `.../modprobe.d/xpadneo.conf` - `options hid_xpadneo disable_shift_mode=1` (BT Xbox QAM chord).
- `.../systemd/system/essway.service.d/10-hidapi.conf` - `SDL_JOYSTICK_HIDAPI=0` (ES Xbox input).
- `.../autostart/SDM845/115-rotate-landscape` - sway `output DSI-1 transform 270` + touch map
  (the panel is portrait-native; this is the compositor-side rotation, separate from fbcon).
- `.../autostart/quirks/platforms/SDM845/040-affinity` - `FAST_CORES="taskset -c 4-7"` (big
  cores) for `steam.cores=big`.
- `.../bin/beryllium-idle-screenoff` + `.../systemd/system/beryllium-idle-screenoff.service` -
  idle screen-off daemon (evdev-based; swayidle doesn't work because ES holds a Wayland
  idle-inhibitor). Backlight off after 5 min, wake on any input, hotplug re-scan for the BT pad.
- `usr/bin/systemd-machine-id-setup` (override) + `rocknix-update` (OTA guard) - SDM845 cases.

### Steam launch scripts - `packages/emulators/standalone/steam/scripts/`
- `start_steam_arm64.sh` / `start_steam_x86.sh`: `performance` governor on launch + `trap
  ondemand EXIT` (Steam doesn't otherwise touch the governor; the trap survives the gamescope
  scope re-exec). And `export MESA_LOADER_DRIVER_OVERRIDE=zink` so native-GL games route GL->
  Vulkan->turnip instead of the llvmpipe software fallback (Proton/DXVK + Vulkan games ignore it).

### `devices/SDM845/options`
- `EXTRA_CMDLINE="rootwait quiet video=efifb:off console=tty0 fbcon=rotate:3"` (3 = landscape;
  1 came out upside-down).
- `ENABLE_32BIT="false"` (FEX covers x86; avoids a fragile second ARM build pass).
- Emulator set mirrors SM8250/Retroid Pocket 5 minus the 4 unrunnable heavy cores (RPCS3/Cemu/
  xemu/vita3k). `ADDITIONAL_PACKAGES` adds gamepadcalibration, pd-mapper, rmtfs, tqftpserv,
  xpadneo. NB some packages have their own `case ${DEVICE}` splits favoring FEX SoCs (libfmt
  -> 11.2.0, dolphin-sa -> fmt-11 build); SDM845 must be in those groups.

---

## Steam / FEX performance (real ceiling)

x86 games run under FEX emulation feeding the Adreno via a Vulkan thunk. The bottleneck is
**FEX guest<->host latency + poor frame-pipeline overlap**, not RAM, CPU throughput, or GPU
compute (all sit idle-ish). Confirmed by testing: TSO=0 gave nothing; RAM is never swapped.
Levers that actually help: lower render resolution (GPU fill), the performance governor (now
automatic for Steam), and choosing the right render path (D3D engines -> Proton/DXVK; GL-native
engines -> native + zink). A lightweight 2D game at 25 fps with everything idle is the
emulation ceiling, not a misconfiguration.

---

## Known issues / accepted limitations

- **Speaker is quiet.** TAS2559 firmware loads and plays, but the mainline driver never
  programs the amp's boost voltage (it lacks the downstream's VBoost machinery). pmOS has the
  same limitation. A real fix = porting the boost/calibration handling from the downstream
  driver (github.com/Matheus-Garbelini/Kernel-Sphinx-Pocophone-F1 `tas2559-core.c`); carries
  speaker-damage risk if the boost/config-PPG pairing is wrong. Accepted as-is; headphones are
  full volume. UCM uses Configuration 0 (Landscape); 4 is a calibration config.
- **WiFi MAC/IP random each boot** - WCN3990 has no fused MAC; ath10k ignores userspace MAC
  changes. Find the device IP in ES network settings or a LAN scan.
- **Tianma untested** - built, no hardware to verify.
- **No idle suspend, just screen-off** - power button suspends (rocknix-fake-suspend).

---

## Release process

Tag `vX.Y-beryllium`, assets = `boot-ebbg.img`, `boot-tianma.img`, `system.img.gz`,
`storage.img.gz`. Notes live in `flash/release/notes.md` (gitignored staging). The boot images
are byte-identical across releases when the kernel is unchanged (a system-only change can reuse
the prior boot images). `gh release create/upload --clobber/edit`; move the tag to the release
commit. Issues on, Actions off (`gh api PUT .../actions/permissions enabled=false`).
