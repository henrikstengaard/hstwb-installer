#!/bin/bash -e

# Run Emulator
# ------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-01-18
#
# Bash script to run emulator for DietPi.

pushd /mnt/dietpi_userdata/amiberry >/dev/null
export LD_LIBRARY_PATH=/mnt/dietpi_userdata/amiberry/lib
/mnt/dietpi_userdata/amiberry/amiberry
popd >/dev/null
