# SDM845 / Xiaomi Poco F1 (beryllium, EBBG panel)

ROCKNIX device target for the Xiaomi Poco F1 (codename **beryllium**), SoC **sdm845**
(Snapdragon 845, Adreno 630, WCN3990 WiFi+BT). Forked from the SM6115 target.

## Why this differs from the official Snapdragon handhelds
The official handhelds boot via a per-device prebuilt **signed ABL** shipped by the
`rocknix-abl` package (`abl_signed-<DEVICE>.elf`). No signed ABL exists for beryllium,
and we don't need one: the Poco F1's stock bootloader already boots a standard
**fastboot Android boot image**, exactly like postmarketOS. So `rocknix-abl` is dropped
and we package a `boot.img` with `mkbootimg` instead.

## Boot image geometry (from postmarketOS device-xiaomi-beryllium)
```
cmdline (device part) : console=ttyMSM0,115200
flash_offset_base     : 0x00000000
flash_offset_kernel   : 0x00008000
flash_offset_ramdisk  : 0x01000000
flash_offset_second   : 0x00f00000
flash_offset_tags     : 0x00000100
pagesize              : 4096
header version        : 0 (legacy)
append_dtb            : true  (DTB is concatenated onto the kernel Image, NOT a v2 dtb header)
dtb (ebbg variant)    : qcom/sdm845-xiaomi-beryllium-ebbg.dtb
flash method          : fastboot (sparse)
```

## Boot image recipe
1. Append the DTB to the kernel:  `cat Image qcom/sdm845-xiaomi-beryllium-ebbg.dtb > Image-dtb`
2. Pack with mkbootimg using the offsets/pagesize above, ramdisk = ROCKNIX initramfs,
   cmdline = `${EXTRA_CMDLINE}` + ROCKNIX boot args (`boot=`/`disk=`).
3. `fastboot flash boot boot.img`

## Rootfs
ROCKNIX produces a squashfs `SYSTEM` + storage. On the F1's fixed eMMC layout we flash
the rootfs to `userdata` (pmOS-style) rather than dd-ing a whole-disk GPT (which would
clobber modem/persist partitions). Exact partition wiring is finalized during bring-up.

## Status / open items
- Touchscreen `focaltech,ft8719`: no mainline driver found yet — deferred (BT controller
  is the primary input). Display/touch panel DTS + `panel-ebbg-ft8719` driver are mainline.
- Display rotation: panel is native portrait (1080x2246); `config.xml` sets `rotation="3"`
  (270°) as a starting guess for landscape handheld use — verify/flip on device.
- WiFi/BT MAC: handled by the kept `0009-drivers-use-soc-serial-for-wifi-and-bluetooth.patch`.
