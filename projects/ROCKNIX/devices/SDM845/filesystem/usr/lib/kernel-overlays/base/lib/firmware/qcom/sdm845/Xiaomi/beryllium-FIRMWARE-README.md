# beryllium DSP/GPU firmware (NOT in git)

These proprietary signed blobs are extracted from the device (MIUI vendor/dsp/modem
partitions) or a postmarketOS install, and are NOT redistributable. The build expects
them at `qcom/sdm845/Xiaomi/beryllium/`:

  adsp.mbn cdsp.mbn slpi.mbn mba.mbn modem.mbn venus.mbn wlanmdsp.mbn ipa_fws.mbn
  a630_zap.mbn  + the matching *.jsn files

Easiest source: a running pmOS on the F1:
  sudo tar czf /tmp/beryllium-fw.tar.gz -C /lib/firmware qcom/sdm845 ath10k/WCN3990 qca
then drop `qcom/sdm845/Xiaomi/beryllium/*` into this directory (uncompressed).

## Speaker amp firmware (TAS2559)

The built-in loudspeaker is a TI TAS2559 smart amp. Its driver loads
`tas2559_uCDSP.bin` (the DSP program) from `/lib/firmware/`; without it the amp
logs "tas2559_uCDSP.bin firmware is not loaded" and the speaker stays silent (the
headphone jack still works). Extract these from your device's vendor partition:

  /vendor/firmware/tas2559_uCDSP.bin
  /vendor/etc/tas2559_l.ftcfg
  /vendor/etc/tas2559_r.ftcfg

Place all three at the firmware ROOT (NOT under `qcom/...`), i.e. two levels up
from this file, next to the `qcom/` dir:

  usr/lib/kernel-overlays/base/lib/firmware/tas2559_uCDSP.bin
  usr/lib/kernel-overlays/base/lib/firmware/tas2559_l.ftcfg
  usr/lib/kernel-overlays/base/lib/firmware/tas2559_r.ftcfg

(Also gitignored. The `.ftcfg` are L/R speaker tuning configs; `tas2559_uCDSP.bin`
is the one the driver explicitly requests.)
