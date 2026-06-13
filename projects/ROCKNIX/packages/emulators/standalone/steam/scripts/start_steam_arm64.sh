#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

STEAM_MAIN_SCRIPT=${0}
STEAM_FLAVOR=arm64

source /etc/profile
set_kill set "gamescope steam FEX"

# Run the CPU at max clock while gaming and restore the default on exit. Steam,
# unlike the emulator path (runemu.sh), never touches the governor, so it would
# otherwise idle at ondemand mid-clock. The EXIT trap survives the gamescope
# scope re-exec below (that re-runs this script, which re-arms it) and fires
# when Steam quits.
performance
trap ondemand EXIT

# Route OpenGL games through zink (GL -> Vulkan -> turnip) instead of the
# llvmpipe software fallback, which is unusably slow under FEX. Only affects
# native-GL games; Vulkan-native and Proton/DXVK games never load Mesa GL and
# ignore it. Override per-game with a Steam launch option (e.g.
# MESA_LOADER_DRIVER_OVERRIDE=llvmpipe %command%) if a title glitches under zink.
export MESA_LOADER_DRIVER_OVERRIDE=zink

# shellcheck source=start_steam.sh
. /usr/bin/start_steam.sh

steam_ensure_fex_config_template
steam_prepare_storage_and_vdf
steam_load_es_thunk_settings "$@"
steam_write_fex_config_json
steam_set_cpu_affinity
steam_debug_print

steam_arm64_binfmt_and_proton_prep
steam_read_sway_geometry
steam_scope_reexec_if_needed "$@"
steam_dual_screen_begin
steam_launch_bigpicture "$@"
steam_dual_screen_end
systemctl restart systemd-binfmt
