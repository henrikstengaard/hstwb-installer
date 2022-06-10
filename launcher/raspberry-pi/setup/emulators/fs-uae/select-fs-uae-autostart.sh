#!/bin/bash -e

# Select FS-UAE autostart
# -----------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2022-01-26
#
# A bash script to select FS-UAE configuration to autostart.


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
	choice=$(dialog --clear --stdout --title "Select FS-UAE autostart" --menu "Select FS-UAE configuration to autostart:" 0 0 0 "${options[@]}")

	# exit, if cancelled
	if [ -z "$choice" ]; then
        	exit
	fi

        FSUAE_CONFIG=$(sed "${choice[@]}!d" /tmp/_fs-uae_configs.txt)
        rm /tmp/_fs-uae_configs.txt
}

# fail, if fs-uae config path is not set
if [ -z "$FSUAE_CONF_PATH" ]; then
        dialog --clear --title "ERROR" --msgbox "ERROR: FS-UAE config path 'FSUAE_CONF_PATH' is not set!\n\nPlease verify FS-UAE is installed correctly." 0 0
        exit 1
fi

# select fs-uae config
FSUAE_CONFIG=""
select_fsuae_config

# exit, if fs-uae config is not set
if [ -z "$FSUAE_CONFIG" ]; then
	exit
fi

# delete fs-uae autostart, if it exists
if [ -s "$FSUAE_CONF_PATH/autostart.fs-uae" ]; then
	rm -f "$FSUAE_CONF_PATH/autostart.fs-uae"
fi

# create fs-uae autostart symlink
ln -s "$FSUAE_CONF_PATH/$FSUAE_CONFIG" "$FSUAE_CONF_PATH/autostart.fs-uae"
