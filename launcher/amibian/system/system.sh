#!/bin/bash

# Setup
# -----
# Author: Henrik Noerfjand Stengaard
# Date: 2019-12-22
#
# bash script to show system menu.

while true; do
	choices=$(dialog --clear --stdout \
	--title "System" \
	--menu "Select option:" 0 0 0 \
	1 "Reboot" \
	2 "Shutdown" \
	3 "Exit")

	clear

	# exit, if cancelled
	if [ $? -ne 0 ]; then
		exit
	fi

	for choice in $choices; do
		case $choice in
		1)
			./reboot.sh
			;;
		2)
			./shutdown.sh
			;;
		3)
			exit
			;;
		esac
	done
done
