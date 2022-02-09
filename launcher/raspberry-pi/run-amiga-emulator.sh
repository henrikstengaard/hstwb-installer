#!/bin/bash

# Run Amiga Emulator
# ------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-13
#
# A bash script to run Amiga emulator.


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

# change amiga emulator, if amiga emulator is not selected
if [ -z "$AMIGA_EMULATOR" ]; then
	$HSTWB_INSTALLER_ROOT/launcher/raspberry-pi/setup/emulators/change-amiga-emulator.sh
fi

case "$AMIGA_EMULATOR" in
amiberry)
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
	;;
uae4arm)
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
	;;
*)
	dialog --clear --title "ERROR" --msgbox "ERROR: Amiga emulator is not defined!\n\nPlease change Amiga emulator first!" 0 0
	exit 1
	;;
esac

