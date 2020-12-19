#!/bin/bash -e

# Launcher
# --------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-19
#
# bash script to start HstWB Installer for Raspberry Pi launcher.

# fail, if hstwb installer config doesn't exist
if [ ! -f ~/.hstwb-installer/config.sh ]; then
	echo "ERROR: HstWB Installer config \"~/.hstwb-installer/config.sh\" doesn't exist!"
	exit 1
fi

# run hstwb installer config
. ~/.hstwb-installer/config.sh

# fail, if hstwb installer root doesn't exist
if [ ! -d "$HSTWB_INSTALLER_ROOT" ]; then
	echo "ERROR: HstWB Installer root \"$HSTWB_INSTALLER_ROOT\" doesn't exist!"
	exit 1
fi

# start hstwb installer for raspberry pi
pushd "$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi" >/dev/null
./raspberry-pi.sh
popd >/dev/null
