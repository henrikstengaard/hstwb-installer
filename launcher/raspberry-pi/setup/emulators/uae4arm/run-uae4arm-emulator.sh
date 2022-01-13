#!/bin/bash

# Run UAE4ARM Emulator
# --------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-13
#
# A bash script to run UAE4ARM Amiga emulator.


# run hstwb installer config in current shell
. ~/.hstwb-installer/config.sh

# fail, if amiga emulator is not set
if [ -z "$AMIGA_EMULATOR" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: Amiga emulator 'AMIGA_EMULATOR' is not set!\n\nPlease verify HstWB Installer is installed correctly." 0 0
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


# fail, if uae4arm emulator path is not set
if [ -z "$UAE4ARM_EMULATOR_PATH" ]; then
       	dialog --clear --title "ERROR" --msgbox "ERROR: UAE4ARM emulator path 'UAE4ARM_EMULATOR_PATH' is not set!\n\nPlease verify HstWB Installer is installed correctly." 0 0
        exit 1
fi

# fail, if uae4arm emulator is not installed
if [ ! -f "$UAE4ARM_EMULATOR_PATH/uae4arm" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: UAE4ARM emulator is not installed!" 0 0
        exit 1
fi

# run uae4arm
pushd "$UAE4ARM_EMULATOR_PATH" >/dev/null
if [ $noautostart -eq 1 ]; then
	uae4armargs=""
else
	uae4armargs="-f \"$UAE4ARM_CONF_PATH/autostart.uae\""
fi
./uae4arm $uae4armargs
popd >/dev/null
