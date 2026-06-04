# beryllium DSP/GPU firmware (NOT in git)

These proprietary signed blobs are extracted from the device (MIUI vendor/dsp/modem
partitions) or a postmarketOS install, and are NOT redistributable. The build expects
them at `qcom/sdm845/Xiaomi/beryllium/`:

  adsp.mbn cdsp.mbn slpi.mbn mba.mbn modem.mbn venus.mbn wlanmdsp.mbn ipa_fws.mbn
  a630_zap.mbn  + the matching *.jsn files

Easiest source: a running pmOS on the F1:
  sudo tar czf /tmp/beryllium-fw.tar.gz -C /lib/firmware qcom/sdm845 ath10k/WCN3990 qca
then drop `qcom/sdm845/Xiaomi/beryllium/*` into this directory (uncompressed).
