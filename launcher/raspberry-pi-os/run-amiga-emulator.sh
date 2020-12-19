#!/bin/bash

# Run Amiga Emulator
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-19
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


# args
noautostart=0

# parse arguments
for i in "$@"
do
case $i in
    -n|--no-autostart)
    noautostart=1
    shift
    ;;
    *)
        # unknown argument
    ;;
esac
done

# run amiberry
pushd "$AMIBERRY_EMULATOR_PATH" >/dev/null
if [ $noautostart -eq 1 ]; then
	./amiberry
else
	./amiberry -f "$AMIBERRY_CONF_PATH/autostart.uae"
fi
popd >/dev/null


