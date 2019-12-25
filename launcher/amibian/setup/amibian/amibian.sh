#!/bin/bash

# Setup Amibian
# -------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-25
#
# bash script to show setup amibian menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup Amibian" \
	--menu "Select option:" 0 0 0 \
	1 "Raspberry Pi Software Configuration Tool (raspiconf)" \
	2 "WiFi settings" \
	3 "Network settings" \
	4 "Change Volume" \
	5 "Force audio To HDMI output" \
	6 "Force audio to Jack output" \
	7 "Change boot" \
	8 "Expand filesystem" \
	9 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			raspiconf
			;;
		2)
			wifi
			;;
		3)
			network
			;;
		4)
			volume
			;;
		5)
			audiohdmi
			read -n 1 -s -r -p "Press any key to continue"
			;;
		6)
			audiojack
			read -n 1 -s -r -p "Press any key to continue"
			;;
		7)
			./change-boot.sh
			;;
		8)
			./expand-filesystem.sh
			;;
		9)
			exit
			;;
		esac
	done
done
