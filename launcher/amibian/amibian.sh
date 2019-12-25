#!/bin/bash

# Amibian Launcher
# ----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-22
#
# bash script to show amibian launcher.

# main menu
while true; do
	# show main menu
	choices=$(dialog --clear --stdout \
	--title "HstWB Installer for Amibian" \
	--menu "Select option:" 0 0 0 \
	1 "Run emulator" \
	2 "Midnight Commander" \
	3 "Setup" \
	4 "System" \
	5 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			3
			;;
		2)
			mc
			;;
		3)
			pushd setup >/dev/null
			./setup.sh
			popd >/dev/null
			;;
		4)
			pushd system >/dev/null
			./system.sh
			popd >/dev/null
			;;
		5)
			exit
			;;
		esac
	done
done
