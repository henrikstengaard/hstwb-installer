#!/bin/bash -e

# Run amiga emulator for HstWB Installer
# --------------------------------------
# Author: Henrik Noefjand Stengaard
# Date: 2021-01-05
#
# Bash script to run amiga emulator for HstWB Installer UAE4ARM image installation.

# mount fat32 devices
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/system/mount-fat32-devices.sh --quiet

# find hstwb self install
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/setup/hstwb-installer/find-hstwb-self-install.sh --quiet

# run amiga emulator
$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/run-amiga-emulator.sh
