# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2025 ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="xpadneo"
PKG_VERSION="b514bd4454ddca2c40bf5522b3083cf079c9764e"
PKG_LICENSE="GPL-3.0"
PKG_SITE="https://github.com/atar-axis/xpadneo"
PKG_URL="${PKG_SITE}.git"
PKG_LONGDESC="xpadneo: advanced Linux driver for Xbox One/Series wireless controllers over Bluetooth"
PKG_TOOLCHAIN="make"
PKG_IS_KERNEL_PKG="yes"

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  # build the hid-xpadneo.ko module out-of-tree against our kernel
  make -C "$(kernel_path)" M="${PKG_BUILD}/hid-xpadneo/src" modules \
       ARCH=${TARGET_KERNEL_ARCH} CROSS_COMPILE=${TARGET_KERNEL_PREFIX}
}

makeinstall_target() {
  mkdir -p ${INSTALL}/$(get_full_module_dir)/kernel/drivers/hid/
    cp ${PKG_BUILD}/hid-xpadneo/src/hid-xpadneo.ko \
       ${INSTALL}/$(get_full_module_dir)/kernel/drivers/hid/
}
