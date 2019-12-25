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
	4 "Change boot" \
	5 "Expand filesystem" \
	6 "Exit")

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
			./change-boot.sh
			;;
		5)
			./expand-filesystem.sh
			;;
		6)
			exit
			;;
		esac
	done
done
