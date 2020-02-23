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
	6 "Force audio To HDMI output" \
	7 "Force audio to Jack output" \
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
			network
			;;
		5)
			sudo alsamixer
			;;
		6)
			audiohdmi
			read -n 1 -s -r -p "Press any key to continue"
			;;
		7)
			audiojack
			read -n 1 -s -r -p "Press any key to continue"
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
