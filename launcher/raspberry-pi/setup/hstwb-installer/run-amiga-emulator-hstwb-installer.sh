#!/bin/bash -e

# Run amiga emulator for HstWB Installer
# --------------------------------------
# Author: Henrik Noefjand Stengaard
# Date: 2021-01-16
#
# Bash script to run amiga emulator for HstWB Installer UAE4ARM image installation.

# mount fat32 devices
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/system/mount-fat32-devices.sh --quiet

# find hstwb self install
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/setup/hstwb-installer/find-hstwb-self-install.sh --quiet

# disable amiberry autostart, if it exists
if [ -f "$AMIBERRY_CONF_PATH/autostart.uae" ]; then
        mv -f "$AMIBERRY_CONF_PATH/autostart.uae" "$AMIBERRY_CONF_PATH/autostart-disabled.uae"
fi

# disable uae4arm autostart, if it exists
if [ -f "$UAE4ARM_CONF_PATH/autostart.uae" ]; then
        mv -f "$UAE4ARM_CONF_PATH/autostart.uae" "$UAE4ARM_CONF_PATH/autostart-disabled.uae"
fi

# run amiga emulator
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/run-amiga-emulator.sh
