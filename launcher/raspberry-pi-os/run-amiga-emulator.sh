#!/bin/bash

# Run Amiga Emulator
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-17
#
# A bash script to run Amiga emulator.

# run amiberry with autostart config
pushd "$AMIBERRY_EMULATOR_PATH" >/dev/null
./amiberry -f "$AMIBERRY_CONF_PATH/autostart.uae"
popd >/dev/null


