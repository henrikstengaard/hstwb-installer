#!/bin/bash -e

# HstWB Launcher
# --------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-01-18
#
# Bash script to start HstWB Installer for DietPt launcher.

# fail, if hstwb installer config doesn't exist
if [ ! -f ~/.hstwb-installer/config.sh ]; then
	echo "ERROR: HstWB Installer config \"~/.hstwb-installer/config.sh\" doesn't exist!"
	exit 1
fi

# run hstwb installer config
. ~/.hstwb-installer/config.sh

# fail, if hstwb installer root doesn't exist
if [ ! -d "$HSTWBINSTALLERROOT" ]; then
	echo "ERROR: HstWB Installer root \"$HSTWBINSTALLERROOT\" doesn't exist!"
	exit 1
fi

# start hstwb installer for dietpi
pushd "$HSTWBINSTALLERROOT/launcher/dietpi" >/dev/null
./launcher.sh
popd >/dev/null
