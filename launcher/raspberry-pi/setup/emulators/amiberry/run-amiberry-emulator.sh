#!/bin/bash

# Run Amiberry Emulator
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-12
#
# A bash script to run Amiberry amiga emulator.


# run hstwb installer config in current shell
. ~/.hstwb-installer/config.sh

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


# fail, if amiberry emulator path is not set
if [ -z "$AMIBERRY_EMULATOR_PATH" ]; then
	dialog --clear --title "ERROR" --msgbox "ERROR: Amiberry emulator path 'AMIBERRY_EMULATOR_PATH' is not set!\n\nPlease verify HstWB Installer is installed correctly." 0 0
        exit 1
fi

# fail, if amiberry emulator is not installed
if [ ! -f "$AMIBERRY_EMULATOR_PATH/amiberry" ]; then
	dialog --clear --title "ERROR" --msgbox "ERROR: Amiberry emulator is not installed!" 0 0
	exit 1
fi

# run amiberry
pushd "$AMIBERRY_EMULATOR_PATH" >/dev/null
if [ $noautostart -eq 1 ]; then
	amiberryargs=""
else
	amiberryargs="-f \"$AMIBERRY_CONF_PATH/autostart.uae\""
fi
./amiberry $amiberryargs
popd >/dev/null
