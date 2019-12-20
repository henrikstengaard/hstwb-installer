#!/bin/bash

# Setup
# -----
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-20
#
# bash script to show setup menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "Setup" \
	--menu "Select option:" 0 0 0 \
	1 "Amibian" \
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
			pushd amibian
			./amibian.sh
			popd
			;;
		2)
			pushd emulators
			./emulators.sh
			popd
			;;
		3)
			pushd hstwb-installer
			./hstwb-installer.sh
			popd
			;;
		4)
			exit
			;;
		esac
	done
done
