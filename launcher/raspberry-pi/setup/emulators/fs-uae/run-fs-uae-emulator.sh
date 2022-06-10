#!/bin/bash -e

# Run FS-UAE Emulator
# -------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-26
#
# A bash script to run FS-UAE Amiga emulator.


function select_fsuae_config()
{
	# fail, if fs-uae config path doesn't exist
	if [ ! -d "$FSUAE_CONF_PATH" ]; then
		dialog --clear --title "ERROR" --msgbox "ERROR: FS-UAE config path '$FSUAE_CONF_PATH' doesn't exist!\n\nPlease verify FS-UAE is installed correctly." 0 0
		exit 1
	fi

	# list fs-uae configs
	find "$FSUAE_CONF_PATH/" -type f -name "*.fs-uae" -printf "%f\n" | sort >/tmp/_fs-uae_configs.txt

	# build options
	options=()
	n=0
	while read line ; do
		n=$(($n + 1))
	        options+=($n "$line")
	done </tmp/_fs-uae_configs.txt

	# fail, if no config files in fs-uae config path
	if [ $n = 0 ]; then
		dialog --clear --title "ERROR" --msgbox "ERROR: No configuration files in FS-UAE config path '$FSUAE_CONF_PATH'." 0 0
		exit 1
	fi

	# show select asound card dialog
	choice=$(dialog --clear --stdout --title "Select FS-UAE configuration" --menu "Select FS-UAE configuration to run:" 0 0 0 "${options[@]}")

	# exit, if cancelled
	if [ -z "$choice" ]; then
        	exit
	fi

        FSUAE_CONFIG=$(sed "${choice[@]}!d" /tmp/_fs-uae_configs.txt)
        rm /tmp/_fs-uae_configs.txt
}

# fail, if amiga emulator is not set
if [ -z "$AMIGA_EMULATOR" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: Amiga emulator 'AMIGA_EMULATOR' is not set!\n\nPlease verify HstWB Installer is installed correctly." 0 0
        exit 1
fi

# args
autostart=1

# parse arguments
for i in "$@"
do
case $i in
    -n|--no-autostart)
    autostart=0
    shift
    ;;
    *)
        # unknown argument
    ;;
esac
done


# fail, if fs-uae emulator path is not set
if [ -z "$FSUAE_EMULATOR_PATH" ]; then
       	dialog --clear --title "ERROR" --msgbox "ERROR: FS-UAE emulator path 'FSUAE_EMULATOR_PATH' is not set!\n\nPlease verify HstWB Installer is installed correctly." 0 0
        exit 1
fi

# fail, if fs-uae emulator is not installed
if [ ! -f "$FSUAE_EMULATOR_PATH/fs-uae" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: FS-UAE emulator is not installed!" 0 0
        exit 1
fi

# fail, if fs-uae emulator path is not set
if [ -z "$FSUAE_CONF_PATH" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: FS-UAE config path 'FSUAE_CONF_PATH' is not set!\n\nPlease verify HstWB Installer is installed correctly." 0 0
        exit 1
fi

# build fs-uae args
fsuaeargs=""
if [ $autostart -eq 1 -a -f "$FSUAE_CONF_PATH/autostart.fs-uae" ]; then
	fsuaeargs="$FSUAE_CONF_PATH/autostart.fs-uae"
else
	FSUAE_CONFIG=""
	select_fsuae_config

	if [ ! -z "$FSUAE_CONFIG" ]; then
		fsuaeargs="$FSUAE_CONF_PATH/$FSUAE_CONFIG"
	fi
fi

# run fs-uae
pushd "$FSUAE_EMULATOR_PATH" >/dev/null
echo "FS-UAE args: $fsuaeargs"
sleep 1
./fs-uae $fsuaeargs
popd >/dev/null
