#!/bin/bash

# Run Amiga Emulator
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-02-26
#
# A bash script to run Amiga emulator.

case $AMIBIAN_VERSION in
	1.5)
		# run amiberry with autostart config
		pushd /home/amibian/Amiga/Emulators/amiberry >/dev/null
		./amiberry -f "$AMIBERRY_CONF_PATH/autostart.uae"
		popd >/dev/null
		;;
	1.4.1001)
		3
		;;
esac


