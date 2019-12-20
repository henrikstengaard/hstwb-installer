#!/bin/bash

# Amibian Launcher
# ----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-20
#
# bash script to show amibian launcher.

# main menu
while true; do
	# show main menu
	choices=$(dialog --clear --stdout \
	--title "HstWB Installer for Amibian" \
	--menu "Select option:" 0 0 0 \
	1 "Run emulator" \
	2 "Setup" \
	3 "Exit")

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
			pushd setup
			./setup.sh
			popd
			;;
		3)
			exit
			;;
		esac
	done
done
