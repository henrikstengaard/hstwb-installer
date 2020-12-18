#!/bin/bash

# Run Amiga Emulator
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-18
#
# A bash script to run Amiga emulator.

# fail, if amiberry emulator path is not set
if [ -z "$AMIBERRY_EMULATOR_PATH" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: Amiberry emulator path 'AMIBERRY_EMULATOR_PATH' is not set!" 0 0
        exit 1
fi

# fail, if amiberry emulator is not installed
if [ ! -f "$AMIBERRY_EMULATOR_PATH/amiberry" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: Amiberry emulator is not installed!" 0 0
        exit 1
fi

# run amiberry with autostart config
pushd "$AMIBERRY_EMULATOR_PATH" >/dev/null
./amiberry -f "$AMIBERRY_CONF_PATH/autostart.uae"
popd >/dev/null


