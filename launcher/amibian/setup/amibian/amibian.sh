#!/bin/bash

# Setup Amibian
# -------------
# Author: Henrik Noerfjand Stengaard
# Date: 2020-02-23
#
# bash script to show setup amibian menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Amibian" \
	--menu "Select option:" 0 0 0 \
	1 "Amibian/Raspberry Pi Software Configuration Tool (raspiconf)" \
	2 "Change WiFi configuration" \
	3 "Edit WiFi settings file" \
	4 "Edit network settings file" \
	5 "Change Volume" \
	6 "Set audio output to HDMI" \
	7 "Set audio output to Jack" \
	8 "Change boot" \
	9 "Expand filesystem" \
	10 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			case $AMIBIAN_VERSION in
				1.5)
					pushd /home/amibian/.amibian_scripts >/dev/null
					./run_system_settings.sh
					popd >/dev/null
					;;
				1.4.1001)
					raspiconf
					;;
			esac

			;;
		2)
			./change-wifi-configuration.sh
			;;
		3)
			./edit-wifi-settings-file.sh
			;;
		4)
			./edit-network-settings-file.sh
			;;
		5)
			sudo alsamixer
			;;
		6)
			./audio-output-hdmi.sh
			;;
		7)
			./audio-output-jack.sh
			;;
		8)
			./change-boot.sh
			;;
		9)
			./expand-filesystem.sh
			;;
		10)
			exit
			;;
		esac
	done
done
