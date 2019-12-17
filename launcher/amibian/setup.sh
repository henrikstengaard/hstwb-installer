#!/bin/bash

# Amibian Launcher
# ----------------
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-17
#
# bash script to show amibian launcher.

# main menu
while true; do
	# show main menu
	choices=$(dialog --clear --stdout \
	--title "Setup" \
	--menu "Select option:" 0 0 0 \
	1 "Select emulator" \
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
			./select-emulator.sh
			;;
		2)
			./s.sh
			;;
		3)
			exit
			;;
		esac
	done
done
