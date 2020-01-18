#!/bin/bash

# Setup
# -----
# Author: Henrik Noerfjand Stengaard
# Date: 2020-01-18
#
# bash script to show setup menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup" \
	--menu "Select option:" 0 0 0 \
	1 "DietPi" \
	2 "Emulators" \
	3 "HstWB Installer" \
	4 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			pushd dietpi >/dev/null
			./dietpi.sh
			popd >/dev/null
			;;
		2)
			pushd emulators >/dev/null
			./emulators.sh
			popd >/dev/null
			;;
		3)
			pushd hstwb-installer >/dev/null
			./hstwb-installer.sh
			popd >/dev/null
			;;
		4)
			exit
			;;
		esac
	done
done
