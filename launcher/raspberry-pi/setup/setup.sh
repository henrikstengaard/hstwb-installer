#!/bin/bash

# Setup
# -----
# Author: Henrik Noerfjand Stengaard
# Date: 2020-12-17
#
# bash script to show setup menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup" \
	--menu "Select option:" 0 0 0 \
	1 "Raspberry Pi OS" \
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
			pushd raspberry-pi-os >/dev/null
			./raspberry-pi-os.sh
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
