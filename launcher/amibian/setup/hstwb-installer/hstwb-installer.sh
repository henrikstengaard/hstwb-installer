#!/bin/bash

# Setup HstWB Installer
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2021-01-05
#
# bash script to show setup hstwb installer menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup HstWB Installer" \
	--menu "Select option:" 0 0 0 \
	1 "Find HstWB Self Install" \
	2 "Build Install Entries" \
	3 "Install HstWB Installer image" \
	4 "Run Amiga emulator for HstWB Installer image" \
	5 "Delete HstWB Installer image cache" \
	6 "First Time Use" \
	7 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./find-hstwb-self-install.sh
			;;
		2)
			./build-install-entries.sh
			;;
		3)
			./install-hstwb-installer-image.sh
			;;
                4)
                        ./run-amiga-emulator-hstwb-installer.sh
                        ;;
		5)
			./delete-hstwb-installer-image-cache.sh
			;;
		6)
			./first-time-use.sh
			;;
		7)
			exit
			;;
		esac
	done
done
