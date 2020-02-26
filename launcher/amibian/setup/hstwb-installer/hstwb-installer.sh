#!/bin/bash

# Setup HstWB Installer
# ---------------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-20
#
# bash script to show setup hstwb installer menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup HstWB Installer" \
	--menu "Select option:" 0 0 0 \
	1 "Find HstWB Self Install" \
	2 "Build Install Entries" \
	3 "Install HstWB Installer image" \
	4 "First Time Use" \
	5 "Exit")

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
			./first-time-use.sh
			;;
		5)
			exit
			;;
		esac
	done
done
